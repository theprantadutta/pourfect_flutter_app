/// The two boards, and the choice that puts somebody on them.
///
/// **A NAME IS THE OPT-IN, and nothing here invents one.** An account without
/// a display name appears on no board at all, so this screen has to be honest
/// about that rather than showing a player a list they are silently absent
/// from. Publishing a stranger as "Player 4821" would put somebody on a public
/// list they never agreed to join, and the fact that it is a puzzle game does
/// not make that a smaller decision.
///
/// **No photos here, ever.** Every avatar on this screen is an initial on a
/// ball color, the player's own included: a photo belongs on the crest of the
/// person in it, not on a public list somebody else is scrolling.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_result.dart';
import '../../services/api/leaderboard_api.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme/toy.dart';
import '../widgets/toy_kit.dart';

enum LeaderboardTab { daily, campaign }

class LeaderboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.onBack});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardTab _tab = LeaderboardTab.daily;

  Leaderboard? _board;
  ApiFailureKind? _failure;
  bool _loading = true;

  /// Bumped on every request, so a slow answer for the tab the player has
  /// already left cannot land on top of the one they are looking at.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [quiet] is the pull-to-refresh path: the board already on screen stays
  /// there while the new one loads, rather than blinking to a spinner.
  Future<void> _load({bool quiet = false}) async {
    final request = ++_request;
    if (!quiet) {
      setState(() {
        _loading = true;
        _failure = null;
      });
    }

    final api = LeaderboardApi(ref.read(apiClientProvider));
    final result = await (_tab == LeaderboardTab.daily
        ? api.daily()
        : api.campaign());

    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      switch (result) {
        case ApiOk(:final value):
          _board = value;
          _failure = null;
        case ApiFailure(:final kind):
          _board = null;
          _failure = kind;
      }
    });
  }

  void _select(LeaderboardTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _board = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);

    return ToyScaffold(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToyHeader(title: 'Rankings', onBack: widget.onBack),
          const SizedBox(height: 14),
          ToyTabs(
            labels: const ['Today', 'Campaign'],
            index: _tab.index,
            onChanged: (i) => _select(LeaderboardTab.values[i]),
          ),

          // The explanation sits ABOVE the board, not under it. Somebody
          // looking at a list they are not on should be told why before they
          // scroll fifty rows looking for themselves.
          //
          // This used to be a "pick a name" prompt, shown when the account
          // had none — that was the only way to be absent. Every account now
          // has a handle from sign-up, so the one remaining reason to be
          // missing is having chosen to be, and that is what it says.
          if (!account.showOnLeaderboards) ...[
            const SizedBox(height: 12),
            const _HiddenNotice(),
          ],

          const SizedBox(height: 6),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: Toy.tomato,
            backgroundColor: Toy.track,
          ),
        ),
      );
    }

    final board = _board;
    final List<Widget> children;

    if (board == null) {
      children = [
        const SizedBox(height: 24),
        _Unavailable(kind: _failure, onRetry: _load),
      ];
    } else if (board.isEmpty) {
      // The podium still stands, with nobody on it. An empty board is a
      // race nobody has entered yet, which is an invitation rather than an
      // error, and the empty steps say so better than a paragraph would.
      children = [
        const SizedBox(height: 8),
        _Podium(top: const [], tab: _tab),
        const SizedBox(height: 18),
        _Message(
          title: _tab == LeaderboardTab.daily
              ? 'Nobody has finished today’s board yet'
              : 'No ranked players yet',
          detail: _tab == LeaderboardTab.daily
              ? 'Be the first.'
              : 'Stars decide this one.',
        ),
      ];
    } else {
      final top = board.rows.take(3).toList();
      final rest = board.rows.skip(3).toList();
      children = [
        const SizedBox(height: 8),
        _Podium(top: top, tab: _tab),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 18),
          _RowsCard(rows: rest, tab: _tab),
        ],
        if (_showOwnRowSeparately(board)) ...[
          const SizedBox(height: 14),
          const ToySectionLabel('Your spot'),
          _RowsCard(rows: [board.you!], tab: _tab),
        ],
        if (board.totalPlayers > 0) ...[
          const SizedBox(height: 14),
          Text(
            board.totalPlayers == 1
                ? '1 player on this board'
                : '${formatCount(board.totalPlayers)} players on this board',
            textAlign: TextAlign.center,
            style: Toy.ui(12, color: Toy.inkMuted),
          ),
        ],
      ];
    }

    return RefreshIndicator(
      color: Toy.tomato,
      backgroundColor: Toy.card,
      onRefresh: () => _load(quiet: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // The bottom inset leaves room for the last card's hard shadow.
        padding: const EdgeInsets.only(bottom: 28),
        children: children,
      ),
    );
  }

  /// Whether the player's own row needs showing on its own.
  ///
  /// A board of the top fifty tells somebody nothing about themselves, which
  /// is the one thing they came to see — so their row is appended when they
  /// are not already in the visible list.
  bool _showOwnRowSeparately(Leaderboard board) =>
      board.you != null && !board.rows.any((r) => r.isYou);
}

// ---- how a score reads -------------------------------------------------------

/// The headline figure for a row: stars on the campaign, moves on the daily.
String _valueText(LeaderboardRow row, LeaderboardTab tab) =>
    tab == LeaderboardTab.daily ? plural(row.value, 'move') : '${row.value}';

/// The second axis: levels cleared, or the daily's time.
String? _tieBreakText(LeaderboardRow row, LeaderboardTab tab) {
  final tie = row.tieBreak;
  if (tie == null) return null;
  return tab == LeaderboardTab.daily
      ? 'in ${formatClock(tie)}'
      : plural(tie, 'level');
}

/// The score as a line: "38 ★" on the campaign, "14 moves" on the daily.
class _Score extends StatelessWidget {
  final LeaderboardRow row;
  final LeaderboardTab tab;
  final double size;
  final Color color;

  const _Score({
    required this.row,
    required this.tab,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      _valueText(row, tab),
      style: Toy.numbers(size, color: color),
    );
    if (tab == LeaderboardTab.daily) return text;
    return Semantics(
      label: plural(row.value, 'star'),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          SizedBox(width: size * 0.25),
          ToyStar(size: size, fill: color, outlined: false),
        ],
      ),
    );
  }
}

// ---- podium -----------------------------------------------------------------

/// The top three, on steps: #2 left, #1 centre and tallest, #3 right.
///
/// Fewer than three players still gets three steps. A missing place is drawn
/// as an open step — dimmed, no shadow, a question mark where the avatar goes
/// — so a two-player board reads as a podium with a spot free rather than a
/// layout that fell over.
class _Podium extends StatelessWidget {
  final List<LeaderboardRow> top;
  final LeaderboardTab tab;

  const _Podium({required this.top, required this.tab});

  static const _heights = [124.0, 92.0, 72.0];
  static const _colors = [Toy.yellow, Toy.blue, Toy.pink];

  @override
  Widget build(BuildContext context) {
    Widget slot(int place) => Expanded(
      child: _Step(
        place: place,
        row: place < top.length ? top[place] : null,
        tab: tab,
        height: _heights[place],
        color: _colors[place],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        slot(1),
        const SizedBox(width: 8),
        slot(0),
        const SizedBox(width: 8),
        slot(2),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  /// 0 for first.
  final int place;
  final LeaderboardRow? row;
  final LeaderboardTab tab;
  final double height;
  final Color color;

  const _Step({
    required this.place,
    required this.row,
    required this.tab,
    required this.height,
    required this.color,
  });

  bool get _first => place == 0;

  @override
  Widget build(BuildContext context) {
    final row = this.row;
    final avatarSize = _first ? 62.0 : 50.0;

    final Widget avatar = row == null
        ? _OpenAvatar(size: avatarSize)
        : ToyAvatar(
            name: row.displayName,
            size: avatarSize,
            strokeWidth: _first ? 3 : Toy.stroke,
          );

    final name = row == null
        ? 'Open spot'
        : row.isYou
        ? '${row.displayName} (you)'
        : row.displayName;

    // Ink on yellow, white on blue and pink: the contrast each one needs.
    final onStep = _first ? Toy.ink : Colors.white;
    final numberSize = switch (place) {
      0 => 44.0,
      1 => 34.0,
      _ => 30.0,
    };

    return Semantics(
      label: row == null
          ? 'Place ${place + 1}, open'
          : 'Place ${row.rank}, $name, ${_semanticScore(row)}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_first)
            // The crown overlaps the avatar's top edge, as in the mockup.
            SizedBox(
              height: avatarSize + 16,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  avatar,
                  if (row != null)
                    const Positioned(
                      top: 0,
                      child: CustomPaint(
                        size: Size(28, 18),
                        painter: _CrownPainter(),
                      ),
                    ),
                ],
              ),
            )
          else
            avatar,
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Toy.ui(
              _first ? 13 : 12,
              weight: _first ? FontWeight.w800 : FontWeight.w700,
              color: row == null ? Toy.inkDim : Toy.ink,
            ),
          ),
          const SizedBox(height: 6),
          if (row == null)
            _OpenStep(height: height, place: place, numberSize: numberSize)
          else
            ToyBox(
              height: height,
              width: double.infinity,
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${row.rank}',
                    style: TextStyle(
                      fontFamily: Toy.displayFamily,
                      fontSize: numberSize,
                      height: 1,
                      color: _first ? Toy.tomato : Colors.white,
                      shadows: [
                        Shadow(
                          color: Toy.ink,
                          offset: Offset(2, _first ? 3 : 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Score(
                    row: row,
                    tab: tab,
                    size: _first ? 13 : 12,
                    color: onStep,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _semanticScore(LeaderboardRow row) {
    final value = tab == LeaderboardTab.daily
        ? plural(row.value, 'move')
        : plural(row.value, 'star');
    final tie = _tieBreakText(row, tab);
    return tie == null ? value : '$value, $tie';
  }
}

/// A place nobody holds yet.
class _OpenAvatar extends StatelessWidget {
  final double size;

  const _OpenAvatar({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Toy.card.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(size * 0.3),
      border: Border.all(color: Toy.inkDim, width: Toy.strokeThin),
    ),
    child: Text('?', style: Toy.display(size * 0.44, color: Toy.inkDim)),
  );
}

class _OpenStep extends StatelessWidget {
  final double height;
  final int place;
  final double numberSize;

  const _OpenStep({
    required this.height,
    required this.place,
    required this.numberSize,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Toy.track,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
        bottom: Radius.circular(6),
      ),
      border: Border.all(color: Toy.inkDim, width: Toy.strokeThin),
    ),
    child: Text(
      '${place + 1}',
      style: Toy.display(numberSize, color: Toy.inkDim),
    ),
  );
}

/// The #1 crown: a three-point crown in yellow with an ink edge.
class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Mirrors the mockup's clip-path polygon.
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.2)
      ..lineTo(w * 0.25, h * 0.6)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.75, h * 0.6)
      ..lineTo(w, h * 0.2)
      ..lineTo(w, h)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = Toy.yellow)
      ..drawPath(
        path,
        Paint()
          ..color = Toy.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = Toy.strokeThin
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => false;
}

// ---- list -------------------------------------------------------------------

/// Places four and down, in one white card.
class _RowsCard extends StatelessWidget {
  final List<LeaderboardRow> rows;
  final LeaderboardTab tab;

  const _RowsCard({required this.rows, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Toy.box(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _Row(row: rows[i], tab: tab, divider: i > 0),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardRow row;
  final LeaderboardTab tab;
  final bool divider;

  const _Row({required this.row, required this.tab, required this.divider});

  @override
  Widget build(BuildContext context) {
    final tie = _tieBreakText(row, tab);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: row.isYou ? Toy.tomatoTint : null,
        border: divider
            ? const Border(top: BorderSide(color: Toy.divider, width: 1.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${row.rank}',
                style: Toy.numbers(
                  15,
                  color: row.isYou ? Toy.tomato : Toy.inkMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ToyAvatar(name: row.displayName, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: row.displayName,
                    children: [
                      if (row.isYou)
                        TextSpan(
                          text: ' (you)',
                          style: Toy.ui(13, color: Toy.inkMuted),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Toy.ui(14, weight: FontWeight.w700),
                ),
                if (tie != null)
                  Text(
                    tie,
                    style: Toy.ui(11, color: Toy.inkMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Score(row: row, tab: tab, size: 14, color: Toy.ink),
        ],
      ),
    );
  }
}

// ---- states -----------------------------------------------------------------

class _Unavailable extends StatelessWidget {
  final ApiFailureKind? kind;
  final VoidCallback onRetry;

  const _Unavailable({required this.kind, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (kind == ApiFailureKind.notConfigured) {
      return const _Message(
        title: 'Leaderboards are off in this build',
        detail: 'The campaign is unaffected.',
      );
    }

    final detail = switch (kind) {
      ApiFailureKind.offline =>
        'You look offline. Every level still plays without a connection.',
      ApiFailureKind.timeout => 'The server took too long to answer.',
      _ => 'Something went wrong on our side. Your progress is safe.',
    };

    return _Message(
      title: 'Could not load the board',
      detail: detail,
      action: ToyButton(
        label: 'Try again',
        onPressed: onRetry,
        height: 50,
        radius: 16,
        shadow: 4,
        fontSize: 20,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String detail;
  final Widget? action;

  const _Message({required this.title, required this.detail, this.action});

  @override
  Widget build(BuildContext context) {
    return ToyBox(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Toy.display(22, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Toy.ui(
              14,
              weight: FontWeight.w500,
              color: Toy.inkMuted,
              height: 1.35,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Shown to a player who has taken themselves off the boards.
///
/// Without it the leaderboard is a list they are silently absent from, and the
/// most natural reading of that is that the feature is broken.
class _HiddenNotice extends StatelessWidget {
  const _HiddenNotice();

  @override
  Widget build(BuildContext context) {
    return ToyBox(
      color: Toy.card,
      radius: 18,
      shadow: 3,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ToyIconTile(
            color: Toy.lilac,
            child: Icon(Icons.visibility_off_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are hidden',
                  style: Toy.ui(15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your stars and streak still count — you just do not '
                  'appear here. Settings has the switch.',
                  style: Toy.ui(
                    13,
                    weight: FontWeight.w500,
                    color: Toy.inkMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
