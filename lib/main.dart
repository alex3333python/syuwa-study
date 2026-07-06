import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/mock_data.dart';
import 'logic/diagnosis_engine.dart';
import 'logic/question_generator.dart';
import 'models/answer_record.dart';
import 'models/app_language.dart';
import 'models/lesson.dart';
import 'screens/completion_screen.dart';
import 'screens/diagnosis_result_screen.dart';
import 'screens/language_select_screen.dart';
import 'screens/lesson_map_screen.dart';
import 'screens/lesson_screen.dart';
import 'widgets/header.dart';
import 'screens/settings_screen.dart';
import 'screens/records_screen.dart';
import 'models/question.dart';

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
      title: '多言語算数学習',
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
  int previousLevel = 1;
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
  bool isWeakReviewMode = false;
  AppLanguage selectedLanguage = AppLanguage.japanese;
  DiagnosisResult? diagnosisResult;

  DateTime? lastPlayedDate;
  Lesson? selectedLesson;

  int resultStars = 0;
  int resultCorrectAnswers = 0;
  int resultTotalQuestions = 0;
  List<Question> resultWrongQuestions = [];
  List<int> weakQuestionIds = [];
  Map<String, int> weakTagCounts = {};
  Map<String, int> weakReasonCounts = {};

  double get levelProgress {
    final currentLevelXp = getNextLevelXp(currentLevel - 1);
    final nextLevelXp = getNextLevelXp(currentLevel);

    return (xp - currentLevelXp) / (nextLevelXp - currentLevelXp);
  }

  void startLesson(Lesson lesson) {
    setState(() {
      selectedLesson = lesson;
      isWeakReviewMode = false;
      currentScreen = 'lesson';
    });
  }

  Future<void> completeLesson({
    required int stars,
    required int correctAnswers,
    required int totalQuestions,
    required List<Question> wrongQuestions,
    required List<Question> correctQuestions,
    required List<AnswerRecord> answerRecords,
  }) async {
    if (selectedLesson != null) {
      await updateLessonProgress(lesson: selectedLesson!, stars: stars);
    }

    final isDiagnosis = selectedLesson?.type == LessonType.diagnosis;
    final nextDiagnosisResult = isDiagnosis
        ? DiagnosisEngine.analyze(wrongQuestions, answerRecords)
        : null;
    recordWeakSignals(answerRecords);

    setState(() {
      previousLevel = currentLevel;
      resultStars = stars;
      resultCorrectAnswers = correctAnswers;
      resultTotalQuestions = totalQuestions;
      resultWrongQuestions = wrongQuestions;
      diagnosisResult = nextDiagnosisResult;

      if (isWeakReviewMode) {
        for (final question in correctQuestions) {
          weakQuestionIds.remove(question.id);
        }
      } else {
        for (final question in wrongQuestions) {
          if (!weakQuestionIds.contains(question.id)) {
            weakQuestionIds.add(question.id);
          }
        }
      }

      xp += stars * 10;
      updateStreak();
      currentScreen = isDiagnosis ? 'diagnosis_result' : 'completion';

      final newLevel = currentLevel;

      if (newLevel > previousLevel) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('レベルアップ！'),
              content: Text('Lv.$newLevel になりました！🎉'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    });

    await saveProgress();

    if (isWeakReviewMode && weakQuestionIds.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('復習クリア！'),
            content: const Text('すべての苦手問題を克服しました 🎉'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  void recordWeakSignals(List<AnswerRecord> answerRecords) {
    for (final record in answerRecords.where((record) => !record.isCorrect)) {
      for (final tag in record.question.tags) {
        weakTagCounts[tag] = (weakTagCounts[tag] ?? 0) + 1;
      }

      final reason = record.mistakeReason;
      if (reason != null) {
        final key = reason.storageValue;
        weakReasonCounts[key] = (weakReasonCounts[key] ?? 0) + 1;
      }
    }
  }

  void goToSettings() {
    setState(() {
      currentScreen = 'settings';
    });
  }

  Future<void> selectLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language.storageValue);

    setState(() {
      selectedLanguage = language;
      currentScreen = 'map';
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
        type: current.type,
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
            type: next.type,
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
    await prefs.setStringList(
      'weak_question_ids',
      weakQuestionIds.map((id) => id.toString()).toList(),
    );
    await prefs.setStringList(
      'weak_tag_counts',
      _encodeCountMap(weakTagCounts),
    );
    await prefs.setStringList(
      'weak_reason_counts',
      _encodeCountMap(weakReasonCounts),
    );

    if (lastPlayedDate != null) {
      await prefs.setString(
        'last_played_date',
        lastPlayedDate!.toIso8601String(),
      );
    }
  }

  List<String> _encodeCountMap(Map<String, int> counts) {
    return counts.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
  }

  Map<String, int> _decodeCountMap(List<String>? values) {
    final counts = <String, int>{};
    if (values == null) return counts;

    for (final value in values) {
      final separatorIndex = value.lastIndexOf(':');
      if (separatorIndex <= 0) continue;

      final key = value.substring(0, separatorIndex);
      final count = int.tryParse(value.substring(separatorIndex + 1));
      if (count == null) continue;

      counts[key] = count;
    }

    return counts;
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < mockLessons.length; i++) {
      final lesson = mockLessons[i];

      final completed =
          prefs.getBool('lesson_${lesson.id}_completed') ?? lesson.completed;
      final stars = prefs.getInt('lesson_${lesson.id}_stars') ?? lesson.stars;
      final locked =
          prefs.getBool('lesson_${lesson.id}_locked') ?? lesson.locked;

      mockLessons[i] = Lesson(
        id: lesson.id,
        levelId: lesson.levelId,
        type: lesson.type,
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
    final savedWeakIds = prefs.getStringList('weak_question_ids');
    final savedWeakTagCounts = prefs.getStringList('weak_tag_counts');
    final savedWeakReasonCounts = prefs.getStringList('weak_reason_counts');
    final savedLanguage = prefs.getString('selected_language');

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

      if (savedWeakIds != null) {
        weakQuestionIds = savedWeakIds.map((id) => int.parse(id)).toList();
      }

      weakTagCounts = _decodeCountMap(savedWeakTagCounts);
      weakReasonCounts = _decodeCountMap(savedWeakReasonCounts);

      if (savedLanguage != null) {
        selectedLanguage = AppLanguageLabel.fromStorageValue(savedLanguage);
      } else {
        currentScreen = 'language';
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
    await prefs.setString('selected_language', selectedLanguage.storageValue);

    // ② アプリ内の状態を初期値に戻す
    setState(() {
      for (int i = 0; i < mockLessons.length; i++) {
        final l = mockLessons[i];

        mockLessons[i] = Lesson(
          id: l.id,
          levelId: l.levelId,
          type: l.type,
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
      weakTagCounts = {};
      weakReasonCounts = {};

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

  List<Question> getWeakQuestions() {
    final allQuestions = mockLessons
        .expand((lesson) => lesson.questions)
        .toList();

    return allQuestions
        .where((question) => weakQuestionIds.contains(question.id))
        .toList();
  }

  void startWeakReview() {
    final weakQuestions = getWeakQuestions();
    isWeakReviewMode = true;

    if (weakQuestions.isEmpty) return;

    setState(() {
      selectedLesson = Lesson(
        id: -2,
        levelId: -1,
        type: LessonType.practice,
        title: '苦手問題の復習',
        description: '過去に間違えた問題を復習しましょう',
        completed: false,
        locked: false,
        stars: 0,
        maxStars: 3,
        questions: weakQuestions,
      );

      currentScreen = 'lesson';
    });
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

  void startReview() {
    if (resultWrongQuestions.isEmpty) return;

    setState(() {
      selectedLesson = Lesson(
        id: -1,
        levelId: -1,
        type: LessonType.practice,
        title: '復習',
        description: '間違えた問題をもう一度確認しましょう',
        completed: false,
        locked: false,
        stars: 0,
        maxStars: 3,
        questions: resultWrongQuestions,
      );

      currentScreen = 'lesson';
    });
  }

  void startTodayReview() {
    final questions = QuestionGenerator.reviewQuestionsForTags(
      weakTagCounts.keys.toSet(),
    );
    if (questions.isEmpty) return;

    setState(() {
      selectedLesson = Lesson(
        id: -3,
        levelId: -1,
        type: LessonType.practice,
        title: '今日の復習',
        description: '前にむずかしかった言葉や計算に近い問題を練習します。',
        completed: false,
        locked: false,
        stars: 0,
        maxStars: 3,
        questions: questions.take(3).toList(),
      );
      isWeakReviewMode = false;
      currentScreen = 'lesson';
    });
  }

  void goHome() {
    setState(() {
      isWeakReviewMode = false;
      currentScreen = 'map';
    });
  }

  Future<void> startRecommendedLesson(Lesson lesson) async {
    final index = mockLessons.indexWhere((l) => l.id == lesson.id);
    if (index == -1) return;

    setState(() {
      final current = mockLessons[index];
      mockLessons[index] = Lesson(
        id: current.id,
        levelId: current.levelId,
        type: current.type,
        title: current.title,
        description: current.description,
        completed: current.completed,
        locked: false,
        stars: current.stars,
        maxStars: current.maxStars,
        questions: current.questions,
      );
      selectedLesson = mockLessons[index];
      isWeakReviewMode = false;
      currentScreen = 'lesson';
    });

    await saveProgress();
  }

  List<Lesson> getRecommendedLessons() {
    final result = diagnosisResult;
    if (result == null) return const [];

    return mockLessons
        .where((lesson) => result.recommendedLessonIds.contains(lesson.id))
        .toList();
  }

  void goToRecords() {
    setState(() {
      currentScreen = 'records';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    Widget body;

    if (currentScreen == 'language') {
      body = LanguageSelectScreen(
        selectedLanguage: selectedLanguage,
        onSelectLanguage: selectLanguage,
      );
    } else if (currentScreen == 'map') {
      body = LessonMapScreen(
        lessons: mockLessons,
        onStartLesson: startLesson,
        reviewEnabled: weakTagCounts.isNotEmpty,
        onStartTodayReview: startTodayReview,
      );
    } else if (currentScreen == 'lesson' && selectedLesson != null) {
      body = LessonScreen(
        lesson: selectedLesson!,
        onComplete: completeLesson,
        onClose: goHome,
        selectedLanguage: selectedLanguage,
      );
    } else if (currentScreen == 'diagnosis_result' && diagnosisResult != null) {
      body = DiagnosisResultScreen(
        result: diagnosisResult!,
        recommendedLessons: getRecommendedLessons(),
        totalQuestions: resultTotalQuestions,
        correctAnswers: resultCorrectAnswers,
        onHome: goHome,
        onStartRecommendedLesson: startRecommendedLesson,
      );
    } else if (currentScreen == 'settings') {
      body = SettingsScreen(
        xp: xp,
        streak: streak,
        level: currentLevel,
        xpToNextLevel: xpToNextLevel,
        levelProgress: levelProgress,
        onReset: confirmAndReset,
        onOpenRecords: goToRecords,
        onBack: goHome,
        weakQuestionCount: getWeakQuestions().length,
        onWeakReview: getWeakQuestions().isEmpty ? null : startWeakReview,
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
        wrongQuestionCount: resultWrongQuestions.length,
        onRestart: restartLesson,
        onHome: goHome,
        onNextLesson: getNextLessonAction(),
        onReview: resultWrongQuestions.isEmpty ? null : startReview,
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
