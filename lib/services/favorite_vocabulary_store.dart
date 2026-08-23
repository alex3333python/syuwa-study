import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';
import '../models/question.dart';

/// Persists dictionary words the learner stars for later review.
class FavoriteVocabularyStore extends ChangeNotifier {
  FavoriteVocabularyStore._();

  static final FavoriteVocabularyStore instance = FavoriteVocabularyStore._();

  static const _prefsKey = 'favorite_vocabulary_v1';

  final List<VocabularyEntry> _favorites = [];
  var _loaded = false;
  Future<void>? _loadFuture;

  List<VocabularyEntry> get favorites =>
      List<VocabularyEntry>.unmodifiable(_favorites);

  int get count => _favorites.length;

  bool get hasFavorites => _favorites.isNotEmpty;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  /// Allows a full reload after progress wipe / prefs.clear().
  void resetLoadGate() {
    _loadFuture = null;
    _loaded = false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _favorites
        ..clear()
        ..addAll(_decodeList(raw));
    } catch (error, stackTrace) {
      debugPrint('Failed to load favorite vocabulary: $error\n$stackTrace');
      _favorites.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  bool isFavorite(String term) {
    final key = _normalizeTerm(term);
    return _favorites.any((entry) => _normalizeTerm(entry.term) == key);
  }

  Future<void> toggle(VocabularyEntry entry) async {
    await ensureLoaded();
    final key = _normalizeTerm(entry.term);
    final existingIndex = _favorites.indexWhere(
      (favorite) => _normalizeTerm(favorite.term) == key,
    );

    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
    } else {
      _favorites.insert(0, entry);
    }

    notifyListeners();
    await _persist();
  }

  Future<void> remove(String term) async {
    await ensureLoaded();
    final key = _normalizeTerm(term);
    final before = _favorites.length;
    _favorites.removeWhere((entry) => _normalizeTerm(entry.term) == key);
    if (_favorites.length == before) return;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_encodeList(_favorites)));
    } catch (error, stackTrace) {
      debugPrint('Failed to save favorite vocabulary: $error\n$stackTrace');
    }
  }

  static String _normalizeTerm(String term) => term.trim();

  static List<Map<String, dynamic>> _encodeList(List<VocabularyEntry> entries) {
    return [
      for (final entry in entries) _encodeEntry(entry),
    ];
  }

  static Map<String, dynamic> _encodeEntry(VocabularyEntry entry) {
    return {
      'term': entry.term,
      'surfaces': entry.surfaces,
      'reading': entry.reading,
      'simpleJapanese': entry.simpleJapanese,
      'translations': {
        for (final translation in entry.translations.entries)
          translation.key.name: translation.value,
      },
      'exampleSentence': entry.exampleSentence,
      'category': entry.category,
    };
  }

  static List<VocabularyEntry> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) _decodeEntry(Map<String, dynamic>.from(item)),
    ];
  }

  static VocabularyEntry _decodeEntry(Map<String, dynamic> json) {
    final translationsRaw = json['translations'];
    final translations = <AppLanguage, String>{};
    if (translationsRaw is Map) {
      for (final entry in translationsRaw.entries) {
        final language = AppLanguageLabel.fromStorageValue('${entry.key}');
        final value = '${entry.value}'.trim();
        if (language == AppLanguage.japanese || value.isEmpty) continue;
        translations[language] = value;
      }
    }

    final surfacesRaw = json['surfaces'];
    final surfaces = surfacesRaw is List
        ? [
            for (final surface in surfacesRaw)
              '$surface'.trim(),
          ].where((surface) => surface.isNotEmpty).toList(growable: false)
        : const <String>[];

    return VocabularyEntry(
      term: '${json['term'] ?? ''}'.trim(),
      surfaces: surfaces,
      reading: '${json['reading'] ?? ''}'.trim(),
      simpleJapanese: '${json['simpleJapanese'] ?? ''}'.trim(),
      translations: translations,
      exampleSentence: '${json['exampleSentence'] ?? ''}'.trim(),
      category: '${json['category'] ?? ''}'.trim(),
    );
  }
}
