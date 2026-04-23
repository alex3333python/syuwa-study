import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/mock_data.dart';
import 'models/lesson.dart';
import 'screens/completion_screen.dart';
import 'screens/lesson_map_screen.dart';
import 'screens/lesson_screen.dart';
import 'widgets/header.dart';
import 'screens/settings_screen.dart';
import 'screens/records_screen.dart';

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
  int getLevelFromXp(int xp) {
    if (xp >= 800) return 5;
    if (xp >= 500) return 4;
    if (xp >= 250) return 3;
    if (xp >= 100) return 2;
    return 1;
  }
  int get currentLevel => getLevelFromXp(xp);
  int getNextLevelXp(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 500;
      case 4:
        return 800;
      default:
        return 1200;
    }
  }
  int get xpToNextLevel => getNextLevelXp(currentLevel) - xp;
  bool isLoading = true;

  DateTime? lastPlayedDate;
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
      updateStreak();
      currentScreen = 'completion';
    });

    await saveProgress();
  }

  void goToSettings() {
    setState(() {
      currentScreen = 'settings';
    });
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

  void updateStreak() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    if (lastPlayedDate == null) {
      streak = 1;
      lastPlayedDate = today;
      return;
    }

    final lastDay = DateTime(
      lastPlayedDate!.year,
      lastPlayedDate!.month,
      lastPlayedDate!.day,
    );

    final difference = today.difference(lastDay).inDays;

    if (difference == 0) {
      // 今日すでに学習済み
      return;
    } else if (difference == 1) {
      // 昨日も学習していた
      streak += 1;
    } else {
      // 途切れたので1日目から
      streak = 1;
    }

    lastPlayedDate = today;
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final lesson in mockLessons) {
      await prefs.setBool('lesson_${lesson.id}_completed', lesson.completed);
      await prefs.setInt('lesson_${lesson.id}_stars', lesson.stars);
      await prefs.setBool('lesson_${lesson.id}_locked', lesson.locked);
    }

    await prefs.setInt('user_xp', xp);
    await prefs.setInt('user_streak', streak);

    if (lastPlayedDate != null) {
      await prefs.setString(
        'last_played_date',
        lastPlayedDate!.toIso8601String(),
      );
    }   
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
    final savedStreak = prefs.getInt('user_streak');
    final savedLastPlayed = prefs.getString('last_played_date');



    setState(() {
      if (savedXp != null) {
        xp = savedXp;
      }

      if (savedStreak != null) {
        streak = savedStreak;
      }

      if (savedLastPlayed != null) {
        lastPlayedDate = DateTime.tryParse(savedLastPlayed);
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

  void goToNextLesson() {
    if (selectedLesson == null) return;

    final index = mockLessons.indexWhere((l) => l.id == selectedLesson!.id);

    if (index != -1 && index + 1 < mockLessons.length) {
      final nextLesson = mockLessons[index + 1];

      if (!nextLesson.locked) {
        setState(() {
          selectedLesson = nextLesson;
          currentScreen = 'lesson';
        });
      }
    }
  }
  VoidCallback? getNextLessonAction() {
    if (selectedLesson == null) return null;

    final index = mockLessons.indexWhere((l) => l.id == selectedLesson!.id);
    if (index == -1) return null;
    if (index + 1 >= mockLessons.length) return null;

    final nextLesson = mockLessons[index + 1];
    if (nextLesson.locked) return null;

    return goToNextLesson;
  }

  void goHome() {
    setState(() {
      currentScreen = 'map';
    });
  }

  void goToRecords() {
    setState(() {
      currentScreen = 'records';
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
  } else if (currentScreen == 'settings') {
    body = SettingsScreen(
      xp: xp,
      streak: streak,
      level: currentLevel,
      onReset: confirmAndReset,
      onOpenRecords: goToRecords,
      onBack: goHome,
    );
  } else if (currentScreen == 'records') {
    body = RecordsScreen(
      xp: xp,
      streak: streak,
      level: currentLevel,
      lessons: mockLessons,
      onBack: goToSettings,
    );
  } else {
    body = CompletionScreen(
      stars: resultStars,
      totalQuestions: resultTotalQuestions,
      correctAnswers: resultCorrectAnswers,
      xpGained: resultStars * 10,
      streak: streak,
      onRestart: restartLesson,
      onHome: goHome,
      onNextLesson: getNextLessonAction(),
    );
  }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              streak: streak, 
              xp: xp,
              level: currentLevel,
              onSettingsTap: goToSettings,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}