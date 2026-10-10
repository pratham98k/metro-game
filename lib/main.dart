import 'package:flutter/material.dart';
import 'ui/game_screen.dart';

void main() => runApp(const BulletTrainApp());

class BulletTrainApp extends StatelessWidget {
  const BulletTrainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Little Bullet Express',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F6EF),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF207F71)),
      fontFamily: 'Roboto',
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF284F47),
        displayColor: const Color(0xFF284F47),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF207F71),
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ),
    home: const GameScreen(),
  );
}
