import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/features/home/widgets/ai_topics_carousel.dart';

/// Écran dédié aux topics (accessible via /ai-topics ou depuis le carousel).
class AiTopicsScreen extends ConsumerWidget {
  const AiTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l.aiTopicsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: const AiTopicsCarousel(showHeader: false),
    );
  }
}
