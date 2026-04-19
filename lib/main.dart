import 'package:flutter/material.dart';
import 'screens/CompletionScreen.dart';
import 'screens/LessonMapScreen.dart';
import 'screens/LessonScreen.dart';
import 'widgets/Header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign Learning App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentScreen = 'map';
  int streak = 7;
  int xp = 1250;
  int lastStars = 0;

  void startLesson() {
    setState(() {
      currentScreen = 'lesson';
    });
  }

  void completeLesson(int stars) {
    setState(() {
      lastStars = stars;
      xp += stars * 10;
      currentScreen = 'completion';
    });
  }

  void restartLesson() {
    setState(() {
      currentScreen = 'lesson';
    });
  }

  void goHome() {
    setState(() {
      currentScreen = 'map';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (currentScreen == 'map') {
      body = LessonMapScreen(onStart: startLesson);
    } else if (currentScreen == 'lesson') {
      body = LessonScreen(onComplete: completeLesson, onClose: goHome);
    } else {
      body = CompletionScreen(
        stars: lastStars,
        totalQuestions: 3,
        correctAnswers: ((lastStars / 3) * 3).round(),
        onRestart: restartLesson,
        onHome: goHome,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(streak: streak, xp: xp),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}