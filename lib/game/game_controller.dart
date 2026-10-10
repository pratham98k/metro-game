import 'package:flutter/foundation.dart';

enum RidePhase { ready, riding, paused, complete }

enum Journey {
  meadow(
    'Sunny Meadows',
    'A little sunshine, a big adventure.',
    'Meadow Explorer',
    0xFFDCF0D5,
  ),
  coast(
    'Bubble Bay',
    'Sea breezes and sparkling stars.',
    'Ocean Explorer',
    0xFFD5ECF0,
  ),
  sunset(
    'Peachy Peaks',
    'A golden ride above the clouds.',
    'Mountain Explorer',
    0xFFF4DED3,
  );

  const Journey(this.title, this.subtitle, this.badge, this.color);
  final String title;
  final String subtitle;
  final String badge;
  final int color;
}

class TrackStar {
  TrackStar({required this.lane, required this.x});
  final int lane;
  double x;
}

/// Pure game rules. Time is supplied by the UI, so tests need no real timers.
class GameController extends ChangeNotifier {
  static const targetStars = 8;
  static const trainX = .24;
  static const spawnInterval = 2.7;
  static const _lanePattern = [1, 0, 2, 1, 2, 0, 1, 0];

  Journey journey = Journey.meadow;
  RidePhase phase = RidePhase.ready;
  final Set<Journey> badges = {};
  final List<TrackStar> _stars = [];
  List<TrackStar> get stars => List.unmodifiable(_stars);
  int lane = 1;
  int collected = 0;
  bool speedy = false;
  double distance = 0;
  double celebration = 0;
  double whistle = 0;
  double _spawnTime = 0;
  int _spawnIndex = 0;

  void selectJourney(Journey value) {
    journey = value;
    reset();
  }

  void reset() {
    phase = RidePhase.ready;
    collected = 0;
    lane = 1;
    distance = 0;
    celebration = 0;
    whistle = 0;
    _spawnTime = 0;
    _spawnIndex = 0;
    _stars.clear();
    notifyListeners();
  }

  void start() {
    reset();
    phase = RidePhase.riding;
    _spawnStar(.78);
    notifyListeners();
  }

  void chooseLane(int value) {
    if (phase != RidePhase.riding) return;
    lane = value.clamp(0, 2);
    notifyListeners();
  }

  void togglePace() {
    speedy = !speedy;
    notifyListeners();
  }

  void pause() {
    if (phase != RidePhase.riding) return;
    phase = RidePhase.paused;
    notifyListeners();
  }

  void resume() {
    if (phase != RidePhase.paused) return;
    phase = RidePhase.riding;
    notifyListeners();
  }

  void ringBell() {
    whistle = 1;
    notifyListeners();
  }

  void _spawnStar(double x) {
    _stars.add(
      TrackStar(lane: _lanePattern[_spawnIndex % _lanePattern.length], x: x),
    );
    _spawnIndex++;
  }

  void tick(double seconds) {
    if (phase != RidePhase.riding || seconds <= 0) return;
    // Ignore long gaps after suspension instead of jumping past collectibles.
    final dt = seconds.clamp(0.0, .05);
    final speed = speedy ? .19 : .13;
    distance += dt * speed;
    celebration = (celebration - dt).clamp(0.0, 1.0);
    whistle = (whistle - dt * .7).clamp(0.0, 1.0);
    _spawnTime += dt;
    if (_spawnTime >= spawnInterval) {
      _spawnTime -= spawnInterval;
      _spawnStar(1.06);
    }
    for (final star in _stars.toList()) {
      star.x -= dt * speed;
      // A generous pickup window lets small hands change tracks a little late.
      if (star.lane == lane && (star.x - trainX).abs() < .075) {
        _stars.remove(star);
        collected++;
        celebration = 1;
        if (collected == targetStars) {
          phase = RidePhase.complete;
          badges.add(journey);
          _stars.clear();
          break;
        }
      } else if (star.x < -.08) {
        _stars.remove(star);
      }
    }
    notifyListeners();
  }
}
