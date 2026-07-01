import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/main.dart';
import 'package:mini_nanhe/src/character_reaction.dart';
import 'package:mini_nanhe/src/game_audio_controller.dart';

MiniNanheApp _testApp() {
  return MiniNanheApp(audioController: GameAudioController.disabled());
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

Future<void> _pumpLoadedApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_testApp());
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
    await tester.pumpWidget(_testApp());

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
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('抚摸'), findsOneWidget);
    expect(find.text('观察'), findsOneWidget);
    expect(find.text('散步'), findsOneWidget);
    expect(find.text('喂食'), findsOneWidget);
    expect(find.text('殴打'), findsOneWidget);
    expect(find.text('玩耍'), findsOneWidget);
    expect(find.text('睡觉'), findsOneWidget);
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
      find.text('性格与特质'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('性格'), findsOneWidget);
    expect(find.text('特质'), findsOneWidget);
    expect(find.text('普通'), findsOneWidget);
    expect(find.text('无'), findsOneWidget);
  });

  testWidgets('background arrows cycle through unlocked yard homes', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    expect(find.byKey(const Key('background-previous-button')), findsOneWidget);
    expect(find.byKey(const Key('background-next-button')), findsOneWidget);
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_doghouse_winter_day.webp',
    );

    await tester.tap(find.byKey(const Key('background-next-button')));
    await tester.pumpAndSettle();
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

    await tester.tap(find.byKey(const Key('background-previous-button')));
    await tester.pumpAndSettle();
    expect(
      _currentBackgroundAsset(tester),
      'assets/images/backgrounds/yard_luxury_winter_day.webp',
    );
  });

  testWidgets('new placeholder destinations open from the bottom navigation', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    final pages = {
      '手机': const Key('phone-page'),
      '战斗': const Key('battle-page'),
      '收藏': const Key('collection-page'),
    };

    for (final entry in pages.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.byKey(entry.value), findsOneWidget);
      expect(find.byKey(const Key('companion-scroll-view')), findsNothing);
    }
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
    expect(find.text('版本 0.2.6'), findsOneWidget);
  });

  testWidgets('short screens preserve the character stage and can scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await _waitForEnterButton(tester);
    await tester.tap(find.byKey(const Key('enter-game-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('hit-button')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('companion-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('hit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hit test interaction lowers affection and sets negative mood', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('0/100'), findsWidgets);
    expect(_negativeMoodFinder(), findsOneWidget);
    expect(find.textContaining('南河'), findsWidgets);
  });

  testWidgets('hit lowers affection by five after gains', (tester) async {
    await _pumpLoadedApp(tester);

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

  testWidgets('injured chat prioritizes hurt reactions over pressure', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

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
    await _pumpLoadedApp(tester);

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

  testWidgets('training page restores energy and shows training actions', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

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
    expect(find.text('22/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 07:30 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('18/25'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 08:00 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('14/26'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 08:30 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('10/26'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 09:00 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('6/27'), findsOneWidget);
    expect(find.text('6/29'), findsNothing);
    expect(find.text('冬 | 第1年 · 1月1日 | 09:30 | 晴'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('腿软'), findsOneWidget);
  });

  testWidgets('sleep before night shows a hint without advancing time', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.byKey(const Key('sleep-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('还没到睡觉的时候。'), findsOneWidget);
    expect(find.text('冬 | 第1年 · 1月1日 | 06:00 | 晴'), findsOneWidget);
  });

  testWidgets('sleep after exhaustion resolves after reading sleep text', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    for (var i = 0; i < 25; i += 1) {
      await tester.tap(find.byKey(const Key('pet-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('0/25'), findsOneWidget);
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
