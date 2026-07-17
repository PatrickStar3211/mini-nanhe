import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

enum SicknessStoryChoice { hotWater, attentiveCare }

class SicknessStoryScreen extends StatefulWidget {
  const SicknessStoryScreen({super.key, required this.onFinished});

  final void Function(BuildContext context, SicknessStoryChoice choice)
  onFinished;

  @override
  State<SicknessStoryScreen> createState() => _SicknessStoryScreenState();
}

class _SicknessStoryScreenState extends State<SicknessStoryScreen> {
  int _pageIndex = 0;
  int _visiblePanels = 1;
  SicknessStoryChoice? _choice;

  int get _panelCount => _pageIndex == 0 ? 3 : 2;

  String get _pageAsset {
    if (_pageIndex == 0) return sicknessStoryPage1Asset;
    if (_choice == SicknessStoryChoice.attentiveCare) {
      return sicknessStoryPage2CareAsset;
    }
    return sicknessStoryPage2HotWaterAsset;
  }

  bool get _isChoosing => _pageIndex == 1 && _visiblePanels == 1;

  void _advance() {
    if (_isChoosing) return;

    if (_visiblePanels < _panelCount) {
      setState(() => _visiblePanels += 1);
      return;
    }

    if (_pageIndex == 0) {
      setState(() {
        _pageIndex = 1;
        _visiblePanels = 1;
      });
      return;
    }

    final choice = _choice;
    if (choice == null) return;
    widget.onFinished(context, choice);
  }

  void _selectChoice(SicknessStoryChoice choice) {
    setState(() {
      _choice = choice;
      _visiblePanels = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: SafeArea(
        child: GestureDetector(
          key: const Key('sickness-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _SicknessComicPage(
                    asset: _pageAsset,
                    panelCount: _panelCount,
                    visiblePanels: _visiblePanels,
                    showChoices: _isChoosing,
                    onChoiceSelected: _selectChoice,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: _SicknessStoryProgress(
                    pageIndex: _pageIndex,
                    visiblePanels: _visiblePanels,
                    panelCount: _panelCount,
                    waitingForChoice: _isChoosing,
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

class _SicknessComicPage extends StatelessWidget {
  const _SicknessComicPage({
    required this.asset,
    required this.panelCount,
    required this.visiblePanels,
    required this.showChoices,
    required this.onChoiceSelected,
  });

  final String asset;
  final int panelCount;
  final int visiblePanels;
  final bool showChoices;
  final ValueChanged<SicknessStoryChoice> onChoiceSelected;

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
              Image.asset(asset, fit: BoxFit.cover),
              for (var panel = visiblePanels; panel < panelCount; panel += 1)
                _PanelMask(panelIndex: panel, panelCount: panelCount),
              if (showChoices)
                _SicknessChoiceOverlay(onChoiceSelected: onChoiceSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SicknessChoiceOverlay extends StatelessWidget {
  const _SicknessChoiceOverlay({required this.onChoiceSelected});

  final ValueChanged<SicknessStoryChoice> onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / 941;
        final scaleY = constraints.maxHeight / 1672;

        return Stack(
          children: [
            Positioned(
              left: 190 * scaleX,
              top: 290 * scaleY,
              width: 250 * scaleX,
              height: 230 * scaleY,
              child: _SicknessChoiceButton(
                key: const Key('sickness-story-hot-water-choice'),
                icon: Icons.local_drink_rounded,
                label: '多喝热水',
                onTap: () => onChoiceSelected(SicknessStoryChoice.hotWater),
              ),
            ),
            Positioned(
              left: 505 * scaleX,
              top: 290 * scaleY,
              width: 250 * scaleX,
              height: 230 * scaleY,
              child: _SicknessChoiceButton(
                key: const Key('sickness-story-attentive-care-choice'),
                icon: Icons.volunteer_activism_rounded,
                label: '寸步不离照顾',
                onTap: () =>
                    onChoiceSelected(SicknessStoryChoice.attentiveCare),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SicknessChoiceButton extends StatelessWidget {
  const _SicknessChoiceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF6FFF9EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: deepBlue, size: 36),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelMask extends StatelessWidget {
  const _PanelMask({required this.panelIndex, required this.panelCount});

  final int panelIndex;
  final int panelCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = constraints.maxHeight / panelCount;
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
    );
  }
}

class _SicknessStoryProgress extends StatelessWidget {
  const _SicknessStoryProgress({
    required this.pageIndex,
    required this.visiblePanels,
    required this.panelCount,
    required this.waitingForChoice,
  });

  final int pageIndex;
  final int visiblePanels;
  final int panelCount;
  final bool waitingForChoice;

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
              _ProgressDot(active: pageIndex == 0),
              const SizedBox(width: 6),
              _ProgressDot(active: pageIndex == 1),
              const SizedBox(width: 12),
              Text(
                waitingForChoice ? '选择' : '$visiblePanels/$panelCount',
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
