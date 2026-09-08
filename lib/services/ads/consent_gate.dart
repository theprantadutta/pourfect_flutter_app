/// Advertising consent, via Google's User Messaging Platform.
///
/// Ads used to be requested the moment the SDK initialised, with no consent
/// step at all. In the EEA, the UK and several US states that is not a
/// configuration detail — it is the difference between serving personalised
/// ads lawfully and serving them without a legal basis, and Google requires a
/// certified CMP for EEA/UK traffic on AdMob. An app that skips it risks ad
/// serving being limited or stopped.
///
/// The gate is deliberately small and answers one question: **may we request
/// ads yet?** Everything about WHICH ads and how they are personalised is
/// handled inside the SDK from the consent the form collects.
///
/// It never blocks gameplay. A player in a region that requires no consent
/// sees nothing; a player whose form fails to load still reaches level 1, just
/// without ads until the next launch. Ads are enrichment — the game is
/// playable offline and must never wait on a network round trip to a consent
/// server.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentGate {
  /// Whether ads may be requested right now.
  ///
  /// False until the SDK says otherwise, so the failure mode is "no ads"
  /// rather than "ads without consent". That direction matters: the first
  /// costs revenue, the second costs the account.
  bool canRequestAds = false;

  /// True when the player has a privacy-options entry point to show.
  ///
  /// Required where the form is required: somebody who consented must be able
  /// to change their mind, and the settings screen only shows the row when
  /// this is true.
  bool privacyOptionsRequired = false;

  /// Brings consent up to date, showing a form if one is required.
  ///
  /// Safe to call on every launch. The SDK caches the player's choice, so a
  /// returning player in a consent region sees nothing after the first time.
  Future<void> ensure() async {
    try {
      final params = ConsentRequestParameters();

      await _requestUpdate(params);

      // Loads AND shows, but only if the form is actually required in this
      // region. Outside a consent region this returns immediately.
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('[consent] form: ${error.message}');
        }
      });

      canRequestAds = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;

      debugPrint(
        '[consent] canRequestAds=$canRequestAds '
        'privacyOptions=$privacyOptionsRequired',
      );
    } catch (error) {
      // A consent server that is unreachable must not cost the player the
      // game. They simply get no ads this session.
      debugPrint('[consent] update failed, continuing without ads: $error');
      canRequestAds = false;
    }
  }

  /// Re-opens the privacy options form, for the settings row.
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('[consent] privacy form: ${error.message}');
      });
      canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (error) {
      debugPrint('[consent] privacy options failed: $error');
    }
  }

  Future<void> _requestUpdate(ConsentRequestParameters params) {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      completer.complete,
      (error) {
        debugPrint('[consent] info update failed: ${error.message}');
        completer.complete();
      },
    );
    return completer.future;
  }
}
