/// Reports which screen is on top, by route name.
///
/// Firebase's automatic screen tracking sees Android activities, and a
/// Flutter app is one activity, so every screen used to arrive as
/// `MainActivity`. This watches the app's navigator instead and reports the
/// route that has just become the top page.
///
/// Routes are named in `RouteSettings` where they are pushed (`/daily`,
/// `/level/12`, ...). A page with no name is not reported: guessing from the
/// widget's runtime type would put minified class names in the report the day
/// the build is obfuscated. Dialogs and sheets are not pages and are ignored.
library;

import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

class AnalyticsScreenObserver extends NavigatorObserver {
  /// Read on every report rather than captured once, so tests and a late
  /// Firebase start both get the sink that is current.
  final AnalyticsService Function() analytics;

  AnalyticsScreenObserver(this.analytics);

  /// The screen name for a route name: `/` is home, `/level/12` is `level`
  /// (the level id travels on the funnel events; a screen per level would
  /// bury the report), `/settings` is `settings`.
  static String? screenNameFor(String? routeName) {
    if (routeName == null) return null;
    final parts = routeName.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'home';
    // Ids are dropped wherever they appear, so `/event/play` stays two words
    // and `/level/12` becomes one.
    return parts.where((p) => int.tryParse(p) == null).join('_');
  }

  void _report(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final name = screenNameFor(route.settings.name);
    if (name == null || name.isEmpty) return;
    analytics().log(ScreenView(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Popping a dialog uncovers nothing new; popping a page uncovers the one
    // beneath, which is now on screen again.
    if (route is PageRoute) _report(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);
}
