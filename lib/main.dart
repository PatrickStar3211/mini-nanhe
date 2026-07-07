import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/game_audio_controller.dart';
import 'src/loading_screen.dart';
import 'src/theme.dart';

void main() {
  runApp(const MiniNanheApp());
}

class MiniNanheApp extends StatelessWidget {
  const MiniNanheApp({
    super.key,
    this.audioController,
    this.forcePortraitShell,
  });

  final GameAudioController? audioController;
  final bool? forcePortraitShell;

  @override
  Widget build(BuildContext context) {
    final usePortraitShell = forcePortraitShell ?? kIsWeb;

    return MaterialApp(
      title: '迷你南河',
      debugShowCheckedModeBanner: false,
      theme: buildMiniNanheTheme(),
      builder: (context, child) {
        if (!usePortraitShell) return child ?? const SizedBox.shrink();
        return _PortraitWebShell(child: child ?? const SizedBox.shrink());
      },
      home: LoadingScreen(audioController: audioController),
    );
  }
}

class _PortraitWebShell extends StatelessWidget {
  const _PortraitWebShell({required this.child});

  static const _targetAspectRatio = 390 / 844;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF11151E),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          var width = maxWidth;
          var height = width / _targetAspectRatio;

          if (height > maxHeight) {
            height = maxHeight;
            width = height * _targetAspectRatio;
          }

          return Center(
            child: SizedBox(width: width, height: height, child: child),
          );
        },
      ),
    );
  }
}
