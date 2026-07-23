import 'dart:math';

enum LolRankTier {
  iron('黑铁'),
  bronze('青铜'),
  silver('白银'),
  gold('黄金'),
  platinum('铂金'),
  emerald('翡翠'),
  diamond('钻石'),
  master('大师'),
  grandmaster('宗师'),
  challenger('王者');

  const LolRankTier(this.label);

  final String label;
}

enum LolDivision {
  four('IV'),
  three('III'),
  two('II'),
  one('I');

  const LolDivision(this.label);

  final String label;
}

enum LolHealthCondition { veryHealthy, healthy, subHealthy, unhealthy, sick }

enum LolOrderType { teaching, companion, boosting, flex }

enum LolOrderRankBand { low, high }

class LolRankPosition {
  const LolRankPosition._({
    required this.tier,
    this.division,
    this.lp = 0,
    this.apexScore = 0,
  });

  factory LolRankPosition.fromTotalLp(int totalLp) {
    final safeLp = max(0, totalLp);
    if (safeLp >= LolRankRules.masterTotalLp) {
      final apexScore = safeLp - LolRankRules.masterTotalLp;
      return LolRankPosition._(
        tier: LolRankRules.tierForApexScore(apexScore),
        apexScore: apexScore,
      );
    }

    final tierIndex = safeLp ~/ LolRankRules.lpPerTier;
    final tierLp = safeLp % LolRankRules.lpPerTier;
    final divisionIndex = tierLp ~/ LolRankRules.lpPerDivision;
    return LolRankPosition._(
      tier: LolRankRules.divisionTiers[tierIndex],
      division: LolDivision.values[divisionIndex],
      lp: tierLp % LolRankRules.lpPerDivision,
    );
  }

  final LolRankTier tier;
  final LolDivision? division;
  final int lp;
  final int apexScore;

  bool get isApex => tier.index >= LolRankTier.master.index;

  String get displayLabel => isApex
      ? '${tier.label} $apexScore分'
      : '${tier.label} ${division!.label} · $lp LP';
}

class LolRankRules {
  const LolRankRules._();

  static const lpPerDivision = 100;
  static const divisionsPerTier = 4;
  static const lpPerTier = lpPerDivision * divisionsPerTier;
  static const masterTotalLp = 7 * lpPerTier;
  static const grandmasterScore = 1200;
  static const challengerScore = 1600;
  static const proScore = 2000;
  static const orderSuccessChance = 0.95;
  static const orderFailureChance = 0.05;
  static const minWinChance = 5.0;
  static const maxWinChance = 95.0;
  static const lowRankOverqualificationThreshold = 20.0;
  static const maxLowRankOverqualificationBonus = 12.5;

  static const divisionTiers = <LolRankTier>[
    LolRankTier.iron,
    LolRankTier.bronze,
    LolRankTier.silver,
    LolRankTier.gold,
    LolRankTier.platinum,
    LolRankTier.emerald,
    LolRankTier.diamond,
  ];

  static const _divisionSkillAnchors = <int>[
    1, 3, 5, 7, // 黑铁 IV～I
    10, 13, 16, 19, // 青铜 IV～I
    25, 30, 35, 40, // 白银 IV～I
    45, 52, 59, 66, // 黄金 IV～I
    70, 78, 86, 94, // 铂金 IV～I
    100, 125, 150, 175, // 翡翠 IV～I
    200, 225, 250, 275, // 钻石 IV～I
    300, // 大师 0 分
  ];

  static double requiredSkillForPosition(LolRankPosition position) {
    if (position.isApex) {
      return requiredSkillForApexScore(position.apexScore);
    }

    final tierIndex = divisionTiers.indexOf(position.tier);
    final divisionIndex = position.division!.index;
    final anchorIndex = tierIndex * divisionsPerTier + divisionIndex;
    final current = _divisionSkillAnchors[anchorIndex];
    final next = _divisionSkillAnchors[anchorIndex + 1];
    return current + (next - current) * (position.lp / lpPerDivision);
  }

  static double requiredSkillForApexScore(int score) {
    final safeScore = max(0, score);
    if (safeScore <= grandmasterScore) {
      return 300 + safeScore * 0.5;
    }
    if (safeScore <= proScore) {
      return 900 + (safeScore - grandmasterScore) * 0.75;
    }
    return 1500.0 + (safeScore - proScore);
  }

  static LolRankTier tierForApexScore(int score) {
    if (score >= challengerScore) return LolRankTier.challenger;
    if (score >= grandmasterScore) return LolRankTier.grandmaster;
    return LolRankTier.master;
  }

  static double calculateWinChance({
    required int skill,
    required LolRankPosition position,
    required int pressure,
    required LolHealthCondition healthCondition,
    required bool injured,
    required int consecutiveWins,
    required int consecutiveLosses,
    required double randomModifier,
  }) {
    final requiredSkill = requiredSkillForPosition(position);
    final difference = skill - requiredSkill;
    final scale = max(10.0, requiredSkill * 0.25);
    final skillModifier = difference == 0
        ? 0.0
        : 30 * difference / (difference.abs() + scale);
    final lowRankOverqualificationBonus =
        position.tier.index <= LolRankTier.platinum.index &&
            difference > lowRankOverqualificationThreshold
        ? ((difference - lowRankOverqualificationThreshold) * 0.25).clamp(
            0.0,
            maxLowRankOverqualificationBonus,
          )
        : 0.0;
    final healthModifier = switch (healthCondition) {
      LolHealthCondition.veryHealthy => 5.0,
      LolHealthCondition.healthy => 0.0,
      LolHealthCondition.subHealthy => -5.0,
      LolHealthCondition.unhealthy => -10.0,
      LolHealthCondition.sick => -15.0,
    };
    final injuryModifier = injured ? -10.0 : 0.0;
    final streakModifier = -max(0, consecutiveWins) + max(0, consecutiveLosses);
    final pressureModifier = -pressure.clamp(0, 100) * 0.2;
    final boundedRandomModifier = randomModifier.clamp(-5.0, 5.0);

    return (50 +
            skillModifier +
            lowRankOverqualificationBonus +
            streakModifier +
            pressureModifier +
            healthModifier +
            injuryModifier +
            boundedRandomModifier)
        .clamp(minWinChance, maxWinChance);
  }

  static String winChanceLabel(double chance) {
    if (chance >= 75) return '手拿把掐';
    if (chance >= 60) return '略有优势';
    if (chance >= 40) return '势均力敌';
    if (chance >= 25) return '有些吃力';
    return '无法战胜';
  }

  static int lpDeltaForRoll({required bool won, required int roll}) {
    assert(roll >= 0 && roll <= 5);
    return won ? 20 + roll : -(15 + roll);
  }

  static bool isHighRank(LolRankTier historicalPeakTier) {
    return historicalPeakTier.index >= LolRankTier.master.index;
  }

  static int hourlyOrderRate({
    required LolOrderType type,
    required LolOrderRankBand rankBand,
  }) {
    if (type == LolOrderType.teaching) return 80;
    if (rankBand == LolOrderRankBand.low) return 70;
    if (type == LolOrderType.flex) return 120;
    return 100;
  }

  static bool canAcceptOrder({
    required LolRankTier historicalPeakTier,
    required int skill,
    required LolRankTier minimumPeakTier,
    required int minimumSkill,
  }) {
    return historicalPeakTier.index >= minimumPeakTier.index &&
        skill >= minimumSkill;
  }
}
