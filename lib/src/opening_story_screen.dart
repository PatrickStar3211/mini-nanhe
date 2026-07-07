import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_assets.dart';
import 'theme.dart';

const openingStorySeenPreferenceKey = 'opening_story_seen_v1';

class OpeningStoryScreen extends StatefulWidget {
  const OpeningStoryScreen({super.key, required this.onFinished});

  final ValueChanged<BuildContext> onFinished;

  @override
  State<OpeningStoryScreen> createState() => _OpeningStoryScreenState();
}

class _OpeningStoryScreenState extends State<OpeningStoryScreen> {
  static const _pages = <_OpeningStoryPage>[
    _OpeningStoryPage(asset: openingStoryPage1Asset, panelCount: 3),
    _OpeningStoryPage(asset: openingStoryPage2Asset, panelCount: 3),
    _OpeningStoryPage(asset: openingStoryPage3Asset, panelCount: 2),
  ];

  int _pageIndex = 0;
  int _visiblePanels = 1;
  bool _finishing = false;

  Future<void> _advance() async {
    if (_finishing) return;

    final page = _pages[_pageIndex];
    if (_visiblePanels < page.panelCount) {
      setState(() => _visiblePanels += 1);
      return;
    }

    if (_pageIndex < _pages.length - 1) {
      setState(() {
        _pageIndex += 1;
        _visiblePanels = 1;
      });
      return;
    }

    setState(() => _finishing = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(openingStorySeenPreferenceKey, true);
    if (mounted) widget.onFinished(context);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: SafeArea(
        child: GestureDetector(
          key: const Key('opening-story-tap-area'),
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _ComicPage(
                    key: ValueKey(page.asset),
                    page: page,
                    visiblePanels: _visiblePanels,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: IgnorePointer(
                  child: _StoryProgress(
                    pageIndex: _pageIndex,
                    pageCount: _pages.length,
                    visiblePanels: _visiblePanels,
                    panelCount: page.panelCount,
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

class _OpeningStoryPage {
  const _OpeningStoryPage({required this.asset, required this.panelCount});

  final String asset;
  final int panelCount;
}

class _ComicPage extends StatelessWidget {
  const _ComicPage({
    super.key,
    required this.page,
    required this.visiblePanels,
  });

  final _OpeningStoryPage page;
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
              Image.asset(page.asset, fit: BoxFit.cover),
              for (var panel = visiblePanels; panel < page.panelCount; panel++)
                _PanelMask(panelIndex: panel, panelCount: page.panelCount),
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
    return Align(
      alignment: Alignment(0, -1 + (2 * panelIndex / (panelCount - 1))),
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 1 / panelCount,
        child: const ColoredBox(color: Color(0xFF050A12)),
      ),
    );
  }
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({
    required this.pageIndex,
    required this.pageCount,
    required this.visiblePanels,
    required this.panelCount,
  });

  final int pageIndex;
  final int pageCount;
  final int visiblePanels;
  final int panelCount;

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
              for (var index = 0; index < pageCount; index += 1) ...[
                _ProgressDot(active: index == pageIndex),
                if (index != pageCount - 1) const SizedBox(width: 6),
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
