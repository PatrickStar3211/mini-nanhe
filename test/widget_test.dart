import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/main.dart';

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
  await tester.pumpWidget(const MiniNanheApp());
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

void main() {
  testWidgets('app starts with a loading screen before entering the game', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniNanheApp());

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
    expect(find.text('迷你期 · 第 1 天'), findsOneWidget);
    expect(find.text('冬｜第 1 年・1 月 1 日'), findsOneWidget);
    expect(find.text('好感 Lv.1'), findsOneWidget);
    expect(find.text('0/100'), findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('☺ 平静'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pet-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('49/50'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);

    await tester.tap(find.text('状态'));
    await tester.pumpAndSettle();

    expect(find.text('基础数值'), findsOneWidget);
    expect(find.text('当前好感度'), findsOneWidget);
    expect(find.text('Lv.1  3/100'), findsOneWidget);
    expect(find.text('当前体力'), findsOneWidget);
    expect(find.text('49/50'), findsOneWidget);
    expect(find.text('心情'), findsOneWidget);
    expect(find.text('力量'), findsOneWidget);
    expect(find.text('智力'), findsOneWidget);
    expect(find.text('耐力'), findsOneWidget);
  });

  testWidgets('chat opens dialogue choices', (tester) async {
    await _pumpLoadedApp(tester);
    await tester.tap(find.byKey(const Key('chat-button')));
    await tester.pumpAndSettle();

    expect(find.text('和南河聊聊'), findsOneWidget);
    expect(find.text('问问他今天的心情'), findsOneWidget);

    await tester.tap(find.text('问问他今天的心情'));
    await tester.pumpAndSettle();

    expect(find.text('南河！南河！(*^▽^*)'), findsOneWidget);
    expect(find.text('（今天很开心，因为你有来！）'), findsOneWidget);
    expect(find.text('49/50'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);
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
    expect(find.text('80%'), findsNWidgets(2));

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
    expect(find.text('80%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bgm-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('惬意南河4').last);
    await tester.pumpAndSettle();
    expect(find.text('惬意南河4'), findsOneWidget);
  });

  testWidgets('hit test interaction lowers affection and sets negative mood', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('49/50'), findsOneWidget);
    expect(find.text('0/100'), findsOneWidget);
    expect(_negativeMoodFinder(), findsOneWidget);
    expect(find.textContaining('南河'), findsWidgets);
  });

  testWidgets('hit can downgrade affection level but never below initial', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    for (var i = 0; i < 34; i += 1) {
      await tester.tap(find.byKey(const Key('pet-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('好感 Lv.2'), findsOneWidget);
    expect(find.text('2/100'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hit-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('好感 Lv.1'), findsOneWidget);
    expect(find.text('96/100'), findsOneWidget);
  });

  testWidgets('sleep appears when energy is exhausted and advances the day', (
    tester,
  ) async {
    await _pumpLoadedApp(tester);

    for (var i = 0; i < 50; i += 1) {
      await tester.tap(find.byKey(const Key('pet-button')));
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('0/50'), findsOneWidget);
    expect(find.text('睡觉'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sleep-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('迷你期 · 第 2 天'), findsOneWidget);
    expect(find.text('冬｜第 1 年・1 月 2 日'), findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('睡觉'), findsNothing);
  });
}
