import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

enum FeedingStoryChoice { vegetables, curry }

class FeedingStoryScreen extends StatefulWidget {
  const FeedingStoryScreen({super.key, required this.onFinished});

  final void Function(BuildContext context, FeedingStoryChoice choice)
  onFinished;

  @override
  State<FeedingStoryScreen> createState() => _FeedingStoryScreenState();
}

class _FeedingStoryScreenState extends State<FeedingStoryScreen> {
  int _pageIndex = 0;
  int _visiblePanels = 1;
  FeedingStoryChoice? _choice;

  String get _pageAsset {
    if (_pageIndex == 0) return feedingStoryPage1Asset;
    if (_choice == FeedingStoryChoice.vegetables) {
      return feedingStoryPage2VegetablesAsset;
    }
    return feedingStoryPage2CurryAsset;
  }

  bool get _isChoosing => _pageIndex == 1 && _visiblePanels == 1;

  void _advance() {
    if (_isChoosing) return;

    if (_visiblePanels < 2) {
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

  void _selectChoice(FeedingStoryChoice choice) {
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
          key: const Key('feeding-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _FeedingComicPage(
                    asset: _pageAsset,
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
                  child: _FeedingStoryProgress(
                    pageIndex: _pageIndex,
                    visiblePanels: _visiblePanels,
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

class _FeedingComicPage extends StatelessWidget {
  const _FeedingComicPage({
    required this.asset,
    required this.visiblePanels,
    required this.showChoices,
    required this.onChoiceSelected,
  });

  final String asset;
  final int visiblePanels;
  final bool showChoices;
  final ValueChanged<FeedingStoryChoice> onChoiceSelected;

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
              for (var panel = visiblePanels; panel < 2; panel += 1)
                _PanelMask(panelIndex: panel),
              if (showChoices)
                _ChoiceOverlay(onChoiceSelected: onChoiceSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceOverlay extends StatelessWidget {
  const _ChoiceOverlay({required this.onChoiceSelected});

  final ValueChanged<FeedingStoryChoice> onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / 941;
        final scaleY = constraints.maxHeight / 1672;

        return Stack(
          children: [
            Positioned(
              left: 250 * scaleX,
              top: 280 * scaleY,
              width: 225 * scaleX,
              height: 290 * scaleY,
              child: _ChoiceImageButton(
                key: const Key('feeding-story-vegetables-choice'),
                asset: feedingChoiceVegetablesAsset,
                semanticLabel: '随便抓一把青菜',
                onTap: () => onChoiceSelected(FeedingStoryChoice.vegetables),
              ),
            ),
            Positioned(
              left: 555 * scaleX,
              top: 280 * scaleY,
              width: 230 * scaleX,
              height: 290 * scaleY,
              child: _ChoiceImageButton(
                key: const Key('feeding-story-curry-choice'),
                asset: feedingChoiceCurryAsset,
                semanticLabel: '和自己一样的咖喱饭',
                onTap: () => onChoiceSelected(FeedingStoryChoice.curry),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChoiceImageButton extends StatelessWidget {
  const _ChoiceImageButton({
    super.key,
    required this.asset,
    required this.semanticLabel,
    required this.onTap,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Image.asset(asset, fit: BoxFit.fill),
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
      alignment: Alignment(0, -1.0 + (2.0 * panelIndex)),
      child: const FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.5,
        child: ColoredBox(color: Color(0xFF050A12)),
      ),
    );
  }
}

class _FeedingStoryProgress extends StatelessWidget {
  const _FeedingStoryProgress({
    required this.pageIndex,
    required this.visiblePanels,
    required this.waitingForChoice,
  });

  final int pageIndex;
  final int visiblePanels;
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
                waitingForChoice ? '选择' : '$visiblePanels/2',
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
