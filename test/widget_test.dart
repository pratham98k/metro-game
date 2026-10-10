import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bullet_express/main.dart';

void main() {
  testWidgets('start, change track, pause, resume and return to station', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BulletTrainApp());
    expect(find.text('Let’s ride!'), findsOneWidget);
    await tester.tap(find.text('Let’s ride!'));
    await tester.pump();
    expect(find.text('0 / 8'), findsOneWidget);
    await tester.tap(find.text('Track 1'));
    await tester.pump();
    await tester.tap(find.byTooltip('Pause ride'));
    await tester.pump();
    expect(find.text('A little pit stop'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pump();
    expect(find.text('A little pit stop'), findsNothing);
    await tester.tap(find.byTooltip('Pause ride'));
    await tester.pump();
    await tester.tap(find.text('Back to station'));
    await tester.pump();
    expect(find.text('Let’s ride!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone layout fits, help closes, and a new world is selectable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BulletTrainApp());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('How to play'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Your first train adventure'), findsOneWidget);
    await tester.tap(find.text('Got it!'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(find.text('Bubble Bay'));
    await tester.tap(find.text('Bubble Bay'));
    await tester.pump();
    expect(find.text('Bubble Bay'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
