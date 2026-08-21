import 'package:flutter/material.dart';

/// 画面全体の薄い背景グラデーション（ターコイズ → マリンブルー）。
class AppColors {
  /// まなぶ画面用（いまの濃さ）
  static const Color paleTurquoise = Color(0xFFD7F3F1);
  static const Color paleMarine = Color(0xFFC5DCE8);

  /// ふくしゅう・レポートなど用（もう少し明度高め）
  static const Color lighterTurquoise = Color(0xFFEAF8F7);
  static const Color lighterMarine = Color(0xFFE2EFF5);

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
