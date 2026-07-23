import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/src/lol_rank_system.dart';

void main() {
  test('Chinese rank labels and divisions are mapped from total LP', () {
    expect(LolRankPosition.fromTotalLp(0).displayLabel, '黑铁 IV · 0 LP');
    expect(LolRankPosition.fromTotalLp(400).displayLabel, '青铜 IV · 0 LP');
    expect(LolRankPosition.fromTotalLp(800).displayLabel, '白银 IV · 0 LP');
    expect(LolRankPosition.fromTotalLp(2800).displayLabel, '大师 0分');
    expect(LolRankPosition.fromTotalLp(4000).displayLabel, '宗师 1200分');
    expect(LolRankPosition.fromTotalLp(4400).displayLabel, '王者 1600分');
  });

  test('division skill anchors climb quickly before diamond', () {
    expect(
      LolRankRules.requiredSkillForPosition(LolRankPosition.fromTotalLp(1600)),
      70,
    );
    expect(
      LolRankRules.requiredSkillForPosition(LolRankPosition.fromTotalLp(2000)),
      100,
    );
    expect(
      LolRankRules.requiredSkillForPosition(LolRankPosition.fromTotalLp(2400)),
      200,
    );
    expect(
      LolRankRules.requiredSkillForPosition(LolRankPosition.fromTotalLp(2800)),
      300,
    );
  });

  test('apex score converts to the agreed skill curve', () {
    expect(LolRankRules.requiredSkillForApexScore(0), 300);
    expect(LolRankRules.requiredSkillForApexScore(1200), 900);
    expect(LolRankRules.requiredSkillForApexScore(1600), 1200);
    expect(LolRankRules.requiredSkillForApexScore(2000), 1500);
    expect(LolRankRules.requiredSkillForApexScore(2400), 1900);
    expect(LolRankRules.requiredSkillForApexScore(2600), 2100);
  });

  test(
    'win streak lowers odds and loss streak raises odds without stack caps',
    () {
      final position = LolRankPosition.fromTotalLp(2800);
      double chance({int wins = 0, int losses = 0}) {
        return LolRankRules.calculateWinChance(
          skill: 300,
          position: position,
          pressure: 0,
          healthCondition: LolHealthCondition.healthy,
          injured: false,
          consecutiveWins: wins,
          consecutiveLosses: losses,
          randomModifier: 0,
        );
      }

      expect(chance(), 50);
      expect(chance(wins: 12), 38);
      expect(chance(losses: 12), 62);
      expect(chance(wins: 100), LolRankRules.minWinChance);
      expect(chance(losses: 100), LolRankRules.maxWinChance);
    },
  );

  test('low ranks reward a large positive skill gap', () {
    double chance({required int skill, required int totalLp}) {
      return LolRankRules.calculateWinChance(
        skill: skill,
        position: LolRankPosition.fromTotalLp(totalLp),
        pressure: 0,
        healthCondition: LolHealthCondition.healthy,
        injured: false,
        consecutiveWins: 0,
        consecutiveLosses: 0,
        randomModifier: 0,
      );
    }

    expect(chance(skill: 100, totalLp: 0), closeTo(89.75, 0.1));
    expect(chance(skill: 100, totalLp: 1600), closeTo(71.45, 0.1));
    expect(chance(skill: 130, totalLp: 2000), closeTo(66.36, 0.1));
  });

  test('health pressure injury and random modifier affect win chance', () {
    final position = LolRankPosition.fromTotalLp(2800);
    final chance = LolRankRules.calculateWinChance(
      skill: 300,
      position: position,
      pressure: 50,
      healthCondition: LolHealthCondition.sick,
      injured: true,
      consecutiveWins: 0,
      consecutiveLosses: 0,
      randomModifier: -5,
    );
    expect(chance, 10);
    expect(LolRankRules.winChanceLabel(chance), '无法战胜');
    expect(LolRankRules.winChanceLabel(80), '手拿把掐');
  });

  test('LP rolls stay within configured win and loss ranges', () {
    expect(LolRankRules.lpDeltaForRoll(won: true, roll: 0), 20);
    expect(LolRankRules.lpDeltaForRoll(won: true, roll: 5), 25);
    expect(LolRankRules.lpDeltaForRoll(won: false, roll: 0), -15);
    expect(LolRankRules.lpDeltaForRoll(won: false, roll: 5), -20);
  });

  test('order eligibility and hourly prices use peak rank and skill', () {
    expect(LolRankRules.orderSuccessChance, 0.95);
    expect(LolRankRules.orderFailureChance, 0.05);
    expect(
      LolRankRules.canAcceptOrder(
        historicalPeakTier: LolRankTier.master,
        skill: 300,
        minimumPeakTier: LolRankTier.master,
        minimumSkill: 300,
      ),
      isTrue,
    );
    expect(
      LolRankRules.canAcceptOrder(
        historicalPeakTier: LolRankTier.diamond,
        skill: 1900,
        minimumPeakTier: LolRankTier.master,
        minimumSkill: 300,
      ),
      isFalse,
    );
    expect(
      LolRankRules.hourlyOrderRate(
        type: LolOrderType.teaching,
        rankBand: LolOrderRankBand.high,
      ),
      80,
    );
    expect(
      LolRankRules.hourlyOrderRate(
        type: LolOrderType.companion,
        rankBand: LolOrderRankBand.low,
      ),
      70,
    );
    expect(
      LolRankRules.hourlyOrderRate(
        type: LolOrderType.boosting,
        rankBand: LolOrderRankBand.high,
      ),
      100,
    );
    expect(
      LolRankRules.hourlyOrderRate(
        type: LolOrderType.flex,
        rankBand: LolOrderRankBand.high,
      ),
      120,
    );
  });
}
