import 'package:flutter/material.dart';

/// 画面全体の薄い背景グラデーション（ターコイズ → マリンブルー）。
class AppColors {
  static const Color paleTurquoise = Color(0xFFD7F3F1);
  static const Color paleMarine = Color(0xFFC5DCE8);

  static const LinearGradient screenBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [paleTurquoise, paleMarine],
  );

  static const BoxDecoration screenBackground = BoxDecoration(
    gradient: screenBackgroundGradient,
  );
}
