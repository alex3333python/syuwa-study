import 'package:flutter/material.dart';

class WritingCanvas extends StatelessWidget {
  const WritingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: const Center(
        child: Text(
          '筆算スペース',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
