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
    if (selectedLesson != null) {
      updateLessonProgress(
        lesson: selectedLesson!,
        stars: stars,
      );
    }

    setState(() {
      resultStars = stars;
      resultCorrectAnswers = correctAnswers;
      resultTotalQuestions = totalQuestions;
      xp += stars * 10;
      currentScreen = 'completion';
    });
  }

  void updateLessonProgress({
    required Lesson lesson,
    required int stars,
  }) {
    setState(() {
      // 対象レッスンを見つける
      final index = mockLessons.indexWhere((l) => l.id == lesson.id);
      if (index == -1) return;

      final current = mockLessons[index];

      // 星は「最大値を採用」
      final newStars = stars > current.stars ? stars : current.stars;

      // 新しいLessonを作り直す（イミュータブル更新）
      final updatedLesson = Lesson(
        id: current.id,
        levelId: current.levelId,
        title: current.title,
        description: current.description,
        completed: true, // ← クリア
        locked: false,
        stars: newStars,
        maxStars: current.maxStars,
        questions: current.questions,
      );

      mockLessons[index] = updatedLesson;

      // 次のレッスンを解放
      if (index + 1 < mockLessons.length) {
        final next = mockLessons[index + 1];

        if (next.locked) {
          mockLessons[index + 1] = Lesson(
            id: next.id,
            levelId: next.levelId,
            title: next.title,
            description: next.description,
            completed: next.completed,
            locked: false, // ← 解放
            stars: next.stars,
            maxStars: next.maxStars,
            questions: next.questions,
          );
        }
      }
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