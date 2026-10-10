import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/game_controller.dart';

/// All scenery is drawn locally: crisp at any size, with no remote art assets.
class LandscapePainter extends CustomPainter {
  LandscapePainter({required this.game, this.preview = false})
    : super(repaint: game);
  final GameController game;
  final bool preview;

  void shape(Canvas c, Color color, Path path) =>
      c.drawPath(path, Paint()..color = color);
  void oval(Canvas c, Color color, Rect rect) =>
      c.drawOval(rect, Paint()..color = color);
  void box(Canvas c, Color color, Rect rect, double radius) => c.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    Paint()..color = color,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    c.scale(size.width / 1000, size.height / 500);
    final coast = game.journey == Journey.coast;
    final sunset = game.journey == Journey.sunset;
    final sky = sunset ? const Color(0xFFF9D7B9) : const Color(0xFFCEEBEA);
    c.drawRect(const Rect.fromLTWH(0, 0, 1000, 500), Paint()..color = sky);
    final sun = sunset ? const Color(0xFFFFB86C) : const Color(0xFFFFD977);
    oval(c, sun.withValues(alpha: .22), const Rect.fromLTWH(769, 8, 150, 150));
    oval(c, sun, const Rect.fromLTWH(791, 30, 106, 106));
    _cloud(c, 150, 68, 1);
    _cloud(c, 555, 45, .8);
    _cloud(c, 920, 135, .65);
    if (sunset) {
      shape(
        c,
        const Color(0xFFC8B1BB),
        Path()
          ..moveTo(0, 270)
          ..lineTo(200, 80)
          ..lineTo(350, 270)
          ..lineTo(550, 92)
          ..lineTo(760, 290)
          ..lineTo(1000, 180)
          ..lineTo(1000, 500)
          ..lineTo(0, 500)
          ..close(),
      );
      shape(
        c,
        const Color(0xFFFFF3E4),
        Path()
          ..moveTo(147, 131)
          ..lineTo(200, 80)
          ..lineTo(254, 148)
          ..lineTo(218, 134)
          ..lineTo(191, 145)
          ..lineTo(177, 128)
          ..close(),
      );
      shape(
        c,
        const Color(0xFFFFF3E4),
        Path()
          ..moveTo(496, 147)
          ..lineTo(550, 92)
          ..lineTo(610, 157)
          ..lineTo(567, 140)
          ..lineTo(544, 154)
          ..lineTo(528, 137)
          ..close(),
      );
    }
    shape(
      c,
      coast
          ? const Color(0xFF85C9D1)
          : sunset
          ? const Color(0xFFD5B9AB)
          : const Color(0xFFB0D3A5),
      Path()
        ..moveTo(0, 235)
        ..quadraticBezierTo(160, 85, 350, 210)
        ..quadraticBezierTo(530, 90, 735, 205)
        ..quadraticBezierTo(900, 145, 1000, 203)
        ..lineTo(1000, 500)
        ..lineTo(0, 500)
        ..close(),
    );
    shape(
      c,
      coast
          ? const Color(0xFF56B9C7)
          : sunset
          ? const Color(0xFFBFBC91)
          : const Color(0xFF8ABF94),
      Path()
        ..moveTo(0, 255)
        ..quadraticBezierTo(150, 190, 290, 251)
        ..quadraticBezierTo(430, 300, 625, 216)
        ..quadraticBezierTo(800, 135, 1000, 247)
        ..lineTo(1000, 500)
        ..lineTo(0, 500)
        ..close(),
    );
    if (coast) {
      for (var i = 0; i < 7; i++) {
        box(
          c,
          const Color(0xFFBDE7E6),
          Rect.fromLTWH(70 + i * 151.0, 240 + (i % 3) * 13.0, 52, 3),
          2,
        );
      }
      _boat(c, 660, 214);
    } else {
      _tree(c, 110, 249, .8);
      _tree(c, 690, 247, .7);
      _tree(c, 948, 249, 1.1);
    }
    shape(
      c,
      coast
          ? const Color(0xFFF4DEA9)
          : sunset
          ? const Color(0xFFE2CFAC)
          : const Color(0xFFCCE0AD),
      Path()
        ..moveTo(0, 278)
        ..quadraticBezierTo(250, 237, 520, 280)
        ..quadraticBezierTo(750, 252, 1000, 275)
        ..lineTo(1000, 500)
        ..lineTo(0, 500)
        ..close(),
    );
    _station(c, 785, 248);
    for (var lane = 0; lane < 3; lane++) {
      final y = 292.0 + lane * 75;
      final selected = game.phase == RidePhase.riding && game.lane == lane;
      box(
        c,
        selected ? const Color(0xFFE9EBCD) : const Color(0xFFD6CEAF),
        Rect.fromLTWH(0, y - 7, 1000, 36),
        10,
      );
      final offset = (game.distance * 1000) % 43;
      for (var x = -43.0 - offset; x < 1040; x += 43) {
        box(c, const Color(0xFFB4A88C), Rect.fromLTWH(x, y - 4, 11, 30), 3);
      }
      for (final dy in [0.0, 20.0]) {
        box(c, const Color(0xFF82948B), Rect.fromLTWH(0, y + dy, 1000, 5), 2);
        box(c, const Color(0xFFF2EADB), Rect.fromLTWH(0, y + dy, 1000, 2), 1);
      }
    }
    for (var i = 0; i < 16; i++) {
      final x = (i * 83.0 - game.distance * 350) % 1080 - 40;
      final y = 480.0 + (i % 3) * 5;
      oval(c, const Color(0xFF81AB7B), Rect.fromLTWH(x, y, 5, 10));
      if (i % 3 == 0) {
        oval(c, const Color(0xFFFFF7DA), Rect.fromLTWH(x - 3, y - 4, 11, 9));
        oval(c, const Color(0xFFE5B855), Rect.fromLTWH(x, y - 1, 5, 4));
      }
    }
    if (game.phase == RidePhase.ready || preview) {
      for (var i = 0; i < 3; i++) {
        _star(c, Offset(555.0 + i * 98, 344), 17, const Color(0xFFFFD261));
      }
    }
    for (final star in game.stars) {
      final p = Offset(star.x * 1000, 269 + star.lane * 75.0);
      oval(
        c,
        const Color(0xFFFFEBA5).withValues(alpha: .5),
        Rect.fromCircle(center: p, radius: 29),
      );
      _star(c, p, 19, const Color(0xFFFFC94F));
    }
    final trainLane = game.phase == RidePhase.ready ? 1 : game.lane;
    final y = 292 + trainLane * 75.0;
    _train(c, 240, y);
    if (game.celebration > 0) {
      for (var i = 0; i < 7; i++) {
        final a = i * math.pi * 2 / 7;
        final r = 40 + (1 - game.celebration) * 85;
        _star(
          c,
          Offset(240 + math.cos(a) * r, y - 35 + math.sin(a) * r),
          6 * game.celebration + 2,
          const Color(0xFFF6B83F),
        );
      }
    }
    if (game.whistle > 0) {
      box(c, const Color(0xFFFFFCF2), Rect.fromLTWH(235, y - 125, 133, 45), 22);
      _text(
        c,
        'Toot toot! ♪',
        const Offset(250, 0),
        y - 115,
        20,
        const Color(0xFF26756A),
      );
    }
    c.restore();
  }

  void _cloud(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    final color = const Color(0xFFFFFEF5).withValues(alpha: .85);
    oval(c, color, const Rect.fromLTWH(-50, 0, 125, 29));
    oval(c, color, const Rect.fromLTWH(-25, -20, 48, 45));
    oval(c, color, const Rect.fromLTWH(7, -10, 43, 36));
    c.restore();
  }

  void _tree(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    box(c, const Color(0xFF9D906D), const Rect.fromLTWH(-5, -39, 10, 51), 4);
    oval(c, const Color(0xFF5B9E79), const Rect.fromLTWH(-35, -100, 70, 79));
    oval(c, const Color(0xFF78B18A), const Rect.fromLTWH(-34, -98, 48, 58));
    c.restore();
  }

  void _station(Canvas c, double x, double y) {
    c.save();
    c.translate(x, y);
    box(c, const Color(0xFFF8EDD2), const Rect.fromLTWH(-40, -59, 100, 70), 4);
    shape(
      c,
      const Color(0xFFDC9674),
      Path()
        ..moveTo(-53, -57)
        ..lineTo(10, -94)
        ..lineTo(72, -57)
        ..close(),
    );
    box(c, const Color(0xFF619D92), const Rect.fromLTWH(0, -24, 22, 35), 9);
    box(c, const Color(0xFF9BC6BE), const Rect.fromLTWH(-27, -40, 18, 19), 3);
    box(c, const Color(0xFF9BC6BE), const Rect.fromLTWH(32, -40, 18, 19), 3);
    oval(c, const Color(0xFFFFFDF0), const Rect.fromLTWH(0, -68, 20, 20));
    c.drawLine(
      const Offset(10, -64),
      const Offset(10, -58),
      Paint()
        ..color = const Color(0xFF426F65)
        ..strokeWidth = 2,
    );
    c.drawLine(
      const Offset(10, -58),
      const Offset(15, -56),
      Paint()
        ..color = const Color(0xFF426F65)
        ..strokeWidth = 2,
    );
    c.restore();
  }

  void _boat(Canvas c, double x, double y) {
    shape(
      c,
      const Color(0xFFFFF4DC),
      Path()
        ..moveTo(x, y)
        ..lineTo(x, y - 60)
        ..lineTo(x + 42, y)
        ..close(),
    );
    shape(
      c,
      const Color(0xFFE49C76),
      Path()
        ..moveTo(x - 18, y + 5)
        ..lineTo(x + 55, y + 5)
        ..lineTo(x + 43, y + 20)
        ..lineTo(x - 5, y + 20)
        ..close(),
    );
  }

  void _train(Canvas c, double x, double y) {
    c.save();
    c.translate(x, y);
    oval(
      c,
      const Color(0xFF536D57).withValues(alpha: .16),
      const Rect.fromLTWH(-163, 8, 283, 22),
    );
    for (final wheel in [-133.0, -83.0, -20.0, 77.0]) {
      oval(
        c,
        const Color(0xFF35575A),
        Rect.fromCircle(center: Offset(wheel, 11), radius: 11),
      );
      oval(
        c,
        const Color(0xFFA7C5BD),
        Rect.fromCircle(center: Offset(wheel, 11), radius: 5),
      );
    }
    box(c, const Color(0xFF567A72), const Rect.fromLTWH(-76, -10, 17, 10), 4);
    box(c, const Color(0xFFFEFDF2), const Rect.fromLTWH(-161, -62, 87, 69), 16);
    box(c, const Color(0xFFEFB06F), const Rect.fromLTWH(-161, -13, 87, 15), 4);
    for (final wx in [-149.0, -116.0]) {
      box(c, const Color(0xFF88C8D0), Rect.fromLTWH(wx, -49, 26, 25), 7);
      box(c, const Color(0xFFBCE2E0), Rect.fromLTWH(wx + 4, -45, 5, 16), 2);
    }
    final body = Path()
      ..moveTo(-63, 7)
      ..lineTo(-63, -48)
      ..quadraticBezierTo(-63, -64, -43, -64)
      ..lineTo(25, -64)
      ..cubicTo(66, -63, 84, -44, 112, -9)
      ..quadraticBezierTo(122, 7, 99, 7)
      ..close();
    shape(c, const Color(0xFFFFFEF5), body);
    shape(
      c,
      const Color(0xFFEA9B67),
      Path()
        ..moveTo(-63, -12)
        ..lineTo(107, -12)
        ..quadraticBezierTo(124, 7, 99, 7)
        ..lineTo(-63, 7)
        ..close(),
    );
    shape(
      c,
      const Color(0xFF4B8D96),
      Path()
        ..moveTo(22, -55)
        ..cubicTo(52, -54, 70, -38, 79, -26)
        ..lineTo(24, -26)
        ..quadraticBezierTo(18, -26, 18, -32)
        ..lineTo(18, -50)
        ..close(),
    );
    box(c, const Color(0xFF95CED0), const Rect.fromLTWH(-48, -49, 44, 25), 7);
    box(c, const Color(0xFFC6E4DE), const Rect.fromLTWH(-42, -45, 8, 17), 3);
    oval(c, const Color(0xFFFFDB8E), const Rect.fromLTWH(96, -10, 13, 7));
    _star(c, const Offset(-25, -5), 8, const Color(0xFFFFE7AD));
    c.restore();
  }

  void _star(Canvas c, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * .48;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFDFA03B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    shape(c, color, path);
  }

  void _text(
    Canvas c,
    String text,
    Offset offset,
    double y,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, Offset(offset.dx, y));
  }

  @override
  bool shouldRepaint(covariant LandscapePainter oldDelegate) =>
      oldDelegate.game != game || oldDelegate.preview != preview;
}
