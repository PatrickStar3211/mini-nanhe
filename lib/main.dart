import 'package:flutter/material.dart';

import 'src/game_audio_controller.dart';
import 'src/loading_screen.dart';
import 'src/theme.dart';

void main() {
  runApp(const MiniNanheApp());
}

class MiniNanheApp extends StatelessWidget {
  const MiniNanheApp({super.key, this.audioController});

  final GameAudioController? audioController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '迷你南河',
      debugShowCheckedModeBanner: false,
      theme: buildMiniNanheTheme(),
      home: LoadingScreen(audioController: audioController),
    );
  }
}
