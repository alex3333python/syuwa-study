import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'models/lesson.dart';
import 'screens/completion_screen.dart';
import 'screens/lesson_map_screen.dart';
import 'screens/lesson_screen.dart';
import 'widgets/header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // icon
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '手話アカデミー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  // streak and experience level(xp)
  String currentScreen = 'map';
  int streak = 0;
  int xp = 0;

  Lesson? selectedLesson;

  int resultStars = 0;
  int resultCorrectAnswers = 0;
  int resultTotalQuestions = 0;

  void startLesson(Lesson lesson) {
    setState(() {
      selectedLesson = lesson;
      currentScreen = 'lesson';
    });
  }

  void completeLesson({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
  }) {
    setState(() {
      resultStars = stars;
      resultCorrectAnswers = correctAnswers;
      resultTotalQuestions = totalQuestions;
      xp += stars * 10;
      currentScreen = 'completion';
    });
  }

  void restartLesson() {
    if (selectedLesson == null) return;
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
      body = LessonMapScreen(
        lessons: mockLessons,
        onStartLesson: startLesson,
      );
    } else if (currentScreen == 'lesson' && selectedLesson != null) {
      body = LessonScreen(
        lesson: selectedLesson!,
        onComplete: completeLesson,
        onClose: goHome,
      );
    } else {
      body = CompletionScreen(
        stars: resultStars,
        totalQuestions: resultTotalQuestions,
        correctAnswers: resultCorrectAnswers,
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