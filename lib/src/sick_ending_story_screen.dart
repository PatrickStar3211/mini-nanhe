import 'package:flutter/material.dart';

import 'theme.dart';

class SickEndingStoryScreen extends StatefulWidget {
  const SickEndingStoryScreen({
    super.key,
    required this.assets,
    required this.panelCounts,
    required this.tapAreaKey,
    required this.onFinished,
  }) : assert(assets.length == panelCounts.length);

  final List<String> assets;
  final List<int> panelCounts;
  final Key tapAreaKey;
  final ValueChanged<BuildContext> onFinished;

  @override
  State<SickEndingStoryScreen> createState() => _SickEndingStoryScreenState();
}

class _SickEndingStoryScreenState extends State<SickEndingStoryScreen> {
  int _pageIndex = 0;
  int _visiblePanels = 1;

  int get _panelCount => widget.panelCounts[_pageIndex];
  String get _asset => widget.assets[_pageIndex];

  void _advance() {
    if (_visiblePanels < _panelCount) {
      setState(() => _visiblePanels += 1);
      return;
    }
    if (_pageIndex < widget.assets.length - 1) {
      setState(() {
        _pageIndex += 1;
        _visiblePanels = 1;
      });
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
          key: widget.tapAreaKey,
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _SickEndingComicPage(
                    asset: _asset,
                    panelCount: _panelCount,
                    visiblePanels: _visiblePanels,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: _SickEndingStoryProgress(
                    pageIndex: _pageIndex,
                    pageCount: widget.assets.length,
                    panelCount: _panelCount,
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

class _SickEndingComicPage extends StatelessWidget {
  const _SickEndingComicPage({
    required this.asset,
    required this.panelCount,
    required this.visiblePanels,
  });

  final String asset;
  final int panelCount;
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
              Image.asset(asset, fit: BoxFit.cover),
              for (var panel = visiblePanels; panel < panelCount; panel += 1)
                _PanelMask(panelIndex: panel, panelCount: panelCount),
            ],
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
    return Positioned.fill(
      child: LayoutBuilder(
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
      ),
    );
  }
}

class _SickEndingStoryProgress extends StatelessWidget {
  const _SickEndingStoryProgress({
    required this.pageIndex,
    required this.pageCount,
    required this.panelCount,
    required this.visiblePanels,
  });

  final int pageIndex;
  final int pageCount;
  final int panelCount;
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
              for (var index = 1; index <= panelCount; index += 1) ...[
                _ProgressDot(active: visiblePanels >= index),
                if (index < panelCount) const SizedBox(width: 6),
              ],
              const SizedBox(width: 12),
              Text(
                '$visiblePanels/$panelCount',
                style: const TextStyle(
                  color: frost,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pageIndex + 1}/$pageCount',
                style: TextStyle(
                  color: frost.withValues(alpha: 0.78),
                  fontSize: 11,
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
