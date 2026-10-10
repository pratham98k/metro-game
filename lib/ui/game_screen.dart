import 'dart:ui' show ViewFocusEvent, ViewFocusState;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../game/game_controller.dart';
import '../game/sound.dart';
import 'landscape.dart';

const _ink = Color(0xFF284F47);
const _green = Color(0xFF207F71);
const _muted = Color(0xFF71857B);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final game = GameController();
  late final Ticker _ticker;
  Duration _lastTime = Duration.zero;
  bool _sound = true;
  Object? _lastSnapshot;
  int _previousStars = 0;
  final _focus = FocusNode(debugLabel: 'Game controls');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game.addListener(_gameChanged);
    _ticker = createTicker((elapsed) {
      final delta = elapsed - _lastTime;
      _lastTime = elapsed;
      game.tick(delta.inMicroseconds / Duration.microsecondsPerSecond);
    })..start();
  }

  void _gameChanged() {
    if (_sound && game.collected > _previousStars) {
      playTone(game.phase == RidePhase.complete ? 'win' : 'star');
    }
    _previousStars = game.collected;
    final snapshot = (
      game.phase,
      game.lane,
      game.collected,
      game.journey,
      game.speedy,
    );
    if (snapshot != _lastSnapshot) {
      _lastSnapshot = snapshot;
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) game.pause();
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    if (event.state == ViewFocusState.unfocused) game.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    game.removeListener(_gameChanged);
    game.dispose();
    super.dispose();
  }

  void _start() {
    game.start();
    if (_sound) playTone('bell');
    _focus.requestFocus();
  }

  void _bell() {
    game.ringBell();
    if (_sound) playTone('bell');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      game.chooseLane(game.lane - 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      game.chooseLane(game.lane + 1);
    } else if (key == LogicalKeyboardKey.digit1) {
      game.chooseLane(0);
    } else if (key == LogicalKeyboardKey.digit2) {
      game.chooseLane(1);
    } else if (key == LogicalKeyboardKey.digit3) {
      game.chooseLane(2);
    } else if (key == LogicalKeyboardKey.keyB) {
      _bell();
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP) {
      game.phase == RidePhase.paused ? game.resume() : game.pause();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _showHelp({bool grownups = false}) async {
    game.pause();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          grownups
              ? 'A little note for grown-ups'
              : 'Your first train adventure',
        ),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grownups
                ? [
                    const Text(
                      'Made for little conductors, ages 4–5. Play together for the first ride.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• No ads, purchases, accounts, or tracking.\n\n• No crashes, countdowns, or lost stars.\n\n• Collect 8 stars for a badge. Try a faster ride when your child is ready.\n\n• Badges last until you refresh or close this page.\n\n• A completed ride is a lovely moment for a break.',
                    ),
                  ]
                : [
                    _helpStep(
                      Icons.play_arrow_rounded,
                      '1. Tap “Let’s ride!”',
                      'Your train starts moving all by itself.',
                    ),
                    _helpStep(
                      Icons.alt_route_rounded,
                      '2. Follow the stars',
                      'Tap a track or a big track button to switch.',
                    ),
                    _helpStep(
                      Icons.star_rounded,
                      '3. Collect 8 stars',
                      'Earn a badge! Missed one? More are coming.',
                    ),
                    const Text(
                      'Keyboard: ↑ ↓ or 1 / 2 / 3 to switch tracks. B for the bell. P or Esc to pause.',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
    // Returning from a dialog leaves an active ride paused until explicit resume.
  }

  Widget _helpStep(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1232),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 18 : 40,
                      vertical: 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(narrow),
                        SizedBox(height: narrow ? 26 : 38),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _chip(
                              Icons.wb_sunny_outlined,
                              'SMALL CONDUCTORS. BIG ADVENTURES.',
                              const Color(0xFFEAF0DE),
                            ),
                            const Text(
                              '  Made for ages 4–5',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'A little train. A world of wonder.',
                          style: TextStyle(
                            fontSize: narrow ? 32 : 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.7,
                            height: 1.13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Chase the stars, explore happy places, and enjoy the ride.',
                          style: TextStyle(
                            fontSize: 15,
                            color: _muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (narrow) ...[
                          _playArea(true),
                          const SizedBox(height: 20),
                          _sidePanel(),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: _playArea(false)),
                              const SizedBox(width: 22),
                              Expanded(flex: 3, child: _sidePanel()),
                            ],
                          ),
                        const SizedBox(height: 28),
                        _journeys(narrow),
                        const SizedBox(height: 25),
                        _footer(narrow),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _header(bool narrow) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.train_rounded,
          color: Color(0xFFFFF6D8),
          size: 29,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'little bullet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            Text(
              'E X P R E S S',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
      if (!narrow)
        TextButton.icon(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('How to play'),
        ),
      IconButton.filledTonal(
        tooltip: _sound ? 'Mute sound' : 'Turn sound on',
        onPressed: () => setState(() => _sound = !_sound),
        icon: Icon(_sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
      ),
      if (!narrow) ...[
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showHelp(grownups: true),
          icon: const Icon(Icons.favorite_border_rounded, size: 17),
          label: const Text('For grown-ups'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(60, 48),
            side: const BorderSide(color: Color(0xFFD9DFD1)),
          ),
        ),
      ],
      if (narrow)
        IconButton(
          tooltip: 'How to play',
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
        ),
    ],
  );

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _green),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _playArea(bool narrow) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFDFE4D7)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7CAF72),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  game.journey.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                game.phase == RidePhase.ready
                    ? 'READY TO EXPLORE'
                    : game.phase == RidePhase.complete
                    ? 'WONDERFUL RIDE!'
                    : '${game.collected} / 8 STARS',
                style: const TextStyle(
                  fontSize: 9,
                  color: _muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: narrow ? 280 : 360,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  label:
                      'Train on track ${game.lane + 1}. Use the track buttons below to collect stars.',
                  child: GestureDetector(
                    onTapDown: (details) {
                      final normalizedY =
                          details.localPosition.dy /
                          constraints.maxHeight *
                          500;
                      if (normalizedY > 235) {
                        game.chooseLane(((normalizedY - 292) / 75).round());
                      }
                      _focus.requestFocus();
                    },
                    child: CustomPaint(painter: LandscapePainter(game: game)),
                  ),
                ),
                if (game.phase == RidePhase.ready)
                  Positioned(
                    top: 28,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          'All aboard, little explorer!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: narrow ? 24 : 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your starry adventure starts here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4C756A),
                          ),
                        ),
                        const SizedBox(height: 17),
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: const Text('Let’s ride!'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            elevation: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (game.phase == RidePhase.riding)
                  Positioned(
                    top: 15,
                    left: 15,
                    right: 15,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCED),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFE8AD36),
                                size: 25,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${game.collected} / 8',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton.filled(
                          tooltip: 'Pause ride',
                          onPressed: game.pause,
                          icon: const Icon(Icons.pause_rounded),
                        ),
                      ],
                    ),
                  ),
                if (game.phase == RidePhase.paused ||
                    game.phase == RidePhase.complete)
                  _rideOverlay(narrow),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 17, color: _muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      game.phase == RidePhase.ready
                          ? 'Little hands, big adventures. Just tap to play.'
                          : 'Tap a track. Follow the stars!',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ),
                  if (!narrow)
                    const Text(
                      '↑ ↓  to switch',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        selected: game.lane == i,
                        child: OutlinedButton(
                          onPressed: game.phase == RidePhase.riding
                              ? () {
                                  game.chooseLane(i);
                                  _focus.requestFocus();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 54),
                            backgroundColor: game.lane == i
                                ? const Color(0xFFE6EFE2)
                                : const Color(0xFFFAFAF3),
                            side: BorderSide(
                              color: game.lane == i
                                  ? const Color(0xFF6EA991)
                                  : const Color(0xFFE1E5D9),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                [
                                  Icons.filter_1_rounded,
                                  Icons.filter_2_rounded,
                                  Icons.filter_3_rounded,
                                ][i],
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Track ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rideOverlay(bool narrow) {
    final complete = game.phase == RidePhase.complete;
    return ColoredBox(
      color: const Color(0xFFF9F7EE).withValues(alpha: .91),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                complete
                    ? Icons.workspace_premium_rounded
                    : Icons.coffee_rounded,
                size: 51,
                color: complete ? const Color(0xFFD9A34B) : _green,
              ),
              const SizedBox(height: 10),
              Text(
                complete ? 'You’re a star conductor!' : 'A little pit stop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: narrow ? 24 : 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complete
                    ? '8 stars! Your ${game.journey.badge} badge is yours.'
                    : 'Your train is waiting right here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: complete
                    ? _start
                    : () {
                        game.resume();
                        _focus.requestFocus();
                      },
                icon: Icon(
                  complete ? Icons.replay_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(complete ? 'Ride again' : 'Keep going'),
              ),
              TextButton(
                onPressed: game.reset,
                child: Text(
                  complete ? 'Choose another adventure' : 'Back to station',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidePanel() => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0E3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3E5D4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR LITTLE MISSION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _muted,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD9AA49),
                  size: 27,
                ),
                SizedBox(width: 9),
                Flexible(
                  child: Text(
                    'Catch the stars!',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Find 8 golden stars and earn your explorer badge.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 15),
            Semantics(
              label: '${game.collected} of 8 stars collected',
              liveRegion: true,
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: List.generate(
                  8,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: i < game.collected
                        ? const Color(0xFFE5AA36)
                        : const Color(0xFFD3D9C3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFDCE0CE), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: _green,
                  size: 25,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${game.badges.length} of 3 badges earned',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3E5D9)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.speed_rounded, size: 21, color: _muted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your pace',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Text(
                  game.speedy ? 'Zippy' : 'Gentle',
                  style: const TextStyle(color: _green, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: game.togglePace,
                icon: Icon(
                  game.speedy ? Icons.bolt_rounded : Icons.eco_outlined,
                ),
                label: Text(
                  game.speedy ? 'Try a gentle ride' : 'Ready for a zippy ride?',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  textStyle: const TextStyle(fontSize: 11),
                  side: const BorderSide(color: Color(0xFFDCE3D8)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _bell,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Toot toot!'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF5E5BC),
                  foregroundColor: _ink,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _journeys(bool narrow) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Where shall we go?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ),
          Text(
            '3 happy places',
            style: TextStyle(fontSize: narrow ? 10 : 12, color: _muted),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (narrow)
        ...Journey.values.map(
          (journey) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _journeyCard(journey),
          ),
        )
      else
        Row(
          children: [
            for (var i = 0; i < Journey.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: _journeyCard(Journey.values[i])),
            ],
          ],
        ),
    ],
  );

  Widget _journeyCard(Journey journey) {
    final selected = journey == game.journey;
    final active =
        game.phase == RidePhase.riding || game.phase == RidePhase.paused;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFF0F3E7) : Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: active ? null : () => game.selectJourney(journey),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selected
                    ? const Color(0xFF78A48B)
                    : const Color(0xFFE1E5DA),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 53,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Color(journey.color),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    [
                      Icons.wb_sunny_rounded,
                      Icons.sailing_rounded,
                      Icons.landscape_rounded,
                    ][journey.index],
                    color: [
                      const Color(0xFFAD923D),
                      const Color(0xFF468D98),
                      const Color(0xFFC08770),
                    ][journey.index],
                    size: 31,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        game.badges.contains(journey)
                            ? 'Explorer badge earned!'
                            : [
                                'Sunshine & star trails',
                                'Waves & seaside smiles',
                                'Mountains & peachy skies',
                              ][journey.index],
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _green,
                    size: 21,
                  ),
                if (!selected && game.badges.contains(journey))
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD9A34B),
                    size: 21,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(bool narrow) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 24,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Color(0xFFCE9D83), size: 15),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'A little play. A lot of wonder.',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
      TextButton(
        onPressed: () => _showHelp(grownups: true),
        child: const Text(
          'No ads. No rush. Just happy journeys.  ♡',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
      ),
    ],
  );
}
