import 'dart:math';

import 'package:flutter/material.dart';

import 'game_assets.dart';
import 'theme.dart';

enum CollectionCategory { memory, achievement, decoration }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.onReplayOpeningStory,
    required this.onPageTurn,
  });

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

  int get _pageCount {
    final itemCount = switch (_category) {
      CollectionCategory.memory => _memoryEntries.length,
      CollectionCategory.achievement => _achievementEntries.length,
      CollectionCategory.decoration => _decorationEntries.length,
    };
    return max(1, (itemCount / _itemsPerPage).ceil());
  }

  int get _itemsPerPage {
    return switch (_category) {
      CollectionCategory.memory => 2,
      CollectionCategory.achievement => 4,
      CollectionCategory.decoration => 3,
    };
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
    return Center(
      key: const Key('collection-page'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 752),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: AspectRatio(
            aspectRatio: 941 / 1672,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(collectionAlbumAsset, fit: BoxFit.cover),
                  _AlbumOverlay(
                    category: _category,
                    pageIndex: _pageIndex,
                    pageCount: _pageCount,
                    itemsPerPage: _itemsPerPage,
                    onCategorySelected: _selectCategory,
                    onPreviousPage: () => _turnPage(-1),
                    onNextPage: () => _turnPage(1),
                    onReplayOpeningStory: widget.onReplayOpeningStory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumOverlay extends StatelessWidget {
  const _AlbumOverlay({
    required this.category,
    required this.pageIndex,
    required this.pageCount,
    required this.itemsPerPage,
    required this.onCategorySelected,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onReplayOpeningStory,
  });

  final CollectionCategory category;
  final int pageIndex;
  final int pageCount;
  final int itemsPerPage;
  final ValueChanged<CollectionCategory> onCategorySelected;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onReplayOpeningStory;

  @override
  Widget build(BuildContext context) {
    final topCards = _visibleCards().take(2).toList();
    final bottomCards = _visibleCards().skip(2).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned(
              top: height * 0.02,
              right: width * 0.055,
              child: _CategoryTabs(
                selected: category,
                onSelected: onCategorySelected,
              ),
            ),
            Positioned(
              left: width * 0.085,
              right: width * 0.055,
              top: height * 0.105,
              height: height * 0.41,
              child: _AlbumSection(
                title: _categoryTitle(category),
                subtitle: _categorySubtitle(category),
                cards: topCards,
                onReplayOpeningStory: onReplayOpeningStory,
              ),
            ),
            Positioned(
              left: width * 0.085,
              right: width * 0.055,
              top: height * 0.565,
              height: height * 0.34,
              child: _AlbumSection(
                title: '第 ${pageIndex + 1} / $pageCount 页',
                subtitle: _pageHint(category),
                cards: bottomCards,
                compact: true,
                onReplayOpeningStory: onReplayOpeningStory,
              ),
            ),
            Positioned(
              right: width * 0.105,
              bottom: height * 0.028,
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
      CollectionCategory.decoration => _decorationEntries,
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
      (CollectionCategory.memory, '回忆'),
      (CollectionCategory.achievement, '成就'),
      (CollectionCategory.decoration, '装饰'),
    ];

    return Row(
      children: [
        for (final tab in tabs)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _BookmarkButton(
              label: tab.$2,
              selected: selected == tab.$1,
              onTap: () => onSelected(tab.$1),
            ),
          ),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 68,
      child: TextButton(
        key: Key('collection-tab-$label'),
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 18),
          foregroundColor: selected ? frost : ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: selected
              ? const Color(0xCC2D4E8A)
              : Colors.white.withValues(alpha: 0.16),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({
    required this.title,
    required this.subtitle,
    required this.cards,
    required this.onReplayOpeningStory,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<_CollectionCardData> cards;
  final VoidCallback onReplayOpeningStory;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: cards.isEmpty
              ? const _EmptyAlbumSlot()
              : GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 2 : 1,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: compact ? 1.45 : 2.35,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _CollectionCard(
                      data: card,
                      onTap: card.id == 'opening-memory'
                          ? onReplayOpeningStory
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.data, this.onTap});

  final _CollectionCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !data.unlocked;

    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('collection-card-${data.id}'),
        onTap: locked ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x809AB0C7)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (data.imageAsset != null)
                      Image.asset(
                        data.imageAsset!,
                        fit: BoxFit.cover,
                        color: locked ? const Color(0xAAFFFFFF) : null,
                        colorBlendMode: locked ? BlendMode.srcATop : null,
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: locked
                              ? const Color(0xFFE5E1DA)
                              : const Color(0xFFEAF2FF),
                        ),
                        child: Icon(data.icon, color: data.accent, size: 32),
                      ),
                    if (locked)
                      const ColoredBox(
                        color: Color(0x88EFEAE0),
                        child: Icon(Icons.lock_rounded, color: mutedInk),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
                      const SizedBox(height: 4),
                      Text(
                        locked ? '尚未解锁' : data.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mutedInk,
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _EmptyAlbumSlot extends StatelessWidget {
  const _EmptyAlbumSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x669AB0C7)),
      ),
      child: const Center(
        child: Text(
          '这一页还没有内容',
          style: TextStyle(color: mutedInk, fontWeight: FontWeight.w700),
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
      children: [
        _PageButton(
          key: const Key('collection-page-previous'),
          icon: Icons.chevron_left_rounded,
          onPressed: canPrevious ? onPrevious : null,
        ),
        const SizedBox(width: 8),
        _PageButton(
          key: const Key('collection-page-next'),
          icon: Icons.chevron_right_rounded,
          onPressed: canNext ? onNext : null,
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(
          alpha: onPressed == null ? 0.25 : 0.72,
        ),
        foregroundColor: onPressed == null ? mutedInk : deepBlue,
      ),
    );
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
