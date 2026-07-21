import 'package:flutter/material.dart';

import 'theme.dart';

class EvolutionStoryConfig {
  const EvolutionStoryConfig({
    required this.fromName,
    required this.toName,
    required this.fromAsset,
    required this.toAsset,
    required this.resultText,
  });

  final String fromName;
  final String toName;
  final String fromAsset;
  final String toAsset;
  final String resultText;
}

class EvolutionStoryScreen extends StatefulWidget {
  const EvolutionStoryScreen({
    super.key,
    required this.config,
    required this.onFinished,
  });

  final EvolutionStoryConfig config;
  final ValueChanged<BuildContext> onFinished;

  @override
  State<EvolutionStoryScreen> createState() => _EvolutionStoryScreenState();
}

class _EvolutionStoryScreenState extends State<EvolutionStoryScreen> {
  static const _phaseCount = 4;

  int _phase = 0;

  void _advance() {
    if (_phase < _phaseCount - 1) {
      setState(() => _phase += 1);
      return;
    }
    widget.onFinished(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03060D),
      body: SafeArea(
        child: GestureDetector(
          key: const Key('evolution-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _EvolutionBackground(phase: _phase),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _EvolutionStage(config: widget.config, phase: _phase),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 24,
                child: _EvolutionCaption(config: widget.config, phase: _phase),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionBackground extends StatelessWidget {
  const _EvolutionBackground({required this.phase});

  final int phase;

  @override
  Widget build(BuildContext context) {
    final glow = switch (phase) {
      0 => 0.18,
      1 => 0.42,
      2 => 0.72,
      _ => 0.92,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [
                Color.lerp(const Color(0xFF123D67), frost, glow)!,
                Color.lerp(const Color(0xFF081A30), azure, glow * 0.55)!,
                const Color(0xFF03060D),
              ],
            ),
          ),
        ),
        for (var index = 0; index < 3; index += 1)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
              width: 180.0 + phase * 38 + index * 72,
              height: 180.0 + phase * 38 + index * 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: frost.withValues(alpha: 0.14 + phase * 0.035),
                  width: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EvolutionStage extends StatelessWidget {
  const _EvolutionStage({required this.config, required this.phase});

  final EvolutionStoryConfig config;
  final int phase;

  bool get _showResult => phase == 3;
  bool get _showNewSilhouette => phase == 2;

  @override
  Widget build(BuildContext context) {
    final asset = _showResult || _showNewSilhouette
        ? config.toAsset
        : config.fromAsset;
    final scale = switch (phase) {
      0 => 0.92,
      1 => 1.0,
      2 => 1.12,
      _ => 1.04,
    };
    final glowOpacity = switch (phase) {
      0 => 0.18,
      1 => 0.48,
      2 => 0.88,
      _ => 0.38,
    };

    return AspectRatio(
      aspectRatio: 0.76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            width: 280 + phase * 34,
            height: 280 + phase * 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: frost.withValues(alpha: glowOpacity * 0.18),
              boxShadow: [
                BoxShadow(
                  color: frost.withValues(alpha: glowOpacity),
                  blurRadius: 60 + phase * 20,
                  spreadRadius: 8 + phase * 8,
                ),
              ],
            ),
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 360),
            scale: scale,
            child: _EvolutionCharacterImage(
              asset: asset,
              silhouette: !_showResult,
              flash: phase >= 1,
            ),
          ),
          if (phase == 2)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.62),
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvolutionCharacterImage extends StatelessWidget {
  const _EvolutionCharacterImage({
    required this.asset,
    required this.silhouette,
    required this.flash,
  });

  final String asset;
  final bool silhouette;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, fit: BoxFit.contain);
    if (!silhouette) {
      return SizedBox(width: 240, height: 300, child: image);
    }

    return SizedBox(
      width: 240,
      height: 300,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          flash ? Colors.white : const Color(0xFFBCEBFF),
          BlendMode.srcIn,
        ),
        child: image,
      ),
    );
  }
}

class _EvolutionCaption extends StatelessWidget {
  const _EvolutionCaption({required this.config, required this.phase});

  final EvolutionStoryConfig config;
  final int phase;

  String get _text {
    return switch (phase) {
      0 => '${config.fromName}的样子好像要发生变化了……',
      1 => '${config.fromName}被耀眼的光芒包围了！',
      2 => '光芒中的轮廓正在变化',
      _ => config.resultText,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEFFFF8E7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3C98A), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ink,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 4; index += 1) ...[
                  _ProgressDot(active: phase >= index),
                  if (index < 3) const SizedBox(width: 6),
                ],
                const SizedBox(width: 10),
                const Icon(Icons.arrow_drop_down_rounded, color: ink, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? gold : mutedInk.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
