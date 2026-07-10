import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

class AbuseStoryScreen extends StatefulWidget {
  const AbuseStoryScreen({super.key, required this.onFinished});

  final ValueChanged<BuildContext> onFinished;

  @override
  State<AbuseStoryScreen> createState() => _AbuseStoryScreenState();
}

class _AbuseStoryScreenState extends State<AbuseStoryScreen> {
  static const _panelCount = 3;

  int _visiblePanels = 1;

  void _advance() {
    if (_visiblePanels < _panelCount) {
      setState(() => _visiblePanels += 1);
      return;
    }
    widget.onFinished(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: SafeArea(
        child: GestureDetector(
          key: const Key('abuse-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _AbuseComicPage(visiblePanels: _visiblePanels),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: _AbuseStoryProgress(visiblePanels: _visiblePanels),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbuseComicPage extends StatelessWidget {
  const _AbuseComicPage({required this.visiblePanels});

  final int visiblePanels;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 941 / 1672,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF07111C),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(abuseStoryPage1Asset, fit: BoxFit.cover),
              for (var panel = visiblePanels; panel < 3; panel += 1)
                _PanelMask(panelIndex: panel),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelMask extends StatelessWidget {
  const _PanelMask({required this.panelIndex});

  final int panelIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(0, -1.0 + ((2.0 / 3.0) * panelIndex)),
      child: const FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1 / 3,
        child: ColoredBox(color: Color(0xFF050A12)),
      ),
    );
  }
}

class _AbuseStoryProgress extends StatelessWidget {
  const _AbuseStoryProgress({required this.visiblePanels});

  final int visiblePanels;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 1; index <= 3; index += 1) ...[
                _ProgressDot(active: visiblePanels >= index),
                if (index < 3) const SizedBox(width: 6),
              ],
              const SizedBox(width: 12),
              Text(
                '$visiblePanels/3',
                style: const TextStyle(
                  color: frost,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_drop_down_rounded, color: frost, size: 20),
            ],
          ),
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
        color: active ? gold : Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
