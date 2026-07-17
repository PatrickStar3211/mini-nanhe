import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

class DoghouseUnlockStoryScreen extends StatefulWidget {
  const DoghouseUnlockStoryScreen({super.key, required this.onFinished});

  final ValueChanged<BuildContext> onFinished;

  @override
  State<DoghouseUnlockStoryScreen> createState() =>
      _DoghouseUnlockStoryScreenState();
}

class _DoghouseUnlockStoryScreenState extends State<DoghouseUnlockStoryScreen> {
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
          key: const Key('doghouse-unlock-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _DoghouseUnlockComicPage(
                    visiblePanels: _visiblePanels,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: _DoghouseUnlockStoryProgress(
                    visiblePanels: _visiblePanels,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoghouseUnlockComicPage extends StatelessWidget {
  const _DoghouseUnlockComicPage({required this.visiblePanels});

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
              Image.asset(doghouseUnlockStoryPage1Asset, fit: BoxFit.cover),
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
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = constraints.maxHeight / 3;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: panelHeight * panelIndex,
                height: panelHeight,
                child: const ColoredBox(color: Color(0xFF050A12)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoghouseUnlockStoryProgress extends StatelessWidget {
  const _DoghouseUnlockStoryProgress({required this.visiblePanels});

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
