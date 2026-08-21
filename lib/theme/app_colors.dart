import 'package:flutter/material.dart';

/// Marela ブランドカラーと画面背景。
class AppColors {
  // Brand palette
  static const Color brandBlue = Color(0xFF4A86C5);
  static const Color brandSky = Color(0xFF6FB9E6);
  static const Color brandTurquoise = Color(0xFF7FD6CF);
  static const Color brandMist = Color(0xFFE6F0FA);
  static const Color brandNavy = Color(0xFF1F3A5F);

  /// まなぶ画面用（いまの濃さ）
  static const Color paleTurquoise = Color(0xFFD7F3F1);
  static const Color paleMarine = Color(0xFFC5DCE8);

  /// ふくしゅう・レポートなど用（もう少し明度高め）
  static const Color lighterTurquoise = Color(0xFFEAF8F7);
  static const Color lighterMarine = Color(0xFFE2EFF5);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandBlue, brandSky, brandTurquoise],
  );

  static const LinearGradient mapBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [paleTurquoise, paleMarine],
  );

  static const LinearGradient screenBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lighterTurquoise, lighterMarine],
  );

  static const BoxDecoration mapBackground = BoxDecoration(
    gradient: mapBackgroundGradient,
  );

  static const BoxDecoration screenBackground = BoxDecoration(
    gradient: screenBackgroundGradient,
  );
}
