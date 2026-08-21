import 'dart:async';

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
import 'screens/report_screen.dart';
import 'screens/review_screen.dart';
import 'models/question.dart';
import 'theme/app_fonts.dart';
import 'services/japanese_tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(JapaneseTts.instance.warmup());
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0082FF),
        ),
        fontFamily: AppFonts.interface,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          headlineMedium: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          headlineSmall: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          titleMedium: TextStyle(
            fontFamily: AppFonts.interface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          bodyLarge: TextStyle(
            fontFamily: AppFonts.interface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontFamily: AppFonts.interface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontFamily: AppFonts.interface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            fontFamily: AppFonts.interface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Keep every Material control on the same readable interface font.
        // Some lesson buttons supply colors or padding locally, so this is the
        // shared baseline for labels that do not need a special treatment.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0082FF),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: AppFonts.interface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: AppFonts.interface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0082FF),
            disabledForegroundColor: const Color(0xFF9CA3AF),
            textStyle: const TextStyle(
              fontFamily: AppFonts.interface,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF0082FF),
              ),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: AppFonts.interface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

  // streak and experience (xp) are still tracked for later UI re-enable.
  String currentScreen = 'map';
  int streak = 0;
  int xp = 0;
  bool isLoading = true;
  bool isWeakReviewMode = false;
  AppLanguage selectedLanguage = AppLanguage.japanese;
  DiagnosisResult? diagnosisResult;

  DateTime? lastPlayedDate;
  Lesson? selectedLesson;
  int lessonSessionId = 0;

  int resultStars = 0;
  int resultCorrectAnswers = 0;
  int resultTotalQuestions = 0;
  List<Question> resultWrongQuestions = [];
  List<int> weakQuestionIds = [];
  Map<String, int> weakTagCounts = {};
  Map<String, int> weakReasonCounts = {};

  void startLesson(Lesson lesson) {
    setState(() {
      selectedLesson = lesson;
      lessonSessionId++;
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
    if (nextDiagnosisResult != null) {
      _mergeDiagnosisSignals(nextDiagnosisResult);
    }

    setState(() {
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
      // Level-up dialog is hidden for now (streak / XP / level UI is deferred).
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

      final unitId = record.question.unitId.trim();
      if (unitId.isNotEmpty) {
        weakTagCounts[unitId] = (weakTagCounts[unitId] ?? 0) + 1;
      }

      final reason = record.mistakeReason;
      if (reason != null) {
        final key = reason.storageValue;
        weakReasonCounts[key] = (weakReasonCounts[key] ?? 0) + 1;
      }
    }
  }

  void _mergeDiagnosisSignals(DiagnosisResult result) {
    for (final entry in result.mistakeReasonCounts.entries) {
      final key = entry.key.storageValue;
      weakReasonCounts[key] = (weakReasonCounts[key] ?? 0) + entry.value;
    }
  }

  void goToSettings() {
    setState(() {
      currentScreen = 'settings';
    });
  }

  void selectMainTab(int index) {
    setState(() {
      switch (index) {
        case 0:
          currentScreen = 'map';
          break;
        case 1:
          currentScreen = 'review';
          break;
        case 2:
          currentScreen = 'report';
          break;
      }
    });
  }

  int get selectedMainTabIndex {
    switch (currentScreen) {
      case 'review':
        return 1;
      case 'report':
        return 2;
      case 'map':
      default:
        return 0;
    }
  }

  bool get showMainNavigation {
    return currentScreen == 'map' ||
        currentScreen == 'review' ||
        currentScreen == 'report';
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
        steps: current.steps,
      );

      _syncLearningUnitLocks();
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

  bool get _isDiagnosisCompleted {
    for (final lesson in mockLessons) {
      if (lesson.id == 1) return lesson.completed;
    }
    return false;
  }

  Lesson _copyLesson(Lesson lesson, {bool? completed, bool? locked, int? stars}) {
    return Lesson(
      id: lesson.id,
      levelId: lesson.levelId,
      type: lesson.type,
      title: lesson.title,
      description: lesson.description,
      completed: completed ?? lesson.completed,
      locked: locked ?? lesson.locked,
      stars: stars ?? lesson.stars,
      maxStars: lesson.maxStars,
      questions: lesson.questions,
      steps: lesson.steps,
    );
  }

  void _syncLearningUnitLocks() {
    final diagnosisCompleted = _isDiagnosisCompleted;
    final completedById = {
      for (final lesson in mockLessons) lesson.id: lesson.completed,
    };

    for (int i = 0; i < mockLessons.length; i++) {
      final lesson = mockLessons[i];
      final shouldLock = shouldLessonBeLocked(
        lessonId: lesson.id,
        diagnosisCompleted: diagnosisCompleted,
        isCompleted: (id) => completedById[id] ?? false,
      );

      // 完了済みセクションは復習できるようにロックしない。
      final locked = lesson.completed ? false : shouldLock;
      if (lesson.locked == locked) continue;

      mockLessons[i] = _copyLesson(lesson, locked: locked);
    }
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < mockLessons.length; i++) {
      final lesson = mockLessons[i];

      final completed =
          prefs.getBool('lesson_${lesson.id}_completed') ?? lesson.completed;
      final stars = prefs.getInt('lesson_${lesson.id}_stars') ?? lesson.stars;

      mockLessons[i] = _copyLesson(
        lesson,
        completed: completed,
        stars: stars,
        locked: lesson.locked,
      );
    }

    _syncLearningUnitLocks();

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
      lessonSessionId++;
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

        mockLessons[i] = _copyLesson(
          l,
          completed: false,
          locked: true,
          stars: 0,
        );
      }

      _syncLearningUnitLocks();

      xp = 0;
      weakTagCounts = {};
      weakReasonCounts = {};
      diagnosisResult = null;
      weakQuestionIds = [];

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

    final nextLesson = _nextSectionInUnit(selectedLesson!);
    if (nextLesson == null) return;
    if (_isDivisionLessonWaitingForRedesign(nextLesson)) return;
    if (nextLesson.locked) return;

    setState(() {
      selectedLesson = nextLesson;
      lessonSessionId++;
      currentScreen = 'lesson';
    });
  }

  Lesson? _nextSectionInUnit(Lesson lesson) {
    final sections = learningUnitSectionsForLesson(lesson.id);
    if (sections == null) return null;

    final index = sections.indexOf(lesson.id);
    if (index == -1 || index + 1 >= sections.length) return null;

    final nextId = sections[index + 1];
    for (final candidate in mockLessons) {
      if (candidate.id == nextId) return candidate;
    }
    return null;
  }

  List<Question> getWeakQuestions() {
    final allQuestions = mockLessons
        .expand(
          (lesson) => [
            ...lesson.questions,
            ...lesson.steps.expand((step) => step.questions),
          ],
        )
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

      lessonSessionId++;
      currentScreen = 'lesson';
    });
  }

  VoidCallback? getNextLessonAction() {
    if (selectedLesson == null) return null;

    final nextLesson = _nextSectionInUnit(selectedLesson!);
    if (nextLesson == null) return null;
    if (nextLesson.locked) return null;
    if (_isDivisionLessonWaitingForRedesign(nextLesson)) return null;

    return goToNextLesson;
  }

  bool _isDivisionLessonWaitingForRedesign(Lesson lesson) {
    return false;
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

      lessonSessionId++;
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
        title: '今日のふくしゅう',
        description: 'むずかしかった問題を3問とこう',
        completed: false,
        locked: false,
        stars: 0,
        maxStars: 3,
        questions: questions.take(3).toList(),
      );
      isWeakReviewMode = false;
      lessonSessionId++;
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
      // おすすめから入る場合も、算数チェック済みとして単元ロックを同期する。
      final diagnosisIndex = mockLessons.indexWhere((l) => l.id == 1);
      if (diagnosisIndex != -1 && !mockLessons[diagnosisIndex].completed) {
        mockLessons[diagnosisIndex] = _copyLesson(
          mockLessons[diagnosisIndex],
          completed: true,
          locked: false,
        );
      }

      _syncLearningUnitLocks();

      final currentIndex = mockLessons.indexWhere((l) => l.id == lesson.id);
      if (currentIndex == -1) return;

      mockLessons[currentIndex] = _copyLesson(
        mockLessons[currentIndex],
        locked: false,
      );
      selectedLesson = mockLessons[currentIndex];
      isWeakReviewMode = false;
      lessonSessionId++;
      currentScreen = 'lesson';
    });

    await saveProgress();
  }

  List<Lesson> getRecommendedLessons() {
    final result = diagnosisResult;
    if (result == null) return const [];

    final byId = {for (final lesson in mockLessons) lesson.id: lesson};
    return [
      for (final id in result.recommendedLessonIds)
        if (byId[id] != null) byId[id]!,
    ];
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
      body = LessonMapScreen(lessons: mockLessons, onStartLesson: startLesson);
    } else if (currentScreen == 'review') {
      body = ReviewScreen(
        reviewEnabled: weakTagCounts.isNotEmpty,
        onStartTodayReview: startTodayReview,
      );
    } else if (currentScreen == 'report') {
      body = ReportScreen(
        weakTagCounts: weakTagCounts,
        weakReasonCounts: weakReasonCounts,
      );
    } else if (currentScreen == 'lesson' && selectedLesson != null) {
      body = LessonScreen(
        key: ValueKey('lesson-${selectedLesson!.id}-$lessonSessionId'),
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
        onReset: confirmAndReset,
        onOpenRecords: goToRecords,
        onBack: goHome,
        weakQuestionCount: getWeakQuestions().length,
        onWeakReview: getWeakQuestions().isEmpty ? null : startWeakReview,
      );
    } else if (currentScreen == 'records') {
      body = RecordsScreen(
        lessons: mockLessons,
        onBack: goToSettings,
      );
    } else {
      body = CompletionScreen(
        stars: resultStars,
        totalQuestions: resultTotalQuestions,
        correctAnswers: resultCorrectAnswers,
        wrongQuestionCount: resultWrongQuestions.length,
        onRestart: restartLesson,
        onHome: goHome,
        onNextLesson: getNextLessonAction(),
        onReview: resultWrongQuestions.isEmpty ? null : startReview,
      );
    }

    return Scaffold(
      bottomNavigationBar: showMainNavigation
          ? NavigationBar(
              selectedIndex: selectedMainTabIndex,
              onDestinationSelected: selectMainTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'まなぶ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.refresh_outlined),
                  selectedIcon: Icon(Icons.refresh_rounded),
                  label: 'ふくしゅう',
                ),
                NavigationDestination(
                  icon: Icon(Icons.summarize_outlined),
                  selectedIcon: Icon(Icons.summarize_rounded),
                  label: 'レポート',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Header(
              language: selectedLanguage,
              onSettingsTap: goToSettings,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
