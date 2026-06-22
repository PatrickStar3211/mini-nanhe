import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/main.dart';

void main() {
  testWidgets('character and primary interactions are available', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniNanheApp());

    expect(find.text('迷你南河'), findsWidgets);
    expect(find.text('呼喚'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('觀察'), findsOneWidget);
    expect(find.text('迷你期 · 第 12 天'), findsOneWidget);
    expect(find.text('春｜第 1 年・1 月 12 日'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call-button')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('可以繼續和他互動'), findsOneWidget);
    expect(find.textContaining('南河'), findsWidgets);
    expect(find.textContaining('（'), findsOneWidget);
  });

  testWidgets('chat opens dialogue choices', (tester) async {
    await tester.pumpWidget(const MiniNanheApp());
    await tester.tap(find.byKey(const Key('talk-button')));
    await tester.pumpAndSettle();

    expect(find.text('和南河聊聊'), findsOneWidget);
    expect(find.text('問問他今天的心情'), findsOneWidget);

    await tester.tap(find.text('問問他今天的心情'));
    await tester.pumpAndSettle();

    expect(find.text('南河！南河！(*^▽^*)'), findsOneWidget);
    expect(find.text('（今天很開心，因為你有來！）'), findsOneWidget);
  });
}
