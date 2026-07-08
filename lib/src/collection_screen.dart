import 'dart:math';

import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

enum CollectionCategory { memory, achievement, decoration }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.unlockedDecorationIds,
    required this.onReplayOpeningStory,
    required this.onPageTurn,
  });

  final Set<String> unlockedDecorationIds;
  final VoidCallback onReplayOpeningStory;
  final VoidCallback onPageTurn;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  CollectionCategory _category = CollectionCategory.memory;
  final Map<CollectionCategory, int> _pageByCategory = {
    CollectionCategory.memory: 0,
    CollectionCategory.achievement: 0,
    CollectionCategory.decoration: 0,
  };

  int get _pageIndex => _pageByCategory[_category] ?? 0;

  int get _itemsPerPage {
    return switch (_category) {
      CollectionCategory.memory => 3,
      CollectionCategory.achievement => 4,
      CollectionCategory.decoration => 3,
    };
  }

  int get _pageCount {
    final itemCount = switch (_category) {
      CollectionCategory.memory => _memoryEntries.length,
      CollectionCategory.achievement => _achievementEntries.length,
      CollectionCategory.decoration => _decorationEntries.length,
    };
    return max(1, (itemCount / _itemsPerPage).ceil());
  }

  void _selectCategory(CollectionCategory category) {
    if (_category == category) return;
    setState(() => _category = category);
    widget.onPageTurn();
  }

  void _turnPage(int direction) {
    final nextPage = (_pageIndex + direction).clamp(0, _pageCount - 1);
    if (nextPage == _pageIndex) return;
    setState(() => _pageByCategory[_category] = nextPage);
    widget.onPageTurn();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('collection-page'),
      color: const Color(0xFF11151E),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                collectionAlbumAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              _AlbumOverlay(
                category: _category,
                unlockedDecorationIds: widget.unlockedDecorationIds,
                pageIndex: _pageIndex,
                pageCount: _pageCount,
                itemsPerPage: _itemsPerPage,
                onCategorySelected: _selectCategory,
                onPreviousPage: () => _turnPage(-1),
                onNextPage: () => _turnPage(1),
                onReplayOpeningStory: widget.onReplayOpeningStory,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumOverlay extends StatelessWidget {
  const _AlbumOverlay({
    required this.category,
    required this.unlockedDecorationIds,
    required this.pageIndex,
    required this.pageCount,
    required this.itemsPerPage,
    required this.onCategorySelected,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onReplayOpeningStory,
  });

  final CollectionCategory category;
  final Set<String> unlockedDecorationIds;
  final int pageIndex;
  final int pageCount;
  final int itemsPerPage;
  final ValueChanged<CollectionCategory> onCategorySelected;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onReplayOpeningStory;

  @override
  Widget build(BuildContext context) {
    final cards = _visibleCards();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final horizontalInset = width * 0.125;

        return Stack(
          children: [
            Positioned(
              top: height * 0.008,
              right: width * 0.035,
              child: _CategoryTabs(
                selected: category,
                onSelected: onCategorySelected,
              ),
            ),
            Positioned(
              left: horizontalInset,
              right: width * 0.07,
              top: height * 0.115,
              bottom: height * 0.105,
              child: _AlbumContent(
                category: category,
                pageIndex: pageIndex,
                pageCount: pageCount,
                cards: cards,
                onReplayOpeningStory: onReplayOpeningStory,
              ),
            ),
            Positioned(
              right: width * 0.065,
              bottom: height * 0.018,
              child: _PageControls(
                canPrevious: pageIndex > 0,
                canNext: pageIndex < pageCount - 1,
                onPrevious: onPreviousPage,
                onNext: onNextPage,
              ),
            ),
          ],
        );
      },
    );
  }

  List<_CollectionCardData> _visibleCards() {
    final allCards = switch (category) {
      CollectionCategory.memory => _memoryEntries,
      CollectionCategory.achievement => _achievementEntries,
      CollectionCategory.decoration => _decorationEntries.map((entry) {
        return entry.copyWith(
          unlocked: unlockedDecorationIds.contains(entry.id),
        );
      }).toList(),
    };
    final start = pageIndex * itemsPerPage;
    return allCards.skip(start).take(itemsPerPage).toList();
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final CollectionCategory selected;
  final ValueChanged<CollectionCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _TabSpec(CollectionCategory.memory, '回忆'),
      _TabSpec(CollectionCategory.achievement, '成就'),
      _TabSpec(CollectionCategory.decoration, '装饰'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tab in tabs)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: _BookmarkButton(
              spec: tab,
              selected: selected == tab.category,
              onTap: () => onSelected(tab.category),
            ),
          ),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('collection-tab-${spec.label}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: selected ? 1.04 : 0.97,
        child: SizedBox(
          width: 50,
          height: 82,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BookmarkPainter(selected: selected),
                ),
              ),
              Positioned(
                top: 9,
                child: _VerticalLabel(
                  text: spec.label,
                  color: selected ? frost : ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  const _BookmarkPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: selected
            ? const [Color(0xFF496FA8), Color(0xFF25456F)]
            : const [Color(0xFFF4E7C9), Color(0xFFD6BD8A)],
      ).createShader(Offset.zero & size);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD8B664);
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(size.width * 0.08, 0)
      ..lineTo(size.width * 0.92, 0)
      ..lineTo(size.width * 0.92, size.height * 0.72)
      ..lineTo(size.width * 0.50, size.height * 0.96)
      ..lineTo(size.width * 0.08, size.height * 0.72)
      ..close();

    canvas.drawPath(path.shift(const Offset(1, 2)), shadowPaint);
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, borderPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: selected ? 0.12 : 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.08),
      Offset(size.width * 0.28, size.height * 0.68),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter oldDelegate) {
    return oldDelegate.selected != selected;
  }
}

class _VerticalLabel extends StatelessWidget {
  const _VerticalLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rune in text.runes)
          Text(
            String.fromCharCode(rune),
            style: TextStyle(
              color: color,
              fontSize: 14,
              height: 1.04,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.white70, blurRadius: 2),
                Shadow(color: Color(0x66000000), blurRadius: 1),
              ],
            ),
          ),
      ],
    );
  }
}

class _AlbumContent extends StatelessWidget {
  const _AlbumContent({
    required this.category,
    required this.pageIndex,
    required this.pageCount,
    required this.cards,
    required this.onReplayOpeningStory,
  });

  final CollectionCategory category;
  final int pageIndex;
  final int pageCount;
  final List<_CollectionCardData> cards;
  final VoidCallback onReplayOpeningStory;

  @override
  Widget build(BuildContext context) {
    final isAchievement = category == CollectionCategory.achievement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryTitle(category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _categorySubtitle(category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '第 ${pageIndex + 1} / $pageCount 页',
              style: const TextStyle(
                color: mutedInk,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: cards.isEmpty
              ? const _EmptyAlbumSlot()
              : GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isAchievement ? 2 : 1,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isAchievement ? 1.28 : 2.72,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _CollectionCard(
                      data: card,
                      compact: isAchievement,
                      onTap: card.id == 'opening-memory'
                          ? onReplayOpeningStory
                          : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Text(
          _pageHint(category),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.data,
    required this.compact,
    this.onTap,
  });

  final _CollectionCardData data;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !data.unlocked;

    return Material(
      color: Colors.white.withValues(alpha: 0.66),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('collection-card-${data.id}'),
        onTap: locked ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x6689A8C8)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: compact
              ? _CompactCardBody(data: data, locked: locked)
              : _WideCardBody(data: data, locked: locked),
        ),
      ),
    );
  }
}

class _WideCardBody extends StatelessWidget {
  const _WideCardBody({required this.data, required this.locked});

  final _CollectionCardData data;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: _CardImage(data: data, locked: locked),
        ),
        Expanded(
          child: _CardText(data: data, locked: locked),
        ),
      ],
    );
  }
}

class _CompactCardBody extends StatelessWidget {
  const _CompactCardBody({required this.data, required this.locked});

  final _CollectionCardData data;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _CardImage(data: data, locked: locked),
        ),
        Expanded(
          flex: 5,
          child: _CardText(data: data, locked: locked, compact: true),
        ),
      ],
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.data, required this.locked});

  final _CollectionCardData data;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (data.imageAsset != null)
          Image.asset(
            data.imageAsset!,
            fit: BoxFit.cover,
            color: locked ? const Color(0xBBFFFFFF) : null,
            colorBlendMode: locked ? BlendMode.srcATop : null,
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFE6E1D8) : const Color(0xFFEAF2FF),
            ),
            child: Icon(data.icon, color: data.accent, size: 30),
          ),
        if (locked)
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x88EFEAE0)),
            child: Center(
              child: Icon(Icons.lock_rounded, color: mutedInk, size: 26),
            ),
          ),
      ],
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({
    required this.data,
    required this.locked,
    this.compact = false,
  });

  final _CollectionCardData data;
  final bool locked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 5 : 9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            locked ? '？？？' : data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            locked ? '尚未解锁' : data.description,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: mutedInk,
              fontSize: 11,
              height: 1.22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbumSlot extends StatelessWidget {
  const _EmptyAlbumSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x6689A8C8)),
      ),
      child: const Center(
        child: Text(
          '这一页还没有内容',
          style: TextStyle(color: mutedInk, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageImageButton(
          key: const Key('collection-page-previous'),
          direction: -1,
          enabled: canPrevious,
          onTap: onPrevious,
        ),
        const SizedBox(width: 4),
        _PageImageButton(
          key: const Key('collection-page-next'),
          direction: 1,
          enabled: canNext,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PageImageButton extends StatelessWidget {
  const _PageImageButton({
    super.key,
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  final int direction;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: SizedBox(
          width: 48,
          height: 70,
          child: CustomPaint(painter: _PageButtonPainter(direction)),
        ),
      ),
    );
  }
}

class _PageButtonPainter extends CustomPainter {
  const _PageButtonPainter(this.direction);

  final int direction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8EED6), Color(0xFFD8BE86)],
      ).createShader(rect);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFC69A42);
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2B4774);

    final body = RRect.fromRectAndRadius(
      rect.deflate(3),
      const Radius.circular(16),
    );
    canvas.drawRRect(body.shift(const Offset(1, 2)), shadowPaint);
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(body, borderPaint);

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;
    final arrow = Path();
    if (direction < 0) {
      arrow
        ..moveTo(centerX + 8, centerY - 13)
        ..lineTo(centerX - 9, centerY)
        ..lineTo(centerX + 8, centerY + 13);
    } else {
      arrow
        ..moveTo(centerX - 8, centerY - 13)
        ..lineTo(centerX + 9, centerY)
        ..lineTo(centerX - 8, centerY + 13);
    }
    arrow.close();
    canvas.drawPath(arrow, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _PageButtonPainter oldDelegate) {
    return oldDelegate.direction != direction;
  }
}

String _categoryTitle(CollectionCategory category) {
  return switch (category) {
    CollectionCategory.memory => '回忆',
    CollectionCategory.achievement => '成就',
    CollectionCategory.decoration => '装饰',
  };
}

String _categorySubtitle(CollectionCategory category) {
  return switch (category) {
    CollectionCategory.memory => '已经看过的剧情与事件',
    CollectionCategory.achievement => '南河一起留下的记录',
    CollectionCategory.decoration => '已经解锁的背景、皮肤与饰品',
  };
}

String _pageHint(CollectionCategory category) {
  return switch (category) {
    CollectionCategory.memory => '点击已解锁回忆可以重新观看',
    CollectionCategory.achievement => '更多成就会随着玩法补上',
    CollectionCategory.decoration => '当前先展示已解锁背景',
  };
}

class _TabSpec {
  const _TabSpec(this.category, this.label);

  final CollectionCategory category;
  final String label;
}

class _CollectionCardData {
  const _CollectionCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.icon,
    required this.accent,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final IconData icon;
  final Color accent;
  final String? imageAsset;

  _CollectionCardData copyWith({bool? unlocked}) {
    return _CollectionCardData(
      id: id,
      title: title,
      description: description,
      unlocked: unlocked ?? this.unlocked,
      icon: icon,
      accent: accent,
      imageAsset: imageAsset,
    );
  }
}

const _memoryEntries = <_CollectionCardData>[
  _CollectionCardData(
    id: 'opening-memory',
    title: '初遇',
    description: '那场雨里，纸箱和南河都被带回了家。',
    unlocked: true,
    icon: Icons.auto_stories_rounded,
    accent: deepBlue,
    imageAsset: openingStoryPage1Asset,
  ),
  _CollectionCardData(
    id: 'future-memory-1',
    title: '未开放',
    description: '后续迷你期剧情会记录在这里。',
    unlocked: false,
    icon: Icons.question_mark_rounded,
    accent: mutedInk,
  ),
];

const _achievementEntries = <_CollectionCardData>[
  _CollectionCardData(
    id: 'rainy-day',
    title: '那天下雨了',
    description: '观看「初遇」。',
    unlocked: true,
    icon: Icons.water_drop_rounded,
    accent: deepBlue,
  ),
  _CollectionCardData(
    id: 'first-morning',
    title: '第一个早晨',
    description: '迎来和南河一起生活的第二天。',
    unlocked: false,
    icon: Icons.wb_twilight_rounded,
    accent: gold,
  ),
  _CollectionCardData(
    id: 'clean-and-bright',
    title: '干干净净',
    description: '第一次帮南河洗澡。',
    unlocked: false,
    icon: Icons.cleaning_services_rounded,
    accent: azure,
  ),
  _CollectionCardData(
    id: 'pet-again',
    title: '再摸摸也可以',
    description: '第一次让南河露出亲近的反应。',
    unlocked: false,
    icon: Icons.favorite_rounded,
    accent: Color(0xFFE978A2),
  ),
  _CollectionCardData(
    id: 'tired-care',
    title: '别勉强',
    description: '在体力很低时选择休息。',
    unlocked: false,
    icon: Icons.bedtime_rounded,
    accent: mutedInk,
  ),
];

const _decorationEntries = <_CollectionCardData>[
  _CollectionCardData(
    id: 'yard-box',
    title: '破纸箱',
    description: '刚遇见南河时的临时住处。',
    unlocked: true,
    icon: Icons.inventory_2_rounded,
    accent: gold,
    imageAsset: 'assets/images/backgrounds/yard_box_winter_day.webp',
  ),
  _CollectionCardData(
    id: 'yard-doghouse',
    title: '普通狗窝',
    description: '院子里的普通狗窝。',
    unlocked: true,
    icon: Icons.home_rounded,
    accent: deepBlue,
    imageAsset: 'assets/images/backgrounds/yard_doghouse_winter_day.webp',
  ),
  _CollectionCardData(
    id: 'yard-luxury',
    title: '豪华狗窝',
    description: '升级后的豪华住处。',
    unlocked: true,
    icon: Icons.castle_rounded,
    accent: gold,
    imageAsset: 'assets/images/backgrounds/yard_luxury_winter_day.webp',
  ),
];
