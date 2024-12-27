import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:christmas_bingo/services/init_service.dart';
import 'package:christmas_bingo/theme.dart';
import 'package:christmas_bingo/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensure platform-specific Firebase config
  );

  final initService = InitService();
  await initService.initializeDefaultData();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _currentTheme = _getThemeForCurrentDate();

  static ThemeData _getThemeForCurrentDate() {
    final DateTime now = DateTime.now();
    final int month = now.month;
    final int day = now.day;

    // Christmas theme: December to January
    if (month == 12 || month == 1) {
      return AppThemes.christmasTheme;
    }

    // Easter theme: Check around Easter Sunday
    final DateTime easterSunday = _calculateEasterSunday(now.year);
    final DateTime easterStart = easterSunday.subtract(const Duration(days: 7)); // Week before Easter
    final DateTime easterEnd = easterSunday.add(const Duration(days: 7)); // Week after Easter

    if (now.isAfter(easterStart) && now.isBefore(easterEnd)) {
      return AppThemes.easterTheme;
    }

    // Default to dark theme
    return AppThemes.darkTheme;
  }

  static DateTime _calculateEasterSunday(int year) {
    // Algorithm to calculate the date of Easter Sunday
    final int a = year % 19;
    final int b = year ~/ 100;
    final int c = year % 100;
    final int d = b ~/ 4;
    final int e = b % 4;
    final int f = (b + 8) ~/ 25;
    final int g = (b - f + 1) ~/ 3;
    final int h = (19 * a + b - d - g + 15) % 30;
    final int i = c ~/ 4;
    final int k = c % 4;
    final int l = (32 + 2 * e + 2 * i - h - k) % 7;
    final int m = (a + 11 * h + 22 * l) ~/ 451;
    final int month = (h + l - 7 * m + 114) ~/ 31;
    final int day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Christmas Bingo',
      theme: _currentTheme,
      home: HomeScreen(onThemeChange: _updateTheme),
    );
  }

  void _updateTheme(String themeKey) {
    setState(() {
      switch (themeKey) {
        case 'christmas':
          _currentTheme = AppThemes.christmasTheme;
          break;
        case 'easter':
          _currentTheme = AppThemes.easterTheme;
          break;
        case 'dark':
        default:
          _currentTheme = AppThemes.darkTheme;
          break;
      }
    });
  }
}
