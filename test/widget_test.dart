import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/main.dart';
import 'package:mini_nanhe/src/character_reaction.dart';
import 'package:mini_nanhe/src/app_version.dart';
import 'package:mini_nanhe/src/game_audio_controller.dart';
import 'package:mini_nanhe/src/home_screen.dart';
import 'package:mini_nanhe/src/opening_story_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

MiniNanheApp _testApp({
  bool? forcePortraitShell,
  MiniNanheDebugState? debugInitialState,
}) {
  return MiniNanheApp(
    audioController: GameAudioController.disabled(),
    forcePortraitShell: forcePortraitShell,
    debugInitialState: debugInitialState,
  );
}

void _mockOpeningStorySeen({bool seen = true}) {
  SharedPreferences.setMockInitialValues({openingStorySeenPreferenceKey: seen});
}

Future<void> _waitForEnterButton(WidgetTester tester) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    if (find.byKey(const Key('enter-game-button')).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Loading screen did not finish preloading within the test timeout.');
}

Future<void> _pumpLoadedApp(
  WidgetTester tester, {
  MiniNanheDebugState? debugInitialState,
}) async {
  _mockOpeningStorySeen();
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_testApp(debugInitialState: debugInitialState));
  await _waitForEnterButton(tester);
  await tester.tap(find.byKey(const Key('enter-game-button')));
  await tester.pumpAndSettle();
  await tester.pump();
}

Finder _negativeMoodFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is Text &&
        (widget.data == '! 愤怒' ||
            widget.data == '… 沮丧' ||
            widget.data == '☂ 伤心');
  });
}

Finder _anyTextContaining(Set<String> values) {
  return find.byWidgetPredicate((widget) {
    final data = widget is Text ? widget.data : null;
    return data != null && values.any(data.contains);
  });
}

String? _currentBackgroundAsset(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;
    if (decoration is! BoxDecoration) continue;
    final image = decoration.image?.image;
    if (image is! AssetImage) continue;
    if (image.assetName.startsWith('assets/images/backgrounds/')) {
      return image.assetName;
    }
  }
  return null;
}

void main() {
  test('all Nanhe voice assets are bundled', () async {
    for (final voice in NanheVoice.values) {
      final data = await rootBundle.load('assets/${voice.assetPath}');
      expect(data.lengthInBytes, greaterThan(0), reason: voice.assetPath);
    }
  });

  testWidgets('app starts with a loading screen before entering the game', (
    tester,
  ) async {
    _mockOpeningStorySeen();
    await tester.pumpWidget(
      _testApp(
        debugInitialState: const MiniNanheDebugState(totalDaysTogether: 3),
      ),
    );

    expect(find.text('正在加载……'), findsOneWidget);
    expect(find.text('迷你南河'), findsWidgets);

    await _waitForEnterButton(tester);
    expect(find.text('正在加载……'), findsNothing);
    expect(find.text('带他回家'), findsOneWidget);
    expect(find.text('陪伴'), findsNothing);

    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();
    expect(find.text('陪伴'), findsOneWidget);
  });

  testWidgets('first entry plays the opening story before the home screen', (
    tester,
  ) async {
    _mockOpeningStorySeen(seen: false);
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        debugInitialState: const MiniNanheDebugState(totalDaysTogether: 3),
      ),
    );
    await _waitForEnterButton(tester);
    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opening-story-tap-area')), findsOneWidget);
    expect(find.byKey(const Key('background-next-button')), findsNothing);
    expect(find.text('1/3'), findsOneWidget);

    for (var tap = 0; tap < 8; tap += 1) {
      await tester.tap(find.byKey(const Key('opening-story-tap-area')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('opening-story-tap-area')), findsNothing);
    expect(find.byKey(const Key('background-next-button')), findsNothing);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(openingStorySeenPreferenceKey), isTrue);
  });

  testWidgets('companion page shows primary interactions and synced values', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    expect(find.text('陪伴'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('手机'), findsOneWidget);
    expect(find.text('战斗'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('回忆'), findsNothing);
    expect(find.text('迷你南河'), findsOneWidget);
    expect(find.text('想和他做什么？'), findsNothing);
    expect(find.byKey(const Key('chat-button')), findsOneWidget);
    expect(find.byKey(const Key('pet-button')), findsOneWidget);
    expect(find.byKey(const Key('observe-button')), findsOneWidget);
    expect(find.byKey(const Key('daily-rest-button')), findsOneWidget);
    expect(find.byKey(const Key('play-button')), findsNothing);
    expect(find.byKey(const Key('walk-button')), findsNothing);
    expect(find.byKey(const Key('feed-button')), findsNothing);
    expect(find.byKey(const Key('hit-button')), findsNothing);
    expect(find.byKey(const Key('sleep-button')), findsNothing);
    expect(find.text('迷你期 · 第 1 天'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 06:00 | 晴'), findsOneWidget);
    expect(find.text('好感 Lv.1'), findsOneWidget);
    expect(find.text('信任 Lv.1'), findsOneWidget);
    expect(find.text('0/100'), findsWidgets);
    expect(find.text('25/25'), findsOneWidget);
    expect(find.byKey(const Key('pressure-indicator')), findsOneWidget);
    expect(find.byKey(const Key('cleanliness-indicator')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('☺ 平静'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();

    expect(find.text('日常状态'), findsOneWidget);
    expect(find.text('当前好感度'), findsOneWidget);
    expect(find.text('Lv.1  3/100'), findsOneWidget);
    expect(find.text('当前信任'), findsOneWidget);
    expect(find.text('Lv.1  1/100'), findsOneWidget);
    expect(find.text('当前体力'), findsOneWidget);
    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('情绪'), findsOneWidget);
    expect(find.text('压力'), findsOneWidget);
    expect(find.text('清洁'), findsOneWidget);
    expect(find.text('健康'), findsWidgets);
    expect(find.text('力量'), findsOneWidget);
    expect(find.text('智力'), findsOneWidget);
    expect(find.text('魅力'), findsOneWidget);
    expect(find.text('艺术'), findsOneWidget);
    expect(find.text('技巧'), findsOneWidget);
    expect(find.text('耐力'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('倾向'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('目前倾向'), findsOneWidget);
    expect(find.text('尚未形成'), findsOneWidget);
  });

  testWidgets('background arrows cycle through unlocked yard homes', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        doghouseUnlocked: true,
        luxuryUnlocked: true,
      ),
    );

    expect(find.byKey(const Key('background-previous-button')), findsOneWidget);
    expect(find.byKey(const Key('background-next-button')), findsOneWidget);
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_luxury_winter_day.webp',
    );

    await tester.tap(find.byKey(const Key('background-next-button')));
    await tester.pumpAndSettle();
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_box_winter_day.webp',
    );

    await tester.tap(find.byKey(const Key('background-next-button')));
    await tester.pumpAndSettle();
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_doghouse_winter_day.webp',
    );

    await tester.tap(find.byKey(const Key('background-previous-button')));
    await tester.pumpAndSettle();
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_box_winter_day.webp',
    );
  });

  testWidgets('mini period starts with limited actions', (tester) async {
    await _pumpLoadedApp(tester);

    expect(find.byKey(const Key('chat-button')), findsOneWidget);
    expect(find.byKey(const Key('pet-button')), findsOneWidget);
    expect(find.byKey(const Key('observe-button')), findsOneWidget);
    expect(find.byKey(const Key('daily-rest-button')), findsOneWidget);
    expect(find.byKey(const Key('feed-button')), findsNothing);
    expect(find.byKey(const Key('hit-button')), findsNothing);
    expect(find.byKey(const Key('action-page-down')), findsNothing);
  });

  testWidgets('mini period unlocks feeding and hit by time and day', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(totalDaysTogether: 61),
    );

    expect(find.byKey(const Key('feed-button')), findsOneWidget);
    expect(find.byKey(const Key('hit-button')), findsOneWidget);
  });

  testWidgets(
    'feeding at noon keeps early wary reactions before affection lv2',
    (tester) async {
      await _pumpLoadedApp(
        tester,
        debugInitialState: const MiniNanheDebugState(
          minuteOfDay: 12 * 60,
          feedEventTriggered: true,
        ),
      );

      await tester.tap(find.byKey(const Key('feed-button')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(_anyTextContaining({'可以吃', '才慢慢靠近'}), findsWidgets);
      expect(find.textContaining('好吃'), findsNothing);
      expect(find.textContaining('想再吃一点'), findsNothing);
    },
  );

  testWidgets('first feeding asks the player to choose food', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(minuteOfDay: 12 * 60),
    );

    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feeding-story-tap-area')), findsOneWidget);
    expect(
      find.byKey(const Key('feeding-story-vegetables-choice')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('feeding-story-vegetables-choice')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feeding-story-curry-choice')), findsOneWidget);
  });

  testWidgets('first feeding vegetable choice is accepted but not loved', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(minuteOfDay: 12 * 60),
    );

    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-vegetables-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();

    expect(find.textContaining('肚子饿'), findsOneWidget);
    expect(find.textContaining('好吃'), findsNothing);

    await tester.tap(find.byKey(const Key('reaction-bubble')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-button')), findsOneWidget);
  });

  testWidgets('first feeding curry choice treats Nanhe as eating together', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(minuteOfDay: 12 * 60),
    );

    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-curry-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();

    expect(find.textContaining('从来没吃过这么好吃的'), findsOneWidget);
  });

  testWidgets('day seven sickness story resolves hot water choice', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 7,
        minuteOfDay: 15 * 60 + 30,
        healthValue: 80,
      ),
    );

    await tester.tap(find.byKey(const Key('observe-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sickness-story-tap-area')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sickness-story-hot-water-choice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sickness-story-attentive-care-choice')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sickness-story-hot-water-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sickness-story-tap-area')), findsNothing);
    expect(find.text('迷你期 · 第 8 天'), findsOneWidget);
    expect(find.textContaining('06:00'), findsOneWidget);

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collection-card-day-seven-sickness-memory')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collection-card-hot-water-cure')),
      findsOneWidget,
    );
  });

  testWidgets('health can show sickness and fatigue together', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        energy: 0,
        healthValue: 25,
        exhaustionCount: 2,
      ),
    );

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();

    expect(find.text('生病、疲劳'), findsOneWidget);
  });

  testWidgets('day seven sickness lowers health with a floor', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 7,
        minuteOfDay: 15 * 60 + 30,
        healthValue: 12,
      ),
    );

    await tester.tap(find.byKey(const Key('observe-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-hot-water-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sickness-story-tap-area')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();
    expect(find.text('亚健康'), findsOneWidget);
  });

  testWidgets('zero health immediately shows death state', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(healthValue: 0),
    );

    expect(find.byKey(const Key('reset-game-button')), findsOneWidget);
    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();
    expect(find.text('死亡'), findsOneWidget);
  });

  testWidgets('very healthy raises max energy', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(healthValue: 95),
    );
    expect(find.text('25/37'), findsOneWidget);
  });

  testWidgets('fatigue halves max energy', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        energy: 25,
        exhaustionCount: 2,
      ),
    );
    expect(find.text('12/12'), findsOneWidget);
  });

  testWidgets('sickness raises interaction cost and pressure gain', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        doghouseUnlocked: true,
        healthValue: 25,
      ),
    );
    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('study-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('9/25'), findsOneWidget);
    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();
    expect(find.text('12%'), findsOneWidget);
  });

  testWidgets('injury raises physical action cost and pressure gain', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 61,
        injury: 10,
      ),
    );

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('22/25'), findsOneWidget);
    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();
    expect(find.text('20%'), findsOneWidget);
  });

  testWidgets('new placeholder destinations open from the bottom navigation', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    final pages = {
      '手机': const Key('phone-page'),
      '战斗': const Key('battle-page'),
    };

    for (final entry in pages.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.byKey(entry.value), findsOneWidget);
      expect(find.byKey(const Key('companion-scroll-view')), findsNothing);
    }
  });

  testWidgets('collection page shows memories achievements and decorations', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('collection-page')), findsOneWidget);
    expect(find.text('回忆'), findsWidgets);
    expect(find.text('初遇'), findsOneWidget);
    expect(
      find.byKey(const Key('collection-card-opening-memory')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('collection-card-opening-memory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('opening-story-tap-area')), findsOneWidget);
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opening-story-tap-area')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();
    expect(find.text('那天下雨了'), findsOneWidget);
    expect(find.text('初次相遇'), findsNothing);
    await tester.tap(find.byKey(const Key('collection-card-rainy-day')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('achievement-preview-rainy-day')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('achievement-preview-description-rainy-day')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('achievement-preview-close-rainy-day')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('achievement-preview-rainy-day')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('collection-tab-装饰')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-card-yard-box')), findsOneWidget);
    expect(
      find.byKey(const Key('collection-card-yard-doghouse')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('collection-card-yard-luxury')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('collection-page-next')), findsOneWidget);
  });

  testWidgets('collection records first feeding memory and curry achievement', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        feedEventTriggered: true,
        feedEventCompleted: true,
        feedEventResolvedCorrectly: true,
      ),
    );

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('collection-card-first-feeding-memory')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('collection-card-first-feeding-memory')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feeding-story-tap-area')), findsOneWidget);
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('feeding-story-vegetables-choice')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feeding-story-curry-choice')), findsOneWidget);
    await tester.tap(find.byKey(const Key('feeding-story-curry-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feeding-story-tap-area')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('collection-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collection-card-curry-favorite')),
      findsOneWidget,
    );
    expect(find.text('最爱吃咖喱饭！'), findsOneWidget);
  });

  testWidgets('collection page fits compact mobile dimensions', (tester) async {
    _mockOpeningStorySeen();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        debugInitialState: const MiniNanheDebugState(totalDaysTogether: 3),
      ),
    );
    await _waitForEnterButton(tester);
    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('collection-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('collection-tab-装饰')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('web portrait shell constrains wide browser layouts', (
    tester,
  ) async {
    _mockOpeningStorySeen();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(forcePortraitShell: true));
    await _waitForEnterButton(tester);
    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-page')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat shows dialogue in the stage bubble', (tester) async {
    await _pumpLoadedApp(tester);
    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('和南河聊聊'), findsNothing);
    expect(find.textContaining('南河'), findsWidgets);
    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('1/100'), findsWidgets);
    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsNothing);
  });

  testWidgets('settings controls audio volumes and restores muted volume', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.text('声音'), findsOneWidget);
    expect(find.text('音乐'), findsOneWidget);
    expect(find.text('音效'), findsOneWidget);
    expect(find.text('语音'), findsOneWidget);
    expect(find.text('背景音乐'), findsOneWidget);
    expect(find.text('惬意南河2'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('music-mute-button')));
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('music-mute-button')));
    await tester.pump();
    expect(find.text('70%'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('voice-volume-slider')),
      const Offset(-200, 0),
    );
    await tester.pump();
    expect(find.text('90%'), findsNothing);

    await tester.tap(find.byKey(const Key('bgm-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('惬意南河4').last);
    await tester.pumpAndSettle();
    expect(find.text('惬意南河4'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('版本 $appVersion'), findsOneWidget);
  });

  testWidgets('manual save slot restores saved game state', (tester) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save-slots-panel')), findsOneWidget);
    expect(find.text('空槽'), findsWidgets);
    await tester.tap(find.byKey(const Key('save-slot-0-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 天 06:30'), findsOneWidget);

    await tester.tap(find.text('陪伴'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('冬 | 第1年 · 1月1日 | 07:00 | 晴'), findsOneWidget);
    expect(find.text('6/100'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-slot-0-load')));
    await tester.pumpAndSettle();

    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);
  });

  testWidgets('save code can import into a slot', (tester) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-slot-0-save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save-slot-0-export')), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    final rawSave = preferences.getString('mini_nanhe_save_slot_0');
    expect(rawSave, isNotNull);
    final saveCode = 'MN1.${base64UrlEncode(utf8.encode(rawSave!))}';
    expect(saveCode, startsWith('MN1.'));

    await tester.ensureVisible(
      find.byKey(const Key('import-save-code-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-save-code-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('import-save-code-field')),
      saveCode,
    );
    await tester.tap(find.byKey(const Key('import-save-confirm-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('已导入到存档 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-slot-0-load')));
    await tester.pumpAndSettle();
    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);
  });

  testWidgets('settings debug tools unlock from version long press', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debug-tools-panel')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.longPress(find.byKey(const Key('app-version')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug-tools-panel')), findsOneWidget);
    expect(find.byKey(const Key('debug-day-slider')), findsOneWidget);
    expect(find.byKey(const Key('debug-time-slider')), findsOneWidget);
    expect(
      find.byKey(const Key('debug-affection-level-slider')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('debug-trust-level-slider')), findsOneWidget);
    expect(
      find.byKey(const Key('debug-affection-progress-slider')),
      findsNothing,
    );
    expect(find.byKey(const Key('debug-trust-progress-slider')), findsNothing);
    expect(find.byKey(const Key('debug-preset-第7天 16:00')), findsNothing);
    expect(find.byKey(const Key('debug-affection-lv2')), findsNothing);
  });

  testWidgets('short screens preserve the character stage and can scroll', (
    tester,
  ) async {
    _mockOpeningStorySeen();
    tester.view.physicalSize = const Size(430, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        debugInitialState: const MiniNanheDebugState(totalDaysTogether: 3),
      ),
    );
    await _waitForEnterButton(tester);
    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('hit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hit test interaction lowers affection and sets negative mood', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(totalDaysTogether: 61),
    );

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('0/100'), findsWidgets);
    expect(_negativeMoodFinder(), findsOneWidget);
    expect(find.textContaining('南河'), findsWidgets);
  });

  testWidgets('hit lowers affection by five after gains', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(totalDaysTogether: 61),
    );

    for (var i = 0; i < 2; i += 1) {
      await tester.tap(find.byKey(const Key('pet-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('6/100'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('好感 Lv.1'), findsOneWidget);
    expect(find.text('1/100'), findsOneWidget);
  });

  testWidgets('first early hit asks for confirmation and plays story', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 3,
        affectionProgress: 12,
        trustProgress: 12,
      ),
    );

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-hit-confirm-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-hit-confirm-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('abuse-story-tap-area')), findsOneWidget);

    for (var i = 0; i < 3; i += 1) {
      await tester.tap(find.byKey(const Key('abuse-story-tap-area')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('abuse-story-tap-area')), findsNothing);
    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('0/100'), findsWidgets);

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('0/100'), findsWidgets);
  });

  testWidgets('injured chat prioritizes hurt reactions over pressure', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(totalDaysTogether: 61),
    );

    for (var i = 0; i < 2; i += 1) {
      await tester.tap(find.byKey(const Key('hit-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_anyTextContaining({'现在会痛', '一定要现在吗'}), findsWidgets);
    expect(find.textContaining('我有点乱'), findsNothing);
  });

  testWidgets('injured and wary Nanhe refuses active interactions', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 61,
        affectionLevel: 2,
        affectionProgress: 50,
      ),
    );

    for (var i = 0; i < 2; i += 1) {
      await tester.tap(find.byKey(const Key('hit-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_anyTextContaining({'现在会痛', '一定要现在吗'}), findsWidgets);
    expect(find.textContaining('再来一次'), findsNothing);

    await tester.tap(find.byKey(const Key('walk-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_anyTextContaining({'现在会痛', '一定要现在吗'}), findsWidgets);
    expect(find.textContaining('想去外面'), findsNothing);
  });

  testWidgets('doghouse unlock morning plays story and training dialog', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        minuteOfDay: 22 * 60,
        affectionLevel: 5,
        trustLevel: 2,
      ),
    );

    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('reaction-bubble')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sleep-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('reaction-bubble')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('doghouse-unlock-story-tap-area')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('doghouse-unlock-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('doghouse-unlock-story-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('doghouse-unlock-story-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training-unlock-confirm-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('training-unlock-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('action-page-down')), findsOneWidget);
    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('study-button')), findsOneWidget);

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-page-next')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collection-card-doghouse-unlock-memory')),
      findsOneWidget,
    );
  });

  testWidgets('luxury doghouse unlock plays story and raises bond', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 26,
        minuteOfDay: 22 * 60,
        affectionLevel: 8,
        trustLevel: 4,
        feedEventResolvedCorrectly: true,
        sicknessEventResolvedCorrectly: true,
        doghouseUnlocked: true,
      ),
    );

    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('reaction-bubble')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sleep-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('reaction-bubble')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('luxury-unlock-story-tap-area')),
      findsOneWidget,
    );
    for (var tap = 0; tap < 5; tap += 1) {
      await tester.tap(find.byKey(const Key('luxury-unlock-story-tap-area')));
      await tester.pumpAndSettle();
    }

    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_luxury_winter_day.webp',
    );
    expect(find.text('好感 Lv.9'), findsOneWidget);
    expect(find.text('信任 Lv.5'), findsOneWidget);

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-page-next')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('collection-card-luxury-unlock-memory')),
      findsOneWidget,
    );
  });

  testWidgets('sick ending triggers on day sixty night and ends after care', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 60,
        minuteOfDay: 21 * 60 + 30,
        affectionLevel: 5,
        trustLevel: 2,
        feedEventTriggered: true,
        feedEventCompleted: true,
        feedEventResolvedCorrectly: false,
        doghouseUnlocked: true,
      ),
    );

    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sick-ending-onset-story-tap-area')),
      findsOneWidget,
    );
    for (var tap = 0; tap < 6; tap += 1) {
      await tester.tap(
        find.byKey(const Key('sick-ending-onset-story-tap-area')),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('sick-ending-care-stage')), findsOneWidget);
    expect(find.byKey(const Key('sick-ending-care-button')), findsOneWidget);
    expect(find.byKey(const Key('chat-button')), findsNothing);
    expect(find.byKey(const Key('sleep-button')), findsNothing);

    for (var tap = 0; tap < 12; tap += 1) {
      await tester.tap(find.byKey(const Key('sick-ending-care-button')));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const Key('sick-ending-final-story-tap-area')),
      findsOneWidget,
    );
    for (var tap = 0; tap < 6; tap += 1) {
      await tester.tap(
        find.byKey(const Key('sick-ending-final-story-tap-area')),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('reset-game-button')), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月2日 | 06:00 | 晴'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.collections_bookmark_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-page-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-page-next')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('collection-card-sick-ending-memory')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('collection-card-sick-ending-memory')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sick-ending-memory-story-tap-area')),
      findsOneWidget,
    );
    for (var tap = 0; tap < 12; tap += 1) {
      await tester.tap(
        find.byKey(const Key('sick-ending-memory-story-tap-area')),
      );
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('collection-tab-成就')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('collection-card-sick-death')), findsOneWidget);
    expect(find.byKey(const Key('collection-card-roadside-one')), findsNothing);
  });

  testWidgets('sick ending triggers on day sixty exhaustion', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 60,
        minuteOfDay: 16 * 60,
        energy: 1,
        affectionLevel: 5,
        trustLevel: 2,
        feedEventTriggered: true,
        feedEventCompleted: true,
        feedEventResolvedCorrectly: false,
        doghouseUnlocked: true,
      ),
    );

    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sick-ending-onset-story-tap-area')),
      findsOneWidget,
    );
  });

  testWidgets('training page restores energy and shows training actions', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(doghouseUnlocked: true),
    );

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('24/25'), findsOneWidget);

    expect(find.byKey(const Key('action-page-up')), findsNothing);
    expect(find.byKey(const Key('action-page-down')), findsOneWidget);

    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('action-page-up')), findsOneWidget);
    expect(find.byKey(const Key('action-page-down')), findsNothing);
    expect(find.byKey(const Key('study-button')), findsOneWidget);
    expect(find.byKey(const Key('exercise-button')), findsOneWidget);
    expect(find.byKey(const Key('game-button')), findsOneWidget);
    expect(find.byKey(const Key('create-button')), findsOneWidget);
    expect(find.byKey(const Key('perform-button')), findsOneWidget);
    expect(find.byKey(const Key('bath-button')), findsOneWidget);
    expect(find.byKey(const Key('outing-button')), findsOneWidget);
    expect(find.byKey(const Key('rest-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('25/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 07:00 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('study-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('17/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 08:00 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('6/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 09:00 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('6/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 09:00 | 晴'), findsOneWidget);
    expect(find.textContaining('有点困'), findsOneWidget);
  });

  testWidgets('training actions show stacked core stat popups only', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(doghouseUnlocked: true),
    );

    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('study-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('智力+1'), findsOneWidget);
    expect(find.text('好奇+1'), findsNothing);
    expect(find.text('自律+1'), findsNothing);
    expect(find.text('压力+6'), findsNothing);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('智力+1'), findsOneWidget);
    expect(find.text('力量+1'), findsOneWidget);
    expect(find.text('耐力+1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('力量+1'), findsOneWidget);
    expect(find.text('耐力+1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('力量+1'), findsOneWidget);
    expect(find.text('耐力+1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('game-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('力量+1'), findsNothing);
    expect(find.text('耐力+1'), findsOneWidget);
    expect(find.text('智力+1'), findsOneWidget);
    expect(find.text('技巧+1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('耐力+1'), findsNothing);
    expect(find.text('智力+1'), findsNothing);
    expect(find.text('技巧+1'), findsNothing);
  });

  testWidgets('training ends early at timed story triggers', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        doghouseUnlocked: true,
        totalDaysTogether: 7,
        minuteOfDay: 15 * 60 + 30,
        energy: 25,
      ),
    );

    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('study-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sickness-story-tap-area')), findsOneWidget);
  });

  testWidgets('late training can end at midnight with full gains', (
    tester,
  ) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        doghouseUnlocked: true,
        totalDaysTogether: 2,
        minuteOfDay: 23 * 60 + 30,
        energy: 25,
      ),
    );

    await tester.tap(find.byKey(const Key('action-page-down')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('study-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('00:00'), findsOneWidget);
    expect(find.text('智力+1'), findsOneWidget);
    expect(find.text('17/25'), findsOneWidget);
  });

  testWidgets('exhaustion forces pending same-day timed story', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(
        totalDaysTogether: 7,
        minuteOfDay: 10 * 60,
        energy: 1,
      ),
    );

    await tester.tap(find.byKey(const Key('observe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sickness-story-tap-area')), findsOneWidget);
  });

  testWidgets('daily play and walk do not grow core stats', (tester) async {
    await _pumpLoadedApp(
      tester,
      debugInitialState: const MiniNanheDebugState(affectionLevel: 2),
    );

    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('技巧+1'), findsNothing);

    await tester.tap(find.byKey(const Key('walk-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('耐力+1'), findsNothing);
  });

  testWidgets('daily rest replaces sleep before night', (tester) async {
    await _pumpLoadedApp(tester);

    expect(find.byKey(const Key('sleep-button')), findsNothing);
    expect(find.byKey(const Key('daily-rest-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('daily-rest-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('还没到睡觉的时候。'), findsNothing);
    expect(find.text('冬 | 第1年 · 1月1日 | 06:30 | 晴'), findsOneWidget);
  });

  testWidgets('sleep after exhaustion resolves after reading sleep text', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    for (var i = 0; i < 25; i += 1) {
      await tester.tap(find.byKey(const Key('pet-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('0/12'), findsOneWidget);
    expect(find.text('睡觉'), findsOneWidget);
    expect(find.byKey(const Key('pet-button')), findsNothing);

    await tester.tap(find.byKey(const Key('sleep-button')));
    await tester.pumpAndSettle();

    expect(find.text('迷你期 · 第 1 天'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
    expect(find.byKey(const Key('sleep-dialogue-hint')), findsOneWidget);
    expect(find.byKey(const Key('pet-button')), findsNothing);
    expect(find.byKey(const Key('action-page-down')), findsNothing);

    await tester.tap(find.byKey(const Key('character-tap-area')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('冬 | 第1年 · 1月1日 | 18:30 | 晴'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded).last);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('迷你期 · 第 2 天'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月2日 | 06:00 | 晴'), findsOneWidget);
    expect(find.text('25/25'), findsOneWidget);
    expect(find.byKey(const Key('pet-button')), findsOneWidget);
  });
}
