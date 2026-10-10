import 'package:flutter_test/flutter_test.dart';
import 'package:little_bullet_express/game/game_controller.dart';

void advance(GameController game, double seconds) {
  for (var i = 0; i < (seconds / .02).round(); i++) {
    game.tick(.02);
  }
}

void main() {
  late GameController game;
  setUp(() => game = GameController());
  tearDown(() => game.dispose());

  test('a ride starts gently on the middle track', () {
    game.start();
    expect(game.phase, RidePhase.riding);
    expect(game.lane, 1);
    expect(game.speedy, isFalse);
    expect(game.stars.single.lane, 1);
  });

  test('matching tracks collect stars; each star counts only once', () {
    game.start();
    advance(game, 4);
    expect(game.collected, 1);
    advance(game, .3);
    expect(game.collected, 1);
  });

  test('missing stars never ends a ride or removes progress', () {
    game.start();
    game.chooseLane(0);
    advance(game, 6);
    expect(game.collected, 0);
    expect(game.phase, RidePhase.riding);
    expect(game.stars, isNotEmpty);
  });

  test('pause freezes positions and resume continues the same ride', () {
    game.start();
    advance(game, 1);
    game.pause();
    final x = game.stars.first.x;
    advance(game, 10);
    expect(game.stars.first.x, x);
    game.chooseLane(0);
    expect(game.lane, 1);
    game.resume();
    advance(game, .5);
    expect(game.stars.first.x, lessThan(x));
  });

  test('eight pickups award one badge and stop the ride', () {
    game.start();
    for (
      var frame = 0;
      frame < 6000 && game.phase == RidePhase.riding;
      frame++
    ) {
      if (game.stars.isNotEmpty) game.chooseLane(game.stars.first.lane);
      game.tick(.02);
    }
    expect(game.collected, GameController.targetStars);
    expect(game.phase, RidePhase.complete);
    expect(game.badges, {Journey.meadow});
    advance(game, 5);
    expect(game.collected, 8);
    game.start();
    expect(game.collected, 0);
    expect(game.badges, {Journey.meadow});
  });

  test('zippy pace increases distance while suspension gaps are clamped', () {
    game.start();
    game.tick(.05);
    final gentleDistance = game.distance;
    game.reset();
    game.togglePace();
    game.start();
    game.tick(10);
    expect(game.distance, greaterThan(gentleDistance));
    expect(game.distance, closeTo(.19 * .05, .00001));
  });

  test('changing worlds resets the ride and lane inputs stay in bounds', () {
    game.start();
    game.chooseLane(100);
    expect(game.lane, 2);
    game.chooseLane(-100);
    expect(game.lane, 0);
    game.selectJourney(Journey.coast);
    expect(game.phase, RidePhase.ready);
    expect(game.journey, Journey.coast);
    expect(game.stars, isEmpty);
  });
}
