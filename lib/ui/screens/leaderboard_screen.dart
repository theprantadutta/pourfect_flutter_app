/// The two boards, and the choice that puts somebody on them.
///
/// **A NAME IS THE OPT-IN, and nothing here invents one.** An account without
/// a display name appears on no board at all, so this screen has to be honest
/// about that rather than showing a player a list they are silently absent
/// from. Publishing a stranger as "Player 4821" would put somebody on a public
/// list they never agreed to join, and the fact that it is a puzzle game does
/// not make that a smaller decision.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api/api_result.dart';
import '../../services/api/leaderboard_api.dart';
import '../../state/providers.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/pressable.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });

    final api = LeaderboardApi(ref.read(apiClientProvider));
    final result = await (_tab == LeaderboardTab.daily
        ? api.daily()
        : api.campaign());

    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case ApiOk(:final value):
          _board = value;
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
    final tokens = PourfectTokens.of(context);
    final name = ref.watch(authServiceProvider).current?.displayName;

    return Scaffold(
      backgroundColor: tokens.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: widget.onBack),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space4),
              child: _Tabs(selected: _tab, onSelect: _select),
            ),
            SizedBox(height: tokens.space3),

            // The opt-in sits ABOVE the board, not under it. Somebody looking
            // at a list they are not on should be told why before they scroll
            // fifty rows looking for themselves.
            if (name == null)
              _JoinPrompt(onJoined: (chosen) => setState(_load)),

            Expanded(child: _body(tokens)),
          ],
        ),
      ),
    );
  }

  Widget _body(PourfectTokens tokens) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.accent.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final board = _board;
    if (board == null) return _Unavailable(kind: _failure, onRetry: _load);

    if (board.isEmpty) {
      return _Message(
        title: _tab == LeaderboardTab.daily
            ? 'Nobody has finished today’s board yet'
            : 'No ranked players yet',
        detail: _tab == LeaderboardTab.daily
            ? 'Be the first.'
            : 'Stars decide this one.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: tokens.space5),
      itemCount: board.rows.length + (_showOwnRowSeparately(board) ? 2 : 0),
      itemBuilder: (context, index) {
        if (_showOwnRowSeparately(board)) {
          if (index == board.rows.length) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.space4,
                vertical: tokens.space3,
              ),
              child: Divider(color: tokens.hairline),
            );
          }
          if (index == board.rows.length + 1) {
            return _Row(row: board.you!, tab: _tab);
          }
        }
        return _Row(row: board.rows[index], tab: _tab);
      },
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space4,
        tokens.space3,
        tokens.space4,
        tokens.space3,
      ),
      child: Row(
        children: [
          Pressable(
            onPressed: onBack,
            semanticLabel: 'Back',
            child: Padding(
              padding: EdgeInsets.only(right: tokens.space3),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: tokens.textMuted,
              ),
            ),
          ),
          Text('Leaderboard', style: titleStyle(tokens).copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final LeaderboardTab selected;
  final void Function(LeaderboardTab) onSelect;

  const _Tabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Row(
      children: [
        for (final tab in LeaderboardTab.values) ...[
          if (tab != LeaderboardTab.values.first)
            SizedBox(width: tokens.space2),
          Expanded(
            child: Pressable(
              onPressed: () => onSelect(tab),
              child: AnimatedContainer(
                duration: tokens.selectDuration,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: tab == selected
                      ? tokens.surfaceRaised
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tab == selected
                        ? tokens.accent.withValues(alpha: 0.55)
                        : tokens.hairline,
                  ),
                ),
                child: Center(
                  child: Text(
                    tab == LeaderboardTab.daily ? 'Today' : 'Campaign',
                    style: actionStyle(
                      tokens,
                      color: tab == selected
                          ? tokens.textPrimary
                          : tokens.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardRow row;
  final LeaderboardTab tab;

  const _Row({required this.row, required this.tab});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space3,
      ),
      color: row.isYou ? tokens.accent.withValues(alpha: 0.07) : null,
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '${row.rank}',
              style: numericStyle(
                tokens,
                size: 14,
                color: row.isYou ? tokens.accent : tokens.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.displayName,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle(tokens).copyWith(
                fontSize: 14,
                color: row.isYou ? tokens.textPrimary : tokens.textMuted,
              ),
            ),
          ),
          Text(
            tab == LeaderboardTab.daily
                ? plural(row.value, 'move')
                : plural(row.value, 'star'),
            style: numericStyle(tokens, size: 14, color: tokens.textNumeric),
          ),
          if (row.tieBreak != null) ...[
            SizedBox(width: tokens.space3),
            SizedBox(
              width: 58,
              child: Text(
                tab == LeaderboardTab.daily
                    ? formatClock(row.tieBreak!)
                    : plural(row.tieBreak!, 'level'),
                textAlign: TextAlign.right,
                style: bodyStyle(tokens)
                    .copyWith(fontSize: 12, color: tokens.dimText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The opt-in.
class _JoinPrompt extends ConsumerStatefulWidget {
  final void Function(String name) onJoined;

  const _JoinPrompt({required this.onJoined});

  @override
  ConsumerState<_JoinPrompt> createState() => _JoinPromptState();
}

class _JoinPromptState extends ConsumerState<_JoinPrompt> {
  final _controller = TextEditingController();
  String? _problem;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    final problem = displayNameProblem(name);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });

    final result = await UsersApi(ref.read(apiClientProvider))
        .setDisplayName(name);

    if (!mounted) return;

    switch (result) {
      case ApiOk(:final value):
        await ref.read(authServiceProvider).update(displayName: value);
        if (!mounted) return;
        widget.onJoined(value);
      case ApiFailure(:final kind, :final detail):
        setState(() {
          _saving = false;
          _problem = kind == ApiFailureKind.refused
              ? (detail ?? 'That name was not accepted.')
              : 'Could not reach the server. Try again later.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tokens.space4),
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
        border: Border.all(color: tokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a name to appear here',
            style: titleStyle(tokens).copyWith(fontSize: 15),
          ),
          SizedBox(height: tokens.space2),
          Text(
            'You are not on the board until you choose one, and it is the only '
            'thing about you anybody else can see. You can play without it.',
            style: bodyStyle(tokens).copyWith(fontSize: 13),
          ),
          SizedBox(height: tokens.space3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_saving,
                  maxLength: kMaxDisplayName,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(kDisplayNamePattern),
                  ],
                  style: bodyStyle(tokens).copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    hintText: 'Your name on the board',
                    hintStyle: bodyStyle(tokens)
                        .copyWith(fontSize: 14, color: tokens.dimText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.hairline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                ),
              ),
              SizedBox(width: tokens.space3),
              Pressable(
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving ? 'Saving' : 'Join',
                  style: actionStyle(
                    tokens,
                    color: _saving ? tokens.dimText : tokens.accent,
                  ),
                ),
              ),
            ],
          ),
          if (_problem != null) ...[
            SizedBox(height: tokens.space2),
            Text(
              _problem!,
              style: bodyStyle(tokens)
                  .copyWith(fontSize: 12, color: tokens.accentWarm),
            ),
          ],
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final ApiFailureKind? kind;
  final VoidCallback onRetry;

  const _Unavailable({required this.kind, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    if (kind == ApiFailureKind.notConfigured) {
      return const _Message(
        title: 'Leaderboards are off in this build',
        detail: 'The campaign is unaffected.',
      );
    }

    return Padding(
      padding: EdgeInsets.all(tokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load the board',
            style: titleStyle(tokens).copyWith(fontSize: 17),
          ),
          SizedBox(height: tokens.space3),
          Pressable(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: actionStyle(tokens, color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String detail;

  const _Message({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    final tokens = PourfectTokens.of(context);

    return Padding(
      padding: EdgeInsets.all(tokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: titleStyle(tokens).copyWith(fontSize: 17)),
          SizedBox(height: tokens.space2),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: bodyStyle(tokens).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
