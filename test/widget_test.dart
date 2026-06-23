import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/main.dart';

void main() {
  testWidgets('character status and primary interactions are available', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniNanheApp());

    expect(find.text('迷你南河'), findsOneWidget);
    expect(find.text('呼唤'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('观察'), findsOneWidget);
    expect(find.text('迷你期 · 第 1 天'), findsOneWidget);
    expect(find.text('冬｜第 1 年・1 月 1 日'), findsOneWidget);
    expect(find.text('好感 Lv.1'), findsOneWidget);
    expect(find.text('0/100'), findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('☺ 平静'), findsOneWidget);
    expect(find.text('♥ 亲近'), findsNothing);
    expect(find.text('轻点角色，看看他现在想说什么'), findsNothing);

    await tester.tap(find.byKey(const Key('call-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('49/50'), findsOneWidget);
    expect(find.text('3/100'), findsOneWidget);
    expect(find.textContaining('南河'), findsWidgets);
    expect(find.textContaining('（'), findsWidgets);
  });

  testWidgets('chat opens dialogue choices', (tester) async {
    await tester.pumpWidget(const MiniNanheApp());
    await tester.tap(find.byKey(const Key('talk-button')));
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

  testWidgets('sleep appears when energy is exhausted and advances the day', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniNanheApp());

    for (var i = 0; i < 50; i += 1) {
      await tester.tap(find.byKey(const Key('call-button')));
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
