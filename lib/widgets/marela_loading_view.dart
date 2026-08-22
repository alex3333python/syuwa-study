import 'package:flutter/material.dart';

/// Shared Marela splash: official icon + wordmark (matches header branding).
class MarelaLoadingView extends StatelessWidget {
  final String? message;
  final bool showSpinner;

  const MarelaLoadingView({
    super.key,
    this.message,
    this.showSpinner = true,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MarelaBrandMark(),
              if (showSpinner) ...[
                const SizedBox(height: 28),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MarelaBrandMark extends StatelessWidget {
  const _MarelaBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Marela',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/brand/marela_icon.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/brand/marela_wordmark.png',
            height: 48,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}
