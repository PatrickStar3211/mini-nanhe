import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'abuse_story_screen.dart';
import 'app_version.dart';
import 'character_reaction.dart';
import 'collection_screen.dart';
import 'feeding_story_screen.dart';
import 'game_audio_controller.dart';
import 'game_assets.dart';
import 'opening_story_screen.dart';
import 'reaction_rules.dart';
import 'theme.dart';

const _initialMaxEnergy = 25;
const _minStatValue = 1;
const _maxStatValue = 999;
const _affectionGainPerInteraction = 3;
const _affectionGainPerQuietInteraction = 1;
const _affectionLossPerHit = 5;
const _trustLossPerHit = 10;
const _deathHitThreshold = 50;
const _minutesPerInteraction = 30;
const _sleepAvailableMinute = 22 * 60;
const _midnightMinute = 24 * 60;
const _earliestWakeMinute = 6 * 60;
const _sleepDurationMinutes = 8 * 60;
const _endurancePerMaxEnergy = 4;
const _feedUnlockMinute = 12 * 60;
const _daySevenSickMinute = 16 * 60;

enum YardHomeTier { box, doghouse, luxury }

enum WeatherCondition { sunny, rainy, snowy }

class MiniNanheDebugState {
  const MiniNanheDebugState({
    this.totalDaysTogether,
    this.minuteOfDay,
    this.affectionLevel,
    this.affectionProgress,
    this.trustLevel,
    this.trustProgress,
    this.energy,
    this.healthValue,
    this.exhaustionCount,
    this.injury,
    this.cleanliness,
    this.feedEventTriggered,
    this.feedEventCompleted,
    this.feedEventResolvedCorrectly,
    this.sicknessEventResolvedCorrectly,
    this.doghouseUnlocked,
    this.luxuryUnlocked,
  });

  final int? totalDaysTogether;
  final int? minuteOfDay;
  final int? affectionLevel;
  final int? affectionProgress;
  final int? trustLevel;
  final int? trustProgress;
  final int? energy;
  final int? healthValue;
  final int? exhaustionCount;
  final int? injury;
  final int? cleanliness;
  final bool? feedEventTriggered;
  final bool? feedEventCompleted;
  final bool? feedEventResolvedCorrectly;
  final bool? sicknessEventResolvedCorrectly;
  final bool? doghouseUnlocked;
  final bool? luxuryUnlocked;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.audioController,
    this.debugInitialState,
  });

  final GameAudioController audioController;
  final MiniNanheDebugState? debugInitialState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _random = Random();
  CharacterReaction? _reaction;
  bool _isReacting = false;
  int _selectedDestination = 0;

  int _totalDaysTogether = 1;
  int _year = 1;
  int _month = 1;
  int _day = 1;
  int _minuteOfDay = 6 * 60;
  int _energy = _initialMaxEnergy;
  int _affectionLevel = 1;
  int _affectionProgress = 0;
  int _trustLevel = 1;
  int _trustProgress = 0;
  int _pressure = 0;
  int _cleanliness = 100;
  int _healthValue = 80;
  int _injury = 0;
  int _exhaustionCount = 0;
  int _actionPage = 0;
  bool _sleepPending = false;
  YardHomeTier _yardHomeTier = YardHomeTier.box;
  bool _hasBeenHit = false;
  int _hitCount = 0;
  bool _bondLockedByPreEvolutionHit = false;
  bool _deathPending = false;
  bool _deathEndingReached = false;
  bool _sickEvolutionEndingReached = false;
  bool _feedEventTriggered = false;
  bool _feedEventCompleted = false;
  bool _firstHitEventTriggered = false;
  bool _daySevenSicknessTriggered = false;
  bool _doghouseUnlockPending = false;
  bool _doghouseUnlocked = false;
  bool _luxuryUnlockPending = false;
  bool _luxuryUnlocked = false;
  // TODO: Wire these to the future feeding and sickness story choices.
  // ignore: prefer_final_fields
  bool _feedEventResolvedCorrectly = false;
  // ignore: prefer_final_fields
  bool _sicknessEventResolvedCorrectly = false;
  final Set<String> _permanentMemoryIds = {'opening-memory'};
  final Set<String> _permanentAchievementIds = {'rainy-day'};
  final Set<String> _permanentDecorationIds = {'yard-box'};
  int _strength = 1;
  int _intelligence = 1;
  int _charm = 1;
  int _art = 1;
  int _skill = 1;
  int _endurance = 1;
  int _curiosity = 0;
  int _selfDiscipline = 0;
  int _rebellion = 0;
  int _dependence = 0;
  int _confidence = 0;
  int _gentleness = 0;
  double _musicVolume = 0.7;
  double _soundEffectVolume = 0.8;
  double _voiceVolume = 0.9;
  double _musicVolumeBeforeMute = 0.7;
  double _soundEffectVolumeBeforeMute = 0.8;
  double _voiceVolumeBeforeMute = 0.9;
  BgmTrack _selectedBgm = BgmTrack.cozyNanhe2;

  @override
  void initState() {
    super.initState();
    final debug = widget.debugInitialState;
    if (debug == null) return;
    _totalDaysTogether = debug.totalDaysTogether ?? _totalDaysTogether;
    _minuteOfDay = debug.minuteOfDay ?? _minuteOfDay;
    _affectionLevel = debug.affectionLevel ?? _affectionLevel;
    _affectionProgress = debug.affectionProgress ?? _affectionProgress;
    _trustLevel = debug.trustLevel ?? _trustLevel;
    _trustProgress = debug.trustProgress ?? _trustProgress;
    _energy = debug.energy ?? _energy;
    _healthValue = debug.healthValue ?? _healthValue;
    _exhaustionCount = debug.exhaustionCount ?? _exhaustionCount;
    _injury = debug.injury ?? _injury;
    _cleanliness = debug.cleanliness ?? _cleanliness;
    _feedEventTriggered = debug.feedEventTriggered ?? _feedEventTriggered;
    _feedEventCompleted = debug.feedEventCompleted ?? _feedEventCompleted;
    _feedEventResolvedCorrectly =
        debug.feedEventResolvedCorrectly ?? _feedEventResolvedCorrectly;
    if (_feedEventResolvedCorrectly) {
      _feedEventCompleted = true;
      _feedEventTriggered = true;
    }
    _sicknessEventResolvedCorrectly =
        debug.sicknessEventResolvedCorrectly ?? _sicknessEventResolvedCorrectly;
    _doghouseUnlocked = debug.doghouseUnlocked ?? _doghouseUnlocked;
    _luxuryUnlocked = debug.luxuryUnlocked ?? _luxuryUnlocked;
    if (_luxuryUnlocked) {
      _doghouseUnlocked = true;
      _yardHomeTier = YardHomeTier.luxury;
    } else if (_doghouseUnlocked) {
      _yardHomeTier = YardHomeTier.doghouse;
    }
    _applyTimedEvents();
  }

  bool get _isExhausted => _energy <= 0;
  bool get _isMidnight => _minuteOfDay >= _midnightMinute;
  bool get _isForcedSleep => _isExhausted || _isMidnight;
  bool get _canSleepByTime => _minuteOfDay >= _sleepAvailableMinute;
  bool get _isTired => _energy <= max(1, (_maxEnergy * 0.35).ceil());
  bool get _hasHighPressure => _pressure >= 70;
  bool get _hasLowTrust => _trustLevel == 1 && _trustProgress < 20;
  bool get _hasHighTrust => _trustLevel >= 2 || _trustProgress >= 70;
  bool get _hasHighAffection =>
      _affectionLevel >= 2 || _affectionProgress >= 50;
  bool get _hasLowAffection => _affectionLevel < 2;
  bool get _isDirty => _cleanliness <= 35;
  bool get _isSick => _cleanliness <= 20 || _healthValue < 30;
  bool get _isInjured => _injury >= 10;
  bool get _isFatigued => _isExhausted || _exhaustionCount >= 2;
  bool get _isLateNight => _minuteOfDay >= 20 * 60;
  bool get _hasUnlockedAllDailyActions => _affectionLevel >= 2;
  bool get _hasUnlockedFeed =>
      _hasUnlockedAllDailyActions ||
      _totalDaysTogether > 1 ||
      _minuteOfDay >= _feedUnlockMinute;
  bool get _hasUnlockedHit =>
      _hasUnlockedAllDailyActions || _totalDaysTogether >= 3;
  bool get _hasUnlockedTrainingPage => _doghouseUnlocked;
  bool get _canTriggerDoghouseUnlock =>
      !_doghouseUnlocked && _affectionLevel >= 5 && _trustLevel >= 2;
  bool get _canTriggerLuxuryUnlock =>
      !_luxuryUnlocked &&
      _affectionLevel >= 8 &&
      _trustLevel >= 4 &&
      !_hasBeenHit &&
      _feedEventResolvedCorrectly &&
      _sicknessEventResolvedCorrectly &&
      _totalDaysTogether > 25;
  bool get _canShowEvolutionButton =>
      _totalDaysTogether > 60 && (_luxuryUnlocked || _hasSickEvolutionRoute);
  bool get _isPreEvolutionPeriod => _totalDaysTogether <= 60;
  bool get _isBondLocked =>
      _bondLockedByPreEvolutionHit && _isPreEvolutionPeriod;
  bool get _hasSickEvolutionRoute =>
      _bondLockedByPreEvolutionHit ||
      (_feedEventCompleted && !_feedEventResolvedCorrectly);
  bool get _isEndingReached =>
      _deathEndingReached || _sickEvolutionEndingReached;
  bool get _isDaySevenRain =>
      _totalDaysTogether == 7 && _minuteOfDay >= _earliestWakeMinute;
  List<YardHomeTier> get _unlockedYardHomes => [
    YardHomeTier.box,
    if (_doghouseUnlocked) YardHomeTier.doghouse,
    if (_luxuryUnlocked) YardHomeTier.luxury,
  ];
  Set<String> get _unlockedDecorationIds => {
    ..._permanentDecorationIds,
    'yard-box',
    if (_doghouseUnlocked) 'yard-doghouse',
    if (_luxuryUnlocked) 'yard-luxury',
  };
  Set<String> get _unlockedMemoryIds => {
    ..._permanentMemoryIds,
    'opening-memory',
    if (_feedEventCompleted) 'first-feeding-memory',
    if (_firstHitEventTriggered) 'first-abuse-memory',
  };
  Set<String> get _unlockedAchievementIds => {
    ..._permanentAchievementIds,
    'rainy-day',
    if (_feedEventResolvedCorrectly) 'curry-favorite',
    if (_hitCount >= _deathHitThreshold || _deathPending || _deathEndingReached)
      'roadside-one',
  };
  int get _maxEnergy {
    final enduranceBonus =
        (_endurance - _minStatValue) ~/ _endurancePerMaxEnergy;
    return _clampStat(_initialMaxEnergy + enduranceBonus);
  }

  String get _timeLabel {
    final normalizedMinute = _minuteOfDay % _midnightMinute;
    final hour = normalizedMinute ~/ 60;
    final minute = normalizedMinute % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  String get _seasonAssetKey {
    if (_month >= 3 && _month <= 5) return 'spring';
    if (_month >= 6 && _month <= 8) return 'summer';
    if (_month >= 9 && _month <= 11) return 'autumn';
    return 'winter';
  }

  String get _timeOfDayAssetKey {
    final normalizedMinute = _minuteOfDay % _midnightMinute;
    return normalizedMinute >= _earliestWakeMinute && normalizedMinute < 18 * 60
        ? 'day'
        : 'night';
  }

  bool get _canShowSnowWeather =>
      _seasonAssetKey == 'winter' || _seasonAssetKey == 'spring';

  WeatherCondition get _visibleWeatherCondition {
    final weatherCondition = _isDaySevenRain
        ? WeatherCondition.rainy
        : WeatherCondition.sunny;
    if (weatherCondition == WeatherCondition.snowy && !_canShowSnowWeather) {
      return WeatherCondition.rainy;
    }
    return weatherCondition;
  }

  String get _weatherLabel {
    return switch (_visibleWeatherCondition) {
      WeatherCondition.sunny => '晴',
      WeatherCondition.rainy => '雨',
      WeatherCondition.snowy => '雪',
    };
  }

  String get _yardBackgroundAsset {
    return yardBackgroundAsset(
      home: _yardHomeTier.name,
      season: _seasonAssetKey,
      timeOfDay: _timeOfDayAssetKey,
    );
  }

  void _changeYardHome(int direction) {
    final unlockedHomes = _unlockedYardHomes;
    if (unlockedHomes.length < 2) return;
    final currentIndex = unlockedHomes.indexOf(_yardHomeTier);
    final nextIndex =
        (currentIndex + direction + unlockedHomes.length) %
        unlockedHomes.length;
    setState(() => _yardHomeTier = unlockedHomes[nextIndex]);
  }

  Future<void> _changeBgm(BgmTrack track) async {
    setState(() => _selectedBgm = track);
    await widget.audioController.changeBgm(track);
  }

  @override
  void dispose() {
    widget.audioController.dispose();
    super.dispose();
  }

  NanheEmotion get _currentEmotion {
    final emotion = _reaction?.emotion;
    if (emotion != null) return emotion;
    if (_isExhausted) return NanheEmotion.sleepy;
    if (_pressure >= 80) return NanheEmotion.frustrated;
    if (_isInjured || _isSick) return NanheEmotion.sad;
    if (_affectionLevel == 1 &&
        _affectionProgress == 0 &&
        _trustProgress == 0) {
      return NanheEmotion.calm;
    }
    return NanheEmotion.calm;
  }

  String get _season {
    if (_month >= 3 && _month <= 5) return '春';
    if (_month >= 6 && _month <= 8) return '夏';
    if (_month >= 9 && _month <= 11) return '秋';
    return '冬';
  }

  String get _emotionLabel {
    return switch (_currentEmotion) {
      NanheEmotion.happy => '☺ 开心',
      NanheEmotion.affectionate => '♥ 亲近',
      NanheEmotion.curious => '? 好奇',
      NanheEmotion.sad => '☂ 伤心',
      NanheEmotion.angry => '! 愤怒',
      NanheEmotion.frustrated => '… 沮丧',
      NanheEmotion.sleepy => '☾ 困了',
      NanheEmotion.calm => '☺ 平静',
    };
  }

  String get _healthLabel {
    return _healthLabels.join('、');
  }

  List<String> get _healthLabels {
    final labels = <String>[];
    if (_isInjured) labels.add('受伤');
    if (_isSick) labels.add('生病');
    if (_isFatigued) labels.add('疲劳');
    if (labels.isNotEmpty) return labels;

    if (_healthValue >= 90) return ['非常健康'];
    if (_healthValue >= 70) return ['健康'];
    if (_healthValue >= 50) return ['亚健康'];
    if (_healthValue >= 30) return ['不健康'];
    return ['生病'];
  }

  String get _personalityLabel {
    final tendencies = <String, int>{
      '好奇': _curiosity,
      '自律': _selfDiscipline,
      '叛逆': _rebellion,
      '依赖': _dependence,
      '自信': _confidence,
      '温柔': _gentleness,
    };
    final strongest = tendencies.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return strongest.value >= 15 ? strongest.key : '普通';
  }

  String get _traitLabel {
    if (_intelligence >= 20 && _curiosity >= 15 && _pressure < 80) {
      return '研究者';
    }
    if (_intelligence >= 20 && _selfDiscipline >= 15 && _healthValue >= 70) {
      return '优等生';
    }
    if (_skill >= 20 && _endurance >= 10) return '游戏高手';
    if (_skill >= 20 && _charm >= 15) return '人气玩家';
    if (_art >= 20 && _pressure < 70) return '小艺术家';
    return '无';
  }

  String get _characterAsset {
    if (_deathEndingReached) return miniNanheDeadAsset;
    if (_sickEvolutionEndingReached) return miniNanheSadAsset;
    return switch (_currentEmotion) {
      NanheEmotion.happy => miniNanheHappyAsset,
      NanheEmotion.affectionate => miniNanheAffectionateAsset,
      NanheEmotion.curious => miniNanheCuriousAsset,
      NanheEmotion.sleepy => miniNanheSleepyAsset,
      NanheEmotion.sad => miniNanheSadAsset,
      NanheEmotion.angry => miniNanheAngryAsset,
      NanheEmotion.frustrated => miniNanheFrustratedAsset,
      NanheEmotion.calm => miniNanheCalmAsset,
    };
  }

  int _clampStat(int value) => value.clamp(_minStatValue, _maxStatValue);

  int _clampPercent(int value) => value.clamp(0, 100);

  void _changeAffection(int amount) {
    if (_isBondLocked && amount > 0) return;
    _affectionProgress += amount;
    while (_affectionProgress >= 100) {
      _affectionLevel = _clampStat(_affectionLevel + 1);
      _affectionProgress -= 100;
    }
    while (_affectionProgress < 0 && _affectionLevel > 1) {
      _affectionLevel -= 1;
      _affectionProgress += 100;
    }
    if (_affectionLevel <= 1 && _affectionProgress < 0) {
      _affectionLevel = 1;
      _affectionProgress = 0;
    }
  }

  void _changeTrust(int amount) {
    if (_isBondLocked && amount > 0) return;
    _trustProgress += amount;
    while (_trustProgress >= 100) {
      _trustLevel = _clampStat(_trustLevel + 1);
      _trustProgress -= 100;
    }
    while (_trustProgress < 0 && _trustLevel > 1) {
      _trustLevel -= 1;
      _trustProgress += 100;
    }
    if (_trustLevel <= 1 && _trustProgress < 0) {
      _trustLevel = 1;
      _trustProgress = 0;
    }
  }

  CharacterReaction _pickReaction(List<CharacterReaction> responses) {
    final available = responses.length > 1
        ? responses.where((response) => response != _reaction).toList()
        : responses;
    return available[_random.nextInt(available.length)];
  }

  ReactionContext get _reactionContext {
    return ReactionContext(
      isTired: _isTired,
      hasHighPressure: _hasHighPressure,
      hasLowTrust: _hasLowTrust,
      hasHighTrust: _hasHighTrust,
      hasHighAffection: _hasHighAffection,
      hasLowAffection: _hasLowAffection,
      isDirty: _isDirty,
      isSick: _isSick,
      isInjured: _isInjured,
      isLateNight: _isLateNight,
    );
  }

  List<CharacterReaction> _contextualResponses(ReactionAction action) {
    return selectContextualReactions(action, _reactionContext);
  }

  void _applyAction(
    List<CharacterReaction> responses, {
    int energyDelta = -1,
    int affectionDelta = 0,
    int trustDelta = 0,
    int pressureDelta = 0,
    int cleanlinessDelta = 0,
    int healthDelta = 0,
    int injuryDelta = 0,
    int strengthDelta = 0,
    int intelligenceDelta = 0,
    int charmDelta = 0,
    int artDelta = 0,
    int skillDelta = 0,
    int enduranceDelta = 0,
    int curiosityDelta = 0,
    int selfDisciplineDelta = 0,
    int rebellionDelta = 0,
    int dependenceDelta = 0,
    int confidenceDelta = 0,
    int gentlenessDelta = 0,
    bool advancesTime = true,
    Duration voiceDelay = const Duration(milliseconds: 90),
  }) {
    if (_sleepPending) return;

    if (energyDelta < 0 && _isForcedSleep) {
      setState(() => _reaction = exhaustedReaction);
      widget.audioController.playVoice(exhaustedReaction.voice);
      return;
    }

    final reaction = _pickReaction(responses);

    setState(() {
      _changeAffection(affectionDelta);
      _changeTrust(trustDelta);
      _pressure = _clampPercent(_pressure + pressureDelta);
      _cleanliness = _clampPercent(_cleanliness + cleanlinessDelta);
      _healthValue = _clampPercent(_healthValue + healthDelta);
      _injury = _clampPercent(_injury + injuryDelta);
      _strength = _clampStat(_strength + strengthDelta);
      _intelligence = _clampStat(_intelligence + intelligenceDelta);
      _charm = _clampStat(_charm + charmDelta);
      _art = _clampStat(_art + artDelta);
      _skill = _clampStat(_skill + skillDelta);
      _endurance = _clampStat(_endurance + enduranceDelta);
      _energy = (_energy + energyDelta).clamp(0, _maxEnergy);
      _curiosity = _clampPercent(_curiosity + curiosityDelta);
      _selfDiscipline = _clampPercent(_selfDiscipline + selfDisciplineDelta);
      _rebellion = _clampPercent(_rebellion + rebellionDelta);
      _dependence = _clampPercent(_dependence + dependenceDelta);
      _confidence = _clampPercent(_confidence + confidenceDelta);
      _gentleness = _clampPercent(_gentleness + gentlenessDelta);
      if (advancesTime) _advanceMinutes(_minutesPerInteraction);
      _applyTimedEvents();
      _queueProgressionUnlocks();
      _reaction = reaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(reaction.voice, delay: voiceDelay);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _showReaction(
    List<CharacterReaction> responses, {
    bool consumesEnergy = true,
    int affectionGain = _affectionGainPerInteraction,
    bool advancesTime = true,
  }) {
    _applyAction(
      responses,
      energyDelta: consumesEnergy ? -1 : 0,
      affectionDelta: consumesEnergy ? affectionGain : 0,
      advancesTime: advancesTime,
    );
  }

  Future<void> _handleHitPressed() async {
    if (_sleepPending || _isEndingReached) return;

    if (!_firstHitEventTriggered && _isPreEvolutionPeriod) {
      final confirmed = await _confirmFirstHit();
      if (!confirmed || !mounted) return;
      setState(() {
        _firstHitEventTriggered = true;
        _permanentMemoryIds.add('first-abuse-memory');
        _reaction = null;
      });
      unawaited(_precacheStoryAssets(abuseStoryAssets));
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, animation, secondaryAnimation) {
            return AbuseStoryScreen(
              onFinished: (storyContext) => Navigator.of(storyContext).pop(),
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      if (!mounted) return;
    }

    widget.audioController.playHitInteraction();
    _showHitReaction();
  }

  Future<bool> _confirmFirstHit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('你确定要殴打迷你南河吗？'),
          content: const Text('你可能会失去迷你南河的好感和信任，影响后续的养成，并造成不可挽回的结局。'),
          actions: [
            TextButton(
              key: const Key('first-hit-cancel-button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('first-hit-confirm-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  void _showHitReaction() {
    if (_sleepPending || _isEndingReached) return;

    if (_isForcedSleep) {
      setState(() => _reaction = exhaustedReaction);
      widget.audioController.playVoice(exhaustedReaction.voice);
      return;
    }

    final reactions = _hasHighAffection && _hasHighTrust
        ? trustedHitReactions
        : _hasHighAffection && _hasLowTrust
        ? sadHitReactions
        : _hasHighTrust
        ? confusedHitReactions
        : _hasLowTrust
        ? lowBondHitReactions
        : hitReactions;
    _hasBeenHit = true;
    if (!_firstHitEventTriggered) {
      _firstHitEventTriggered = true;
    }
    _applyAction(
      reactions,
      energyDelta: -1,
      affectionDelta: -_affectionLossPerHit,
      trustDelta: -_trustLossPerHit,
      pressureDelta: 10,
      healthDelta: -2,
      injuryDelta: 5,
      rebellionDelta: 3,
      voiceDelay: const Duration(milliseconds: 180),
    );
    setState(() {
      _hitCount += 1;
      if (_bondLockedByPreEvolutionHit || _isPreEvolutionPeriod) {
        _bondLockedByPreEvolutionHit = true;
        _affectionLevel = 1;
        _affectionProgress = 0;
        _trustLevel = 1;
        _trustProgress = 0;
      }
      if (_hitCount >= _deathHitThreshold || _energy <= 0) {
        _deathPending = true;
        _permanentAchievementIds.add('roadside-one');
      }
    });
  }

  void _handleEvolution() {
    if (_hasSickEvolutionRoute) {
      setState(() {
        _sickEvolutionEndingReached = true;
        _reaction = const CharacterReaction(
          emotion: NanheEmotion.sad,
          nanheSpeech: 'å—æ²³â€¦â€¦',
          meaning: 'è¿·ä½ å—æ²³çš„èº«ä½“æ²¡æœ‰èƒ½æ”¯æ’‘ä½è¿™æ¬¡è¿›åŒ–ã€‚',
          voice: NanheVoice.sadDouble,
        );
        _isReacting = false;
      });
      widget.audioController.playVoice(NanheVoice.sadDouble);
    }
  }

  void _advanceOneDay() {
    _day += 1;
    if (_day > 30) {
      _day = 1;
      _month += 1;
    }
    if (_month > 12) {
      _month = 1;
      _year += 1;
    }
  }

  void _advanceMinutes(int minutes) {
    _minuteOfDay = (_minuteOfDay + minutes).clamp(0, _midnightMinute);
  }

  void _queueProgressionUnlocks() {
    if (_canTriggerDoghouseUnlock) {
      _doghouseUnlockPending = true;
    }
    if (_canTriggerLuxuryUnlock) {
      _luxuryUnlockPending = true;
    }
  }

  void _applyTimedEvents() {
    if (!_daySevenSicknessTriggered &&
        _totalDaysTogether == 7 &&
        _minuteOfDay >= _daySevenSickMinute) {
      _daySevenSicknessTriggered = true;
      _healthValue = min(_healthValue, 25);
      _pressure = _clampPercent(_pressure + 12);
      // TODO: Insert the day-7 sickness story event here.
    }
  }

  void _applyNextDayUnlocks() {
    if (_deathPending) {
      _deathPending = false;
      _deathEndingReached = true;
      _permanentAchievementIds.add('roadside-one');
    }
    if (_doghouseUnlockPending) {
      _doghouseUnlockPending = false;
      _doghouseUnlocked = true;
      _yardHomeTier = YardHomeTier.doghouse;
      _permanentDecorationIds.add('yard-doghouse');
      // TODO: Insert the normal doghouse and training-page unlock event here.
    }
    if (_luxuryUnlockPending) {
      _luxuryUnlockPending = false;
      _luxuryUnlocked = true;
      _yardHomeTier = YardHomeTier.luxury;
      _permanentDecorationIds.add('yard-luxury');
      // TODO: Insert the luxury doghouse unlock event here.
    }
    if (!_unlockedYardHomes.contains(_yardHomeTier)) {
      _yardHomeTier = _unlockedYardHomes.last;
    }
  }

  void _requestSleep() {
    if (_sleepPending) return;

    if (!_isForcedSleep && !_canSleepByTime) {
      setState(() => _reaction = tooEarlyToSleepReaction);
      return;
    }

    final reaction = sleepReactions[_random.nextInt(sleepReactions.length)];
    setState(() {
      _reaction = reaction;
      _sleepPending = true;
      _isReacting = true;
    });
    widget.audioController.playVoice(reaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _completeSleepUntilTomorrow() {
    final wakeMinute = max(
      _earliestWakeMinute,
      _minuteOfDay + _sleepDurationMinutes - _midnightMinute,
    );
    setState(() {
      final sleptFromExhaustion = _isExhausted;
      _advanceOneDay();
      _totalDaysTogether += 1;
      _applyNextDayUnlocks();
      _minuteOfDay = wakeMinute;
      _energy = _maxEnergy;
      _pressure = _clampPercent(_pressure - 4);
      _healthValue = _clampPercent(_healthValue + 3);
      _injury = _clampPercent(_injury - 2);
      _exhaustionCount = sleptFromExhaustion
          ? _clampPercent(_exhaustionCount + 1)
          : _clampPercent(_exhaustionCount - 1);
      _reaction = wakeUpReaction;
      _sleepPending = false;
      _isReacting = false;
      _applyTimedEvents();
      _queueProgressionUnlocks();
      if (_deathEndingReached) {
        _reaction = null;
        _isReacting = false;
      }
    });
    if (!_deathEndingReached) {
      widget.audioController.playVoice(wakeUpReaction.voice);
    }
  }

  void _observe() {
    _applyAction(
      _contextualResponses(ReactionAction.observe),
      energyDelta: -1,
      affectionDelta: _affectionGainPerQuietInteraction,
      curiosityDelta: 2,
    );
  }

  void _chat() {
    if (_sleepPending) return;

    if (_isForcedSleep) {
      _showReaction(const [exhaustedReaction], consumesEnergy: false);
      return;
    }

    _applyAction(
      _contextualResponses(ReactionAction.chat),
      energyDelta: -1,
      affectionDelta: _affectionGainPerQuietInteraction,
      trustDelta: 1,
      pressureDelta: -1,
      curiosityDelta: 1,
      gentlenessDelta: 1,
    );
  }

  void _pet() {
    _applyAction(
      _contextualResponses(ReactionAction.pet),
      energyDelta: -1,
      affectionDelta: _affectionGainPerInteraction,
      trustDelta: 1,
      pressureDelta: -2,
      dependenceDelta: 1,
      gentlenessDelta: 1,
    );
  }

  void _play() {
    _applyAction(
      _contextualResponses(ReactionAction.play),
      energyDelta: -2,
      affectionDelta: 2,
      trustDelta: 1,
      pressureDelta: -4,
      skillDelta: 1,
      confidenceDelta: 1,
    );
  }

  void _walk() {
    _applyAction(
      _contextualResponses(ReactionAction.walk),
      energyDelta: -2,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: -5,
      healthDelta: 1,
      enduranceDelta: 1,
      curiosityDelta: 1,
    );
  }

  void _feed() {
    if (!_feedEventTriggered) {
      setState(() {
        _feedEventTriggered = true;
        _reaction = null;
      });
      unawaited(_precacheStoryAssets(feedingStoryAssets));
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, animation, secondaryAnimation) {
            return FeedingStoryScreen(
              onFinished: (storyContext, choice) {
                Navigator.of(storyContext).pop();
                _resolveFirstFeedingEvent(choice);
              },
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }
    _applyAction(
      _contextualResponses(ReactionAction.feed),
      energyDelta: -1,
      affectionDelta: 2,
      trustDelta: 1,
      pressureDelta: -1,
      healthDelta: 1,
      gentlenessDelta: 1,
    );
  }

  void _resolveFirstFeedingEvent(FeedingStoryChoice choice) {
    final isCorrectChoice = choice == FeedingStoryChoice.curry;
    final reaction = isCorrectChoice
        ? const CharacterReaction(
            emotion: NanheEmotion.curious,
            nanheSpeech: '南河……南河。',
            meaning: '从来没吃过这么好吃的！',
            voice: NanheVoice.curiousDouble,
          )
        : const CharacterReaction(
            emotion: NanheEmotion.calm,
            nanheSpeech: '南河……',
            meaning: '肚子饿。先吃一点。',
            voice: NanheVoice.calmSingle,
          );

    setState(() {
      _feedEventCompleted = true;
      _feedEventResolvedCorrectly = isCorrectChoice;
      _permanentMemoryIds.add('first-feeding-memory');
      if (isCorrectChoice) {
        _permanentAchievementIds.add('curry-favorite');
      }
      _changeAffection(isCorrectChoice ? 2 : 1);
      _changeTrust(isCorrectChoice ? 2 : 0);
      _pressure = _clampPercent(_pressure + (isCorrectChoice ? -2 : 2));
      _healthValue = _clampPercent(_healthValue + (isCorrectChoice ? 2 : 0));
      _gentleness = _clampPercent(_gentleness + 1);
      _energy = (_energy - 1).clamp(0, _maxEnergy);
      _advanceMinutes(_minutesPerInteraction);
      _applyTimedEvents();
      _queueProgressionUnlocks();
      _reaction = reaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(reaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _rest() {
    if (_sleepPending) return;

    if (_isForcedSleep) {
      _showReaction(const [exhaustedReaction], consumesEnergy: false);
      return;
    }

    _applyAction(
      _contextualResponses(ReactionAction.rest),
      energyDelta: 5,
      pressureDelta: -3,
      healthDelta: 1,
      selfDisciplineDelta: 1,
    );
  }

  void _study() {
    _applyAction(
      _contextualResponses(ReactionAction.study),
      energyDelta: -3,
      pressureDelta: 4,
      intelligenceDelta: 2,
      curiosityDelta: 1,
      selfDisciplineDelta: 1,
    );
  }

  void _exercise() {
    _applyAction(
      _contextualResponses(ReactionAction.exercise),
      energyDelta: -4,
      pressureDelta: -5,
      cleanlinessDelta: -5,
      healthDelta: 2,
      strengthDelta: 2,
      enduranceDelta: 2,
      selfDisciplineDelta: 1,
      confidenceDelta: 1,
    );
  }

  void _game() {
    _applyAction(
      _contextualResponses(ReactionAction.game),
      energyDelta: -3,
      pressureDelta: -6,
      cleanlinessDelta: -3,
      intelligenceDelta: 1,
      skillDelta: 2,
      confidenceDelta: 1,
    );
  }

  void _create() {
    _applyAction(
      _contextualResponses(ReactionAction.create),
      energyDelta: -2,
      pressureDelta: -2,
      charmDelta: 1,
      artDelta: 2,
      curiosityDelta: 1,
    );
  }

  void _perform() {
    _applyAction(
      _contextualResponses(ReactionAction.perform),
      energyDelta: -3,
      pressureDelta: 2,
      charmDelta: 2,
      artDelta: 1,
      confidenceDelta: 2,
    );
  }

  void _bath() {
    _applyAction(
      _contextualResponses(ReactionAction.bath),
      energyDelta: -1,
      pressureDelta: -1,
      cleanlinessDelta: 35,
      healthDelta: 2,
    );
  }

  void _outing() {
    _applyAction(
      _contextualResponses(ReactionAction.outing),
      energyDelta: -3,
      pressureDelta: -4,
      charmDelta: 1,
      curiosityDelta: 2,
      confidenceDelta: 1,
    );
  }

  void _readDialogue() {
    if (_reaction == null) return;
    if (_sleepPending) {
      _completeSleepUntilTomorrow();
      return;
    }
    setState(() {
      _reaction = null;
    });
  }

  void _setActionPage(int page) {
    setState(() {
      _actionPage = _hasUnlockedTrainingPage ? page.clamp(0, 1) : 0;
    });
  }

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
  }

  void _replayOpeningStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(openingStoryPageAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return OpeningStoryScreen(
            onFinished: (storyContext) => Navigator.of(storyContext).pop(),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _replayFeedingStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(feedingStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return FeedingStoryScreen(
            onFinished: (storyContext, choice) =>
                Navigator.of(storyContext).pop(),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _replayAbuseStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(abuseStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return AbuseStoryScreen(
            onFinished: (storyContext) => Navigator.of(storyContext).pop(),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _precacheStoryAssets(List<String> assets) async {
    for (final asset in assets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (_) {}
    }
  }

  void _setMusicVolume(double value) {
    setState(() {
      _musicVolume = value;
      if (value > 0) _musicVolumeBeforeMute = value;
    });
    widget.audioController.setMusicVolume(value);
  }

  void _setSoundEffectVolume(double value) {
    setState(() {
      _soundEffectVolume = value;
      if (value > 0) _soundEffectVolumeBeforeMute = value;
    });
    widget.audioController.setSoundEffectVolume(value);
  }

  void _setVoiceVolume(double value) {
    setState(() {
      _voiceVolume = value;
      if (value > 0) _voiceVolumeBeforeMute = value;
    });
    widget.audioController.setVoiceVolume(value);
  }

  void _setDebugTimeline({
    required int totalDaysTogether,
    required int minute,
  }) {
    setState(() {
      _setCalendarFromTotalDays(totalDaysTogether);
      _minuteOfDay = minute.clamp(0, _midnightMinute);
      _applyTimedEvents();
      _queueProgressionUnlocks();
    });
  }

  void _setDebugAffectionLevel(int value) {
    setState(() {
      _affectionLevel = _clampStat(value);
      _affectionProgress = _affectionProgress.clamp(0, 99);
      _queueProgressionUnlocks();
    });
  }

  void _setDebugAffectionProgress(int value) {
    setState(() {
      _affectionProgress = value.clamp(0, 99);
      _queueProgressionUnlocks();
    });
  }

  void _setDebugTrustLevel(int value) {
    setState(() {
      _trustLevel = _clampStat(value);
      _trustProgress = _trustProgress.clamp(0, 99);
      _queueProgressionUnlocks();
    });
  }

  void _setDebugTrustProgress(int value) {
    setState(() {
      _trustProgress = value.clamp(0, 99);
      _queueProgressionUnlocks();
    });
  }

  void _setCalendarFromTotalDays(int totalDaysTogether) {
    final clampedDays = totalDaysTogether.clamp(1, _maxStatValue);
    final zeroBasedDay = clampedDays - 1;
    _totalDaysTogether = clampedDays;
    _year = (zeroBasedDay ~/ 360) + 1;
    _month = ((zeroBasedDay % 360) ~/ 30) + 1;
    _day = (zeroBasedDay % 30) + 1;
  }

  void _toggleMusicMute() {
    setState(() {
      if (_musicVolume > 0) {
        _musicVolumeBeforeMute = _musicVolume;
        _musicVolume = 0;
      } else {
        _musicVolume = _musicVolumeBeforeMute;
      }
    });
    widget.audioController.setMusicVolume(_musicVolume);
  }

  void _toggleSoundEffectMute() {
    setState(() {
      if (_soundEffectVolume > 0) {
        _soundEffectVolumeBeforeMute = _soundEffectVolume;
        _soundEffectVolume = 0;
      } else {
        _soundEffectVolume = _soundEffectVolumeBeforeMute;
      }
    });
    widget.audioController.setSoundEffectVolume(_soundEffectVolume);
  }

  void _toggleVoiceMute() {
    setState(() {
      if (_voiceVolume > 0) {
        _voiceVolumeBeforeMute = _voiceVolume;
        _voiceVolume = 0;
      } else {
        _voiceVolume = _voiceVolumeBeforeMute;
      }
    });
    widget.audioController.setVoiceVolume(_voiceVolume);
  }

  Future<void> _resetRunAndReplayOpening() async {
    setState(() {
      _selectedDestination = 0;
      _totalDaysTogether = 1;
      _year = 1;
      _month = 1;
      _day = 1;
      _minuteOfDay = 6 * 60;
      _energy = _initialMaxEnergy;
      _affectionLevel = 1;
      _affectionProgress = 0;
      _trustLevel = 1;
      _trustProgress = 0;
      _pressure = 0;
      _cleanliness = 100;
      _healthValue = 80;
      _injury = 0;
      _exhaustionCount = 0;
      _actionPage = 0;
      _sleepPending = false;
      _yardHomeTier = YardHomeTier.box;
      _hasBeenHit = false;
      _hitCount = 0;
      _bondLockedByPreEvolutionHit = false;
      _deathPending = false;
      _deathEndingReached = false;
      _sickEvolutionEndingReached = false;
      _feedEventTriggered = false;
      _feedEventCompleted = false;
      _firstHitEventTriggered = false;
      _daySevenSicknessTriggered = false;
      _doghouseUnlockPending = false;
      _doghouseUnlocked = false;
      _luxuryUnlockPending = false;
      _luxuryUnlocked = false;
      _feedEventResolvedCorrectly = false;
      _sicknessEventResolvedCorrectly = false;
      _strength = 1;
      _intelligence = 1;
      _charm = 1;
      _art = 1;
      _skill = 1;
      _endurance = 1;
      _curiosity = 0;
      _selfDiscipline = 0;
      _rebellion = 0;
      _dependence = 0;
      _confidence = 0;
      _gentleness = 0;
      _reaction = null;
      _isReacting = false;
    });

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return OpeningStoryScreen(
            onFinished: (storyContext) => Navigator.of(storyContext).pop(),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selectedDestination) {
      1 => _StatusPage(
        affectionLevel: _affectionLevel,
        affectionProgress: _affectionProgress,
        trustLevel: _trustLevel,
        trustProgress: _trustProgress,
        energy: _energy,
        maxEnergy: _maxEnergy,
        emotionLabel: _emotionLabel,
        pressure: _pressure,
        cleanliness: _cleanliness,
        healthLabel: _healthLabel,
        personalityLabel: _personalityLabel,
        traitLabel: _traitLabel,
        characterAsset: _characterAsset,
        strength: _strength,
        intelligence: _intelligence,
        charm: _charm,
        art: _art,
        skill: _skill,
        endurance: _endurance,
      ),
      2 => const _PlaceholderPage(
        title: '手机',
        icon: Icons.smartphone_rounded,
        pageKey: Key('phone-page'),
      ),
      3 => const _PlaceholderPage(
        title: '战斗',
        icon: Icons.sports_martial_arts_rounded,
        pageKey: Key('battle-page'),
      ),
      4 => CollectionScreen(
        unlockedMemoryIds: _unlockedMemoryIds,
        unlockedAchievementIds: _unlockedAchievementIds,
        unlockedDecorationIds: _unlockedDecorationIds,
        onReplayOpeningStory: _replayOpeningStory,
        onReplayFeedingStory: _replayFeedingStory,
        onReplayAbuseStory: _replayAbuseStory,
        onPageTurn: widget.audioController.playPageTurn,
      ),
      5 => _SettingsPage(
        selectedBgm: _selectedBgm,
        musicVolume: _musicVolume,
        soundEffectVolume: _soundEffectVolume,
        voiceVolume: _voiceVolume,
        totalDaysTogether: _totalDaysTogether,
        minuteOfDay: _minuteOfDay,
        affectionLevel: _affectionLevel,
        affectionProgress: _affectionProgress,
        trustLevel: _trustLevel,
        trustProgress: _trustProgress,
        onMusicChanged: _setMusicVolume,
        onSoundEffectChanged: _setSoundEffectVolume,
        onVoiceChanged: _setVoiceVolume,
        onMusicMuteToggle: _toggleMusicMute,
        onSoundEffectMuteToggle: _toggleSoundEffectMute,
        onVoiceMuteToggle: _toggleVoiceMute,
        onBgmChanged: _changeBgm,
        onDebugTimelineChanged: _setDebugTimeline,
        onDebugAffectionLevelChanged: _setDebugAffectionLevel,
        onDebugAffectionProgressChanged: _setDebugAffectionProgress,
        onDebugTrustLevelChanged: _setDebugTrustLevel,
        onDebugTrustProgressChanged: _setDebugTrustProgress,
      ),
      _ => _CompanionPage(
        totalDaysTogether: _totalDaysTogether,
        season: _season,
        year: _year,
        month: _month,
        day: _day,
        timeLabel: _timeLabel,
        weatherLabel: _weatherLabel,
        weatherCondition: _visibleWeatherCondition,
        backgroundAsset: _yardBackgroundAsset,
        canSwitchBackground: _unlockedYardHomes.length > 1,
        reaction: _reaction,
        isReacting: _isReacting,
        emotionLabel: _emotionLabel,
        characterAsset: _characterAsset,
        isEndingReached: _isEndingReached,
        isForcedSleep: _isForcedSleep,
        isSleepPending: _sleepPending,
        canSleep: _canSleepByTime,
        hasUnlockedAllDailyActions: _hasUnlockedAllDailyActions,
        hasUnlockedFeed: _hasUnlockedFeed,
        hasUnlockedHit: _hasUnlockedHit,
        hasUnlockedTrainingPage: _hasUnlockedTrainingPage,
        canShowEvolutionButton: _canShowEvolutionButton,
        actionPage: _actionPage,
        affectionLevel: _affectionLevel,
        affectionProgress: _affectionProgress,
        trustLevel: _trustLevel,
        trustProgress: _trustProgress,
        energy: _energy,
        maxEnergy: _maxEnergy,
        pressure: _pressure,
        cleanliness: _cleanliness,
        onReadDialogue: _readDialogue,
        onResetGame: _resetRunAndReplayOpening,
        onEvolution: _handleEvolution,
        onPreviousBackground: () => _changeYardHome(-1),
        onNextBackground: () => _changeYardHome(1),
        onPageChanged: _setActionPage,
        onCharacterTap: () {
          widget.audioController.playRegularInteraction();
          _pet();
        },
        onChat: () {
          widget.audioController.playRegularInteraction();
          _chat();
        },
        onPet: () {
          widget.audioController.playRegularInteraction();
          _pet();
        },
        onPlay: () {
          widget.audioController.playRegularInteraction();
          _play();
        },
        onObserve: () {
          widget.audioController.playRegularInteraction();
          _observe();
        },
        onWalk: () {
          widget.audioController.playRegularInteraction();
          _walk();
        },
        onFeed: () {
          widget.audioController.playRegularInteraction();
          _feed();
        },
        onRest: () {
          widget.audioController.playRegularInteraction();
          _rest();
        },
        onStudy: () {
          widget.audioController.playRegularInteraction();
          _study();
        },
        onExercise: () {
          widget.audioController.playRegularInteraction();
          _exercise();
        },
        onGame: () {
          widget.audioController.playRegularInteraction();
          _game();
        },
        onCreate: () {
          widget.audioController.playRegularInteraction();
          _create();
        },
        onPerform: () {
          widget.audioController.playRegularInteraction();
          _perform();
        },
        onBath: () {
          widget.audioController.playRegularInteraction();
          _bath();
        },
        onOuting: () {
          widget.audioController.playRegularInteraction();
          _outing();
        },
        onHit: () {
          _handleHitPressed();
        },
        onSleep: () {
          widget.audioController.playRegularInteraction();
          _requestSleep();
        },
      ),
    };

    return Scaffold(
      body: SafeArea(child: page),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '陪伴',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart_rounded),
            label: '状态',
          ),
          NavigationDestination(
            icon: Icon(Icons.smartphone_outlined),
            selectedIcon: Icon(Icons.smartphone_rounded),
            label: '手机',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_martial_arts_outlined),
            selectedIcon: Icon(Icons.sports_martial_arts_rounded),
            label: '战斗',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark_rounded),
            label: '收藏',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '设置'),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.pageKey,
  });

  final String title;
  final IconData icon;
  final Key pageKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: pageKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: azure),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _CompanionPage extends StatelessWidget {
  const _CompanionPage({
    required this.totalDaysTogether,
    required this.season,
    required this.year,
    required this.month,
    required this.day,
    required this.timeLabel,
    required this.weatherLabel,
    required this.weatherCondition,
    required this.backgroundAsset,
    required this.canSwitchBackground,
    required this.reaction,
    required this.isReacting,
    required this.emotionLabel,
    required this.characterAsset,
    required this.isEndingReached,
    required this.isForcedSleep,
    required this.isSleepPending,
    required this.canSleep,
    required this.hasUnlockedAllDailyActions,
    required this.hasUnlockedFeed,
    required this.hasUnlockedHit,
    required this.hasUnlockedTrainingPage,
    required this.canShowEvolutionButton,
    required this.actionPage,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.energy,
    required this.maxEnergy,
    required this.pressure,
    required this.cleanliness,
    required this.onReadDialogue,
    required this.onResetGame,
    required this.onEvolution,
    required this.onPreviousBackground,
    required this.onNextBackground,
    required this.onPageChanged,
    required this.onCharacterTap,
    required this.onChat,
    required this.onPet,
    required this.onPlay,
    required this.onObserve,
    required this.onWalk,
    required this.onFeed,
    required this.onRest,
    required this.onStudy,
    required this.onExercise,
    required this.onGame,
    required this.onCreate,
    required this.onPerform,
    required this.onBath,
    required this.onOuting,
    required this.onHit,
    required this.onSleep,
  });

  final int totalDaysTogether;
  final String season;
  final int year;
  final int month;
  final int day;
  final String timeLabel;
  final String weatherLabel;
  final WeatherCondition weatherCondition;
  final String backgroundAsset;
  final bool canSwitchBackground;
  final CharacterReaction? reaction;
  final bool isReacting;
  final String emotionLabel;
  final String characterAsset;
  final bool isEndingReached;
  final bool isForcedSleep;
  final bool isSleepPending;
  final bool canSleep;
  final bool hasUnlockedAllDailyActions;
  final bool hasUnlockedFeed;
  final bool hasUnlockedHit;
  final bool hasUnlockedTrainingPage;
  final bool canShowEvolutionButton;
  final int actionPage;
  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final int energy;
  final int maxEnergy;
  final int pressure;
  final int cleanliness;
  final VoidCallback onReadDialogue;
  final VoidCallback onResetGame;
  final VoidCallback onEvolution;
  final VoidCallback onPreviousBackground;
  final VoidCallback onNextBackground;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onCharacterTap;
  final VoidCallback onChat;
  final VoidCallback onPet;
  final VoidCallback onPlay;
  final VoidCallback onObserve;
  final VoidCallback onWalk;
  final VoidCallback onFeed;
  final VoidCallback onRest;
  final VoidCallback onStudy;
  final VoidCallback onExercise;
  final VoidCallback onGame;
  final VoidCallback onCreate;
  final VoidCallback onPerform;
  final VoidCallback onBath;
  final VoidCallback onOuting;
  final VoidCallback onHit;
  final VoidCallback onSleep;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 752),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 16.0;
            const fixedContentHeight = 254.0;
            final contentWidth = constraints.maxWidth - (horizontalPadding * 2);
            final availableStageHeight =
                constraints.maxHeight - fixedContentHeight;
            final protectedStageHeight = (contentWidth * 1.05).clamp(
              380.0,
              520.0,
            );
            final needsScrolling = availableStageHeight < protectedStageHeight;

            final stage = _CharacterStage(
              backgroundAsset: backgroundAsset,
              canSwitchBackground: canSwitchBackground,
              canShowEvolutionButton: canShowEvolutionButton,
              weatherCondition: weatherCondition,
              reaction: reaction,
              isReacting: isReacting,
              emotionLabel: emotionLabel,
              characterAsset: characterAsset,
              affectionLevel: affectionLevel,
              affectionProgress: affectionProgress,
              trustLevel: trustLevel,
              trustProgress: trustProgress,
              energy: energy,
              maxEnergy: maxEnergy,
              pressure: pressure,
              cleanliness: cleanliness,
              onTap: isEndingReached ? null : onCharacterTap,
              onReadDialogue: onReadDialogue,
              onPreviousBackground: onPreviousBackground,
              onNextBackground: onNextBackground,
              onEvolution: onEvolution,
            );
            final actions = _ActionPanel(
              isEndingReached: isEndingReached,
              isForcedSleep: isForcedSleep,
              isSleepPending: isSleepPending,
              canSleep: canSleep,
              hasUnlockedAllDailyActions: hasUnlockedAllDailyActions,
              hasUnlockedFeed: hasUnlockedFeed,
              hasUnlockedHit: hasUnlockedHit,
              hasUnlockedTrainingPage: hasUnlockedTrainingPage,
              actionPage: actionPage,
              onPageChanged: onPageChanged,
              onChat: onChat,
              onPet: onPet,
              onPlay: onPlay,
              onObserve: onObserve,
              onWalk: onWalk,
              onFeed: onFeed,
              onRest: onRest,
              onStudy: onStudy,
              onExercise: onExercise,
              onGame: onGame,
              onCreate: onCreate,
              onPerform: onPerform,
              onBath: onBath,
              onOuting: onOuting,
              onHit: onHit,
              onSleep: onSleep,
              onResetGame: onResetGame,
            );

            if (needsScrolling) {
              return SingleChildScrollView(
                key: const Key('companion-scroll-view'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  children: [
                    _Header(totalDaysTogether: totalDaysTogether),
                    const SizedBox(height: 8),
                    _CalendarCard(
                      season: season,
                      year: year,
                      month: month,
                      day: day,
                      timeLabel: timeLabel,
                      weatherLabel: weatherLabel,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: protectedStageHeight, child: stage),
                    const SizedBox(height: 12),
                    actions,
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                children: [
                  _Header(totalDaysTogether: totalDaysTogether),
                  const SizedBox(height: 8),
                  _CalendarCard(
                    season: season,
                    year: year,
                    month: month,
                    day: day,
                    timeLabel: timeLabel,
                    weatherLabel: weatherLabel,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: stage),
                  const SizedBox(height: 12),
                  actions,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalDaysTogether});

  final int totalDaysTogether;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('迷你南河', style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  '迷你期 · 第 $totalDaysTogether 天',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.season,
    required this.year,
    required this.month,
    required this.day,
    required this.timeLabel,
    required this.weatherLabel,
  });

  final String season;
  final int year;
  final int month;
  final int day;
  final String timeLabel;
  final String weatherLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: blueMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_florist_outlined, color: deepBlue, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$season | 第$year年 · $month月$day日 | $timeLabel | $weatherLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.calendar_today_outlined, color: mutedInk, size: 16),
        ],
      ),
    );
  }
}

class _CharacterStage extends StatelessWidget {
  const _CharacterStage({
    required this.backgroundAsset,
    required this.canSwitchBackground,
    required this.canShowEvolutionButton,
    required this.weatherCondition,
    required this.reaction,
    required this.isReacting,
    required this.emotionLabel,
    required this.characterAsset,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.energy,
    required this.maxEnergy,
    required this.pressure,
    required this.cleanliness,
    required this.onTap,
    required this.onReadDialogue,
    required this.onPreviousBackground,
    required this.onNextBackground,
    required this.onEvolution,
  });

  final String backgroundAsset;
  final bool canSwitchBackground;
  final bool canShowEvolutionButton;
  final WeatherCondition weatherCondition;
  final CharacterReaction? reaction;
  final bool isReacting;
  final String emotionLabel;
  final String characterAsset;
  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final int energy;
  final int maxEnergy;
  final int pressure;
  final int cleanliness;
  final VoidCallback? onTap;
  final VoidCallback onReadDialogue;
  final VoidCallback onPreviousBackground;
  final VoidCallback onNextBackground;
  final VoidCallback onEvolution;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: frost,
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6D5B8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A9B7B4B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (weatherCondition != WeatherCondition.sunny)
            Positioned.fill(
              child: IgnorePointer(
                child: _WeatherOverlay(condition: weatherCondition),
              ),
            ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxCharacterWidth = constraints.maxWidth * 0.5;
                final maxCharacterHeight = constraints.maxHeight * 0.48;

                return Align(
                  alignment: const Alignment(0, 0.2),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 86),
                    child: Semantics(
                      button: true,
                      label: '迷你南河，点击互动',
                      child: InkWell(
                        key: const Key('character-tap-area'),
                        borderRadius: BorderRadius.circular(24),
                        onTap: onTap,
                        child: AnimatedScale(
                          scale: isReacting ? 1.035 : 1,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutBack,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxCharacterWidth,
                              maxHeight: maxCharacterHeight,
                            ),
                            child: Image.asset(
                              characterAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _CompactStatusPanel(
              affectionLevel: affectionLevel,
              affectionProgress: affectionProgress,
              trustLevel: trustLevel,
              trustProgress: trustProgress,
              energy: energy,
              maxEnergy: maxEnergy,
              pressure: pressure,
              cleanliness: cleanliness,
            ),
          ),
          Positioned(top: 12, right: 14, child: _MoodChip(label: emotionLabel)),
          if (canShowEvolutionButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: 104,
              child: Center(
                child: FilledButton.tonalIcon(
                  key: const Key('evolution-button'),
                  onPressed: onEvolution,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('进化'),
                ),
              ),
            ),
          if (canSwitchBackground)
            Positioned.fill(
              child: _BackgroundSwitchControls(
                onPrevious: onPreviousBackground,
                onNext: onNextBackground,
              ),
            ),
          if (reaction != null)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _ReactionBubble(
                reaction: reaction!,
                onTap: onReadDialogue,
              ),
            ),
        ],
      ),
    );
  }
}

class _BackgroundSwitchControls extends StatelessWidget {
  const _BackgroundSwitchControls({
    required this.onPrevious,
    required this.onNext,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: _BackgroundSwitchButton(
              key: const Key('background-previous-button'),
              icon: Icons.chevron_left_rounded,
              tooltip: '切换上一个背景',
              onPressed: onPrevious,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _BackgroundSwitchButton(
              key: const Key('background-next-button'),
              icon: Icons.chevron_right_rounded,
              tooltip: '切换下一个背景',
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundSwitchButton extends StatelessWidget {
  const _BackgroundSwitchButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.74),
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x339B7B4B),
        child: IconButton(
          icon: Icon(icon),
          color: deepBlue,
          iconSize: 28,
          splashRadius: 24,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class FoodBowl extends StatelessWidget {
  const FoodBowl({super.key, required this.choice});

  final FeedingStoryChoice choice;

  @override
  Widget build(BuildContext context) {
    final isCurry = choice == FeedingStoryChoice.curry;
    return DecoratedBox(
      key: Key(isCurry ? 'curry-bowl' : 'vegetable-bowl'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7B76E), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x339B7B4B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurry ? Icons.rice_bowl_rounded : Icons.eco_rounded,
              color: isCurry
                  ? const Color(0xFFB46B25)
                  : const Color(0xFF4F8C45),
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              isCurry ? '咖喱饭' : '青菜',
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedingChoicePanel extends StatelessWidget {
  const FeedingChoicePanel({super.key, required this.onSelected});

  final ValueChanged<FeedingStoryChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('feeding-event-choice-panel'),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xEFFFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD8E9FB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A3155C6),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '迷你南河的肚子叫了一下。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '给他吃什么？',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedInk, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('feed-vegetables-choice'),
                    onPressed: () => onSelected(FeedingStoryChoice.vegetables),
                    icon: const Icon(Icons.eco_rounded),
                    label: const Text('随便给点青菜'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('feed-curry-choice'),
                    onPressed: () => onSelected(FeedingStoryChoice.curry),
                    icon: const Icon(Icons.rice_bowl_rounded),
                    label: const Text('吃一样的咖喱饭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherOverlay extends StatelessWidget {
  const _WeatherOverlay({required this.condition});

  final WeatherCondition condition;

  @override
  Widget build(BuildContext context) {
    final tint = switch (condition) {
      WeatherCondition.rainy => const Color(0x44384F6F),
      WeatherCondition.snowy => const Color(0x2CEAF6FF),
      WeatherCondition.sunny => Colors.transparent,
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: tint),
      child: CustomPaint(painter: _WeatherPainter(condition)),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  const _WeatherPainter(this.condition);

  final WeatherCondition condition;

  @override
  void paint(Canvas canvas, Size size) {
    switch (condition) {
      case WeatherCondition.rainy:
        _paintRain(canvas, size);
      case WeatherCondition.snowy:
        _paintSnow(canvas, size);
      case WeatherCondition.sunny:
        break;
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final spacing = size.width / 11;
    final rowSpacing = size.height / 8;

    for (var row = -1; row < 9; row += 1) {
      for (var col = -1; col < 13; col += 1) {
        final x = col * spacing + (row.isEven ? 0 : spacing * 0.45);
        final y = row * rowSpacing + (col % 3) * 9;
        canvas.drawLine(Offset(x, y), Offset(x - 12, y + 34), paint);
      }
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.62);
    const points = <Offset>[
      Offset(0.10, 0.12),
      Offset(0.28, 0.08),
      Offset(0.46, 0.16),
      Offset(0.68, 0.10),
      Offset(0.84, 0.20),
      Offset(0.18, 0.32),
      Offset(0.38, 0.28),
      Offset(0.58, 0.36),
      Offset(0.78, 0.30),
      Offset(0.12, 0.54),
      Offset(0.32, 0.48),
      Offset(0.52, 0.58),
      Offset(0.72, 0.50),
      Offset(0.90, 0.62),
      Offset(0.22, 0.76),
      Offset(0.44, 0.70),
      Offset(0.64, 0.80),
      Offset(0.82, 0.72),
    ];

    for (var i = 0; i < points.length; i += 1) {
      final point = points[i];
      final radius = i.isEven ? 2.2 : 1.5;
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) {
    return oldDelegate.condition != condition;
  }
}

class _CompactStatusPanel extends StatelessWidget {
  const _CompactStatusPanel({
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.energy,
    required this.maxEnergy,
    required this.pressure,
    required this.cleanliness,
  });

  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final int energy;
  final int maxEnergy;
  final int pressure;
  final int cleanliness;

  Color _pressureColor() {
    if (pressure <= 30) return const Color(0xFF2E9D68);
    if (pressure <= 60) return const Color(0xFFD49A22);
    if (pressure <= 80) return const Color(0xFFE46F32);
    return const Color(0xFFD13D3D);
  }

  Color _cleanlinessColor() {
    if (cleanliness >= 80) return const Color(0xFF2E9D68);
    if (cleanliness >= 50) return const Color(0xFFD49A22);
    if (cleanliness >= 21) return const Color(0xFFE46F32);
    return const Color(0xFFD13D3D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E9FB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniStatusBar(
            label: '好感 Lv.$affectionLevel',
            valueLabel: '$affectionProgress/100',
            value: affectionProgress / 100,
            color: const Color(0xFFFF91B8),
          ),
          const SizedBox(height: 6),
          _MiniStatusBar(
            label: '信任 Lv.$trustLevel',
            valueLabel: '$trustProgress/100',
            value: trustProgress / 100,
            color: const Color(0xFF9DA8FF),
          ),
          const SizedBox(height: 6),
          _MiniStatusBar(
            label: '体力',
            valueLabel: '$energy/$maxEnergy',
            value: energy / maxEnergy,
            color: azure,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStatusIcon(
                  key: const Key('pressure-indicator'),
                  tooltip: '压力',
                  icon: Icons.psychology_alt_rounded,
                  label: '$pressure%',
                  color: _pressureColor(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniStatusIcon(
                  key: const Key('cleanliness-indicator'),
                  tooltip: '清洁',
                  icon: Icons.cleaning_services_rounded,
                  label: '$cleanliness%',
                  color: _cleanlinessColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatusIcon extends StatelessWidget {
  const _MiniStatusIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.color,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.36)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusBar extends StatelessWidget {
  const _MiniStatusBar({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: mutedInk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: value.clamp(0, 1),
            color: color,
            backgroundColor: const Color(0xFFEAF1FA),
          ),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: blueMist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReactionBubble extends StatelessWidget {
  const _ReactionBubble({required this.reaction, required this.onTap});

  final CharacterReaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Material(
        key: ValueKey(reaction),
        color: Colors.transparent,
        child: InkWell(
          key: const Key('reaction-bubble'),
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.fromLTRB(16, 12, 28, 14),
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD8E9FB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A3155C6),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reaction.nanheSpeech,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '（${reaction.meaning}）',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: mutedInk,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: mutedInk,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.energy,
    required this.maxEnergy,
    required this.emotionLabel,
    required this.pressure,
    required this.cleanliness,
    required this.healthLabel,
    required this.personalityLabel,
    required this.traitLabel,
    required this.characterAsset,
    required this.strength,
    required this.intelligence,
    required this.charm,
    required this.art,
    required this.skill,
    required this.endurance,
  });

  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final int energy;
  final int maxEnergy;
  final String emotionLabel;
  final int pressure;
  final int cleanliness;
  final String healthLabel;
  final String personalityLabel;
  final String traitLabel;
  final String characterAsset;
  final int strength;
  final int intelligence;
  final int charm;
  final int art;
  final int skill;
  final int endurance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: ListView(
        children: [
          Text('状态', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: frost,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD7E8FA)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 74,
                    height: 74,
                    color: blueMist,
                    child: Image.asset(characterAsset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '迷你南河',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('迷你期', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StatusValueCard(
            title: '日常状态',
            children: [
              _StatusValueRow(
                label: '当前好感度',
                value: 'Lv.$affectionLevel  $affectionProgress/100',
              ),
              _StatusValueRow(
                label: '当前信任',
                value: 'Lv.$trustLevel  $trustProgress/100',
              ),
              _StatusValueRow(label: '当前体力', value: '$energy/$maxEnergy'),
              _StatusValueRow(label: '情绪', value: emotionLabel),
              _StatusValueRow(label: '压力', value: '$pressure%'),
              _StatusValueRow(label: '清洁', value: '$cleanliness%'),
              _StatusValueRow(label: '健康', value: healthLabel),
            ],
          ),
          const SizedBox(height: 10),
          _StatusValueCard(
            title: '能力数值',
            children: [
              _StatusValueRow(label: '力量', value: '$strength'),
              _StatusValueRow(label: '智力', value: '$intelligence'),
              _StatusValueRow(label: '魅力', value: '$charm'),
              _StatusValueRow(label: '艺术', value: '$art'),
              _StatusValueRow(label: '技巧', value: '$skill'),
              _StatusValueRow(label: '耐力', value: '$endurance'),
            ],
          ),
          const SizedBox(height: 10),
          _StatusValueCard(
            title: '性格与特质',
            children: [
              _StatusValueRow(label: '性格', value: personalityLabel),
              _StatusValueRow(label: '特质', value: traitLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusValueCard extends StatelessWidget {
  const _StatusValueCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: frost,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E8FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _StatusValueRow extends StatelessWidget {
  const _StatusValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isEndingReached,
    required this.isForcedSleep,
    required this.isSleepPending,
    required this.canSleep,
    required this.hasUnlockedAllDailyActions,
    required this.hasUnlockedFeed,
    required this.hasUnlockedHit,
    required this.hasUnlockedTrainingPage,
    required this.actionPage,
    required this.onPageChanged,
    required this.onChat,
    required this.onPet,
    required this.onPlay,
    required this.onObserve,
    required this.onWalk,
    required this.onFeed,
    required this.onRest,
    required this.onStudy,
    required this.onExercise,
    required this.onGame,
    required this.onCreate,
    required this.onPerform,
    required this.onBath,
    required this.onOuting,
    required this.onHit,
    required this.onSleep,
    required this.onResetGame,
  });

  final bool isEndingReached;
  final bool isForcedSleep;
  final bool isSleepPending;
  final bool canSleep;
  final bool hasUnlockedAllDailyActions;
  final bool hasUnlockedFeed;
  final bool hasUnlockedHit;
  final bool hasUnlockedTrainingPage;
  final int actionPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onChat;
  final VoidCallback onPet;
  final VoidCallback onPlay;
  final VoidCallback onObserve;
  final VoidCallback onWalk;
  final VoidCallback onFeed;
  final VoidCallback onRest;
  final VoidCallback onStudy;
  final VoidCallback onExercise;
  final VoidCallback onGame;
  final VoidCallback onCreate;
  final VoidCallback onPerform;
  final VoidCallback onBath;
  final VoidCallback onOuting;
  final VoidCallback onHit;
  final VoidCallback onSleep;
  final VoidCallback onResetGame;

  @override
  Widget build(BuildContext context) {
    if (isEndingReached) {
      return Center(
        child: SizedBox(
          width: 220,
          child: _ActionButton(
            key: const Key('reset-game-button'),
            label: '将大局逆转吧！',
            emphasized: true,
            onPressed: onResetGame,
          ),
        ),
      );
    }

    if (isForcedSleep) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: 160,
              child: _ActionButton(
                key: const Key('sleep-button'),
                label: '睡觉',
                emphasized: true,
                onPressed: onSleep,
              ),
            ),
          ),
          if (isSleepPending) ...[
            const SizedBox(height: 6),
            Text(
              '点击对话框开始下一天',
              key: const Key('sleep-dialogue-hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mutedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    final effectivePage = hasUnlockedTrainingPage ? actionPage : 0;
    final page = effectivePage == 0 ? _dailyPage() : _trainingPage();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: page),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasUnlockedTrainingPage && effectivePage > 0)
                IconButton.filledTonal(
                  key: const Key('action-page-up'),
                  tooltip: '上一页',
                  onPressed: () => onPageChanged(effectivePage - 1),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              const SizedBox(height: 6),
              if (hasUnlockedTrainingPage && effectivePage < 1)
                IconButton.filledTonal(
                  key: const Key('action-page-down'),
                  tooltip: '下一页',
                  onPressed: () => onPageChanged(effectivePage + 1),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dailyPage() {
    final restOrSleepButton = canSleep
        ? _ActionButton(
            key: const Key('sleep-button'),
            label: '睡覺',
            emphasized: true,
            onPressed: onSleep,
          )
        : _ActionButton(
            key: const Key('daily-rest-button'),
            label: '休息',
            onPressed: onRest,
          );
    final primaryActions = <Widget>[
      _ActionButton(
        key: const Key('chat-button'),
        label: '聊天',
        emphasized: true,
        onPressed: onChat,
      ),
      _ActionButton(
        key: const Key('pet-button'),
        label: '撫摸',
        onPressed: onPet,
      ),
      _ActionButton(
        key: const Key('observe-button'),
        label: '觀察',
        onPressed: onObserve,
      ),
      restOrSleepButton,
    ];
    final unlockedExtraActions = <Widget>[
      if (hasUnlockedAllDailyActions)
        _ActionButton(
          key: const Key('play-button'),
          label: '玩耍',
          onPressed: onPlay,
        ),
      if (hasUnlockedAllDailyActions)
        _ActionButton(
          key: const Key('walk-button'),
          label: '散步',
          onPressed: onWalk,
        ),
      if (hasUnlockedFeed)
        _ActionButton(
          key: const Key('feed-button'),
          label: '喂食',
          onPressed: onFeed,
        ),
      if (hasUnlockedHit)
        _ActionButton(
          key: const Key('hit-button'),
          label: '殴打',
          destructive: true,
          onPressed: onHit,
        ),
    ];

    return Column(
      children: [
        _ActionButtonRow(children: primaryActions),
        if (unlockedExtraActions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ActionButtonRow(children: unlockedExtraActions),
        ],
      ],
    );
  }

  Widget _trainingPage() {
    return Column(
      children: [
        _ActionButtonRow(
          children: [
            _ActionButton(
              key: const Key('study-button'),
              label: '学习',
              emphasized: true,
              onPressed: onStudy,
            ),
            _ActionButton(
              key: const Key('exercise-button'),
              label: '运动',
              onPressed: onExercise,
            ),
            _ActionButton(
              key: const Key('game-button'),
              label: '打游戏',
              onPressed: onGame,
            ),
            _ActionButton(
              key: const Key('create-button'),
              label: '创作',
              onPressed: onCreate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ActionButtonRow(
          children: [
            _ActionButton(
              key: const Key('perform-button'),
              label: '表演',
              onPressed: onPerform,
            ),
            _ActionButton(
              key: const Key('bath-button'),
              label: '洗澡',
              onPressed: onBath,
            ),
            _ActionButton(
              key: const Key('outing-button'),
              label: '外出',
              onPressed: onOuting,
            ),
            _ActionButton(
              key: const Key('rest-button'),
              label: '休息',
              onPressed: onRest,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.emphasized = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (destructive) {
      return FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFF9B1C1C),
          backgroundColor: const Color(0xFFFFE1E1),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

    if (emphasized) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      child: child,
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.selectedBgm,
    required this.musicVolume,
    required this.soundEffectVolume,
    required this.voiceVolume,
    required this.totalDaysTogether,
    required this.minuteOfDay,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.onMusicChanged,
    required this.onSoundEffectChanged,
    required this.onVoiceChanged,
    required this.onMusicMuteToggle,
    required this.onSoundEffectMuteToggle,
    required this.onVoiceMuteToggle,
    required this.onBgmChanged,
    required this.onDebugTimelineChanged,
    required this.onDebugAffectionLevelChanged,
    required this.onDebugAffectionProgressChanged,
    required this.onDebugTrustLevelChanged,
    required this.onDebugTrustProgressChanged,
  });

  final BgmTrack selectedBgm;
  final double musicVolume;
  final double soundEffectVolume;
  final double voiceVolume;
  final int totalDaysTogether;
  final int minuteOfDay;
  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final ValueChanged<double> onMusicChanged;
  final ValueChanged<double> onSoundEffectChanged;
  final ValueChanged<double> onVoiceChanged;
  final VoidCallback onMusicMuteToggle;
  final VoidCallback onSoundEffectMuteToggle;
  final VoidCallback onVoiceMuteToggle;
  final ValueChanged<BgmTrack> onBgmChanged;
  final void Function({required int totalDaysTogether, required int minute})
  onDebugTimelineChanged;
  final ValueChanged<int> onDebugAffectionLevelChanged;
  final ValueChanged<int> onDebugAffectionProgressChanged;
  final ValueChanged<int> onDebugTrustLevelChanged;
  final ValueChanged<int> onDebugTrustProgressChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: ListView(
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            decoration: BoxDecoration(
              color: frost,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD7E8FA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('声音', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '音乐、互动音效和语音可以分别调节。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<BgmTrack>(
                  key: const Key('bgm-selector'),
                  initialValue: selectedBgm,
                  decoration: InputDecoration(
                    labelText: '背景音乐',
                    prefixIcon: const Icon(Icons.album_rounded),
                    filled: true,
                    fillColor: blueMist.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: BgmTrack.values
                      .map(
                        (track) => DropdownMenuItem(
                          value: track,
                          child: Text(track.label),
                        ),
                      )
                      .toList(),
                  onChanged: (track) {
                    if (track != null) onBgmChanged(track);
                  },
                ),
                const SizedBox(height: 10),
                _VolumeControl(
                  sliderKey: const Key('music-volume-slider'),
                  muteKey: const Key('music-mute-button'),
                  icon: Icons.music_note_rounded,
                  label: '音乐',
                  volume: musicVolume,
                  onChanged: onMusicChanged,
                  onMuteToggle: onMusicMuteToggle,
                ),
                _VolumeControl(
                  sliderKey: const Key('sound-effect-volume-slider'),
                  muteKey: const Key('sound-effect-mute-button'),
                  icon: Icons.touch_app_rounded,
                  label: '音效',
                  volume: soundEffectVolume,
                  onChanged: onSoundEffectChanged,
                  onMuteToggle: onSoundEffectMuteToggle,
                ),
                _VolumeControl(
                  sliderKey: const Key('voice-volume-slider'),
                  muteKey: const Key('voice-mute-button'),
                  icon: Icons.record_voice_over_rounded,
                  label: '语音',
                  volume: voiceVolume,
                  onChanged: onVoiceChanged,
                  onMuteToggle: onVoiceMuteToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.save_outlined),
            title: Text('本机存档'),
            subtitle: Text('将在 EPIC 7 实作'),
          ),
          const SizedBox(height: 8),
          _DebugToolsPanel(
            totalDaysTogether: totalDaysTogether,
            minuteOfDay: minuteOfDay,
            affectionLevel: affectionLevel,
            affectionProgress: affectionProgress,
            trustLevel: trustLevel,
            trustProgress: trustProgress,
            onTimelineChanged: onDebugTimelineChanged,
            onAffectionLevelChanged: onDebugAffectionLevelChanged,
            onAffectionProgressChanged: onDebugAffectionProgressChanged,
            onTrustLevelChanged: onDebugTrustLevelChanged,
            onTrustProgressChanged: onDebugTrustProgressChanged,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '版本 $appVersion',
              key: Key('app-version'),
              style: TextStyle(
                color: Color(0xFF7A8796),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DebugToolsPanel extends StatelessWidget {
  const _DebugToolsPanel({
    required this.totalDaysTogether,
    required this.minuteOfDay,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.trustLevel,
    required this.trustProgress,
    required this.onTimelineChanged,
    required this.onAffectionLevelChanged,
    required this.onAffectionProgressChanged,
    required this.onTrustLevelChanged,
    required this.onTrustProgressChanged,
  });

  final int totalDaysTogether;
  final int minuteOfDay;
  final int affectionLevel;
  final int affectionProgress;
  final int trustLevel;
  final int trustProgress;
  final void Function({required int totalDaysTogether, required int minute})
  onTimelineChanged;
  final ValueChanged<int> onAffectionLevelChanged;
  final ValueChanged<int> onAffectionProgressChanged;
  final ValueChanged<int> onTrustLevelChanged;
  final ValueChanged<int> onTrustProgressChanged;

  static const _presets = [
    _DebugTimePreset('第1天 06:00', 1, 6 * 60),
    _DebugTimePreset('第1天 12:00', 1, 12 * 60),
    _DebugTimePreset('第1天 22:00', 1, 22 * 60),
    _DebugTimePreset('第3天 06:00', 3, 6 * 60),
    _DebugTimePreset('第7天 06:00', 7, 6 * 60),
    _DebugTimePreset('第7天 16:00', 7, 16 * 60),
    _DebugTimePreset('第26天 06:00', 26, 6 * 60),
    _DebugTimePreset('第61天 06:00', 61, 6 * 60),
  ];

  String get _timeLabel {
    final normalizedMinute = minuteOfDay % _midnightMinute;
    final hour = normalizedMinute ~/ 60;
    final minute = normalizedMinute % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('debug-tools-panel'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3C98A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.construction_rounded, color: gold),
              const SizedBox(width: 8),
              Text('测试工具', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '用于快速检查迷你期节点，不影响之后正式存档设计。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                ActionChip(
                  key: Key('debug-preset-${preset.label}'),
                  label: Text(preset.label),
                  avatar: const Icon(Icons.bolt_rounded, size: 16),
                  onPressed: () => onTimelineChanged(
                    totalDaysTogether: preset.day,
                    minute: preset.minute,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _DebugIntSlider(
            key: const Key('debug-day-slider'),
            label: '在一起天数',
            valueLabel: '第 $totalDaysTogether 天',
            value: totalDaysTogether,
            min: 1,
            max: 90,
            onChanged: (value) => onTimelineChanged(
              totalDaysTogether: value,
              minute: minuteOfDay,
            ),
          ),
          _DebugIntSlider(
            key: const Key('debug-time-slider'),
            label: '时间',
            valueLabel: _timeLabel,
            value: minuteOfDay,
            min: 0,
            max: _midnightMinute,
            divisions: 48,
            onChanged: (value) => onTimelineChanged(
              totalDaysTogether: totalDaysTogether,
              minute: value,
            ),
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('debug-affection-lv2'),
                label: const Text('好感 Lv2'),
                onPressed: () {
                  onAffectionLevelChanged(2);
                  onAffectionProgressChanged(0);
                },
              ),
              ActionChip(
                key: const Key('debug-affection-lv5'),
                label: const Text('好感 Lv5'),
                onPressed: () {
                  onAffectionLevelChanged(5);
                  onAffectionProgressChanged(0);
                },
              ),
              ActionChip(
                key: const Key('debug-trust-lv2'),
                label: const Text('信任 Lv2'),
                onPressed: () {
                  onTrustLevelChanged(2);
                  onTrustProgressChanged(0);
                },
              ),
              ActionChip(
                key: const Key('debug-trust-lv4'),
                label: const Text('信任 Lv4'),
                onPressed: () {
                  onTrustLevelChanged(4);
                  onTrustProgressChanged(0);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DebugIntSlider(
            key: const Key('debug-affection-level-slider'),
            label: '好感等级',
            valueLabel: 'Lv.$affectionLevel',
            value: affectionLevel,
            min: 1,
            max: 10,
            onChanged: onAffectionLevelChanged,
          ),
          _DebugIntSlider(
            key: const Key('debug-affection-progress-slider'),
            label: '好感进度',
            valueLabel: '$affectionProgress/100',
            value: affectionProgress,
            min: 0,
            max: 99,
            onChanged: onAffectionProgressChanged,
          ),
          _DebugIntSlider(
            key: const Key('debug-trust-level-slider'),
            label: '信任等级',
            valueLabel: 'Lv.$trustLevel',
            value: trustLevel,
            min: 1,
            max: 10,
            onChanged: onTrustLevelChanged,
          ),
          _DebugIntSlider(
            key: const Key('debug-trust-progress-slider'),
            label: '信任进度',
            valueLabel: '$trustProgress/100',
            value: trustProgress,
            min: 0,
            max: 99,
            onChanged: onTrustProgressChanged,
          ),
        ],
      ),
    );
  }
}

class _DebugTimePreset {
  const _DebugTimePreset(this.label, this.day, this.minute);

  final String label;
  final int day;
  final int minute;
}

class _DebugIntSlider extends StatelessWidget {
  const _DebugIntSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueLabel;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  color: mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions ?? max - min,
            label: valueLabel,
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.sliderKey,
    required this.muteKey,
    required this.icon,
    required this.label,
    required this.volume,
    required this.onChanged,
    required this.onMuteToggle,
  });

  final Key sliderKey;
  final Key muteKey;
  final IconData icon;
  final String label;
  final double volume;
  final ValueChanged<double> onChanged;
  final VoidCallback onMuteToggle;

  @override
  Widget build(BuildContext context) {
    final isMuted = volume == 0;
    final percentage = (volume * 100).round();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: isMuted ? mutedInk : deepBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                key: Key('$label-volume-value'),
                style: const TextStyle(
                  color: mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: muteKey,
                tooltip: isMuted ? '取消静音' : '静音',
                onPressed: onMuteToggle,
                icon: Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                ),
              ),
            ],
          ),
          Slider(
            key: sliderKey,
            value: volume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$percentage%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
