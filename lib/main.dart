import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/mock_data.dart';
import 'models/lesson.dart';
import 'screens/completion_screen.dart';
import 'screens/lesson_map_screen.dart';
import 'screens/lesson_screen.dart';
import 'widgets/header.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    loadProgress();
  }
  // streak and experience level(xp)
  String currentScreen = 'map';
  int streak = 0;
  int xp = 0;
  bool isLoading = true;

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

  Future<void> completeLesson({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    if (selectedLesson != null) {
      await updateLessonProgress(
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

    await saveProgress();
  }

  Future<void> updateLessonProgress({
    required Lesson lesson,
    required int stars,
  }) async {
    setState(() {
      final index = mockLessons.indexWhere((l) => l.id == lesson.id);
      if (index == -1) return;

      final current = mockLessons[index];
      final newStars = stars > current.stars ? stars : current.stars;

      mockLessons[index] = Lesson(
        id: current.id,
        levelId: current.levelId,
        title: current.title,
        description: current.description,
        completed: true,
        locked: false,
        stars: newStars,
        maxStars: current.maxStars,
        questions: current.questions,
      );

      if (index + 1 < mockLessons.length) {
        final next = mockLessons[index + 1];
        if (next.locked) {
          mockLessons[index + 1] = Lesson(
            id: next.id,
            levelId: next.levelId,
            title: next.title,
            description: next.description,
            completed: next.completed,
            locked: false,
            stars: next.stars,
            maxStars: next.maxStars,
            questions: next.questions,
          );
        }
      }
    });

    await saveProgress();
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final lesson in mockLessons) {
      await prefs.setBool('lesson_${lesson.id}_completed', lesson.completed);
      await prefs.setInt('lesson_${lesson.id}_stars', lesson.stars);
      await prefs.setBool('lesson_${lesson.id}_locked', lesson.locked);
    }

    await prefs.setInt('user_xp', xp);
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < mockLessons.length; i++) {
      final lesson = mockLessons[i];

      final completed =
          prefs.getBool('lesson_${lesson.id}_completed') ?? lesson.completed;
      final stars =
          prefs.getInt('lesson_${lesson.id}_stars') ?? lesson.stars;
      final locked =
          prefs.getBool('lesson_${lesson.id}_locked') ?? lesson.locked;

      mockLessons[i] = Lesson(
        id: lesson.id,
        levelId: lesson.levelId,
        title: lesson.title,
        description: lesson.description,
        completed: completed,
        locked: locked,
        stars: stars,
        maxStars: lesson.maxStars,
        questions: lesson.questions,
      );
    }

    final savedXp = prefs.getInt('user_xp');

    setState(() {
      if (savedXp != null) {
        xp = savedXp;
      }
      isLoading = false;
    });
  }
  void restartLesson() {
    if (selectedLesson == null) return;
    setState(() {
      currentScreen = 'lesson';
    });
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // ① 保存データを全削除
    await prefs.clear();

    // ② アプリ内の状態を初期値に戻す
    setState(() {
      for (int i = 0; i < mockLessons.length; i++) {
        final l = mockLessons[i];

        mockLessons[i] = Lesson(
          id: l.id,
          levelId: l.levelId,
          title: l.title,
          description: l.description,
          completed: false,
          locked: i == 0 ? false : true, // 1つ目だけ解放
          stars: 0,
          maxStars: l.maxStars,
          questions: l.questions,
        );
      }

      xp = 0;
      streak = 0;

      // 画面もマップに戻すと分かりやすい
      currentScreen = 'map';
      selectedLesson = null;
    });
  }

  Future<void> confirmAndReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('進捗をリセット'),
        content: const Text('すべての学習データを削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await resetProgress();
    }
  }

  void goHome() {
    setState(() {
      currentScreen = 'map';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }  
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
            Header(
              streak: streak, 
              xp: xp,
              onReset: confirmAndReset,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}