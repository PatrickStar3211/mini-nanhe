import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'abuse_story_screen.dart';
import 'app_version.dart';
import 'character_reaction.dart';
import 'collection_screen.dart';
import 'doghouse_unlock_story_screen.dart';
import 'evolution_story_screen.dart';
import 'feeding_story_screen.dart';
import 'game_audio_controller.dart';
import 'game_assets.dart';
import 'home_bedtime_story_screen.dart';
import 'luxury_unlock_story_screen.dart';
import 'lol_rank_system.dart';
import 'opening_story_screen.dart';
import 'reaction_rules.dart';
import 'sick_ending_story_screen.dart';
import 'sickness_story_screen.dart';
import 'theme.dart';

const _initialMaxEnergy = 25;
const _minStatValue = 1;
const _maxStatValue = 9999;
const _affectionGainPerInteraction = 3;
const _affectionGainPerQuietInteraction = 1;
const _affectionLossPerHit = 5;
const _trustLossPerHit = 10;
const _deathHitThreshold = 50;
const _minutesPerInteraction = 30;
const _minutesPerTraining = 60;
const _sleepAvailableMinute = 22 * 60;
const _midnightMinute = 24 * 60;
const _postMidnightSickEndingMinute = 28 * 60;
const _earliestWakeMinute = 6 * 60;
const _sleepDurationMinutes = 8 * 60;
const _endurancePerMaxEnergy = 4;
const _feedUnlockMinute = 12 * 60;
const _daySevenSickMinute = 16 * 60;
const _sickEndingTriggerMinute = 22 * 60;
const _daysPerCommonYear = 365;
const _daysInMonth = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

enum YardHomeTier { box, doghouse, luxury }

enum HomeRoom { bedroom, livingRoom, study }

enum GrowthStage { mini, childhood }

enum CompanionLocation { garden, home }

enum NanheAppearance { mini, childhood }

enum WeatherCondition { sunny, rainy, snowy }

const _saveSlotCount = 3;
const _saveSlotKeyPrefix = 'mini_nanhe_save_slot_';
const _saveSchemaVersion = 1;
const _saveCodePrefix = 'MN1.';

String _formatMinuteLabel(int minuteOfDay) {
  final normalizedMinute = minuteOfDay % _midnightMinute;
  final hour = normalizedMinute ~/ 60;
  final minute = normalizedMinute % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

int _zeroBasedCalendarDay(int year, int month, int day) {
  final daysBeforeYear = (year - 1) * _daysPerCommonYear;
  final daysBeforeMonth = _daysInMonth
      .take(month - 1)
      .fold<int>(0, (total, days) => total + days);
  return daysBeforeYear + daysBeforeMonth + day - 1;
}

String _weekdayLabelForDate(int year, int month, int day) {
  const labels = <String>['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  return labels[_zeroBasedCalendarDay(year, month, day) % labels.length];
}

const _sickEndingCareReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '高烧退不下去',
    meaning: '迷你南河的身体烫得吓人。',
    voice: NanheVoice.sadDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '越来越虚弱了',
    meaning: '他的呼吸比刚才更轻了。',
    voice: NanheVoice.sadDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '咳血停不下来',
    meaning: '床边的手帕又被染红了一点。',
    voice: NanheVoice.sadDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '吃了药也没有好转',
    meaning: '你能做的事情正在变少。',
    voice: NanheVoice.sadDouble,
  ),
];

class MiniNanheDebugState {
  const MiniNanheDebugState({
    this.totalDaysTogether,
    this.minuteOfDay,
    this.affectionLevel,
    this.affectionProgress,
    this.trustLevel,
    this.trustProgress,
    this.energy,
    this.money,
    this.healthValue,
    this.exhaustionCount,
    this.injury,
    this.cleanliness,
    this.growthStage,
    this.homeBedtimeStoryCompleted,
    this.homeInteriorUnlocked,
    this.feedEventTriggered,
    this.feedEventCompleted,
    this.feedEventResolvedCorrectly,
    this.sicknessEventResolvedCorrectly,
    this.doghouseUnlocked,
    this.luxuryUnlocked,
    this.skill,
    this.lolTotalLp,
    this.lolHistoricalPeakTotalLp,
    this.lolConsecutiveWins,
    this.lolConsecutiveLosses,
  });

  final int? totalDaysTogether;
  final int? minuteOfDay;
  final int? affectionLevel;
  final int? affectionProgress;
  final int? trustLevel;
  final int? trustProgress;
  final int? energy;
  final int? money;
  final int? healthValue;
  final int? exhaustionCount;
  final int? injury;
  final int? cleanliness;
  final GrowthStage? growthStage;
  final bool? homeBedtimeStoryCompleted;
  final bool? homeInteriorUnlocked;
  final bool? feedEventTriggered;
  final bool? feedEventCompleted;
  final bool? feedEventResolvedCorrectly;
  final bool? sicknessEventResolvedCorrectly;
  final bool? doghouseUnlocked;
  final bool? luxuryUnlocked;
  final int? skill;
  final int? lolTotalLp;
  final int? lolHistoricalPeakTotalLp;
  final int? lolConsecutiveWins;
  final int? lolConsecutiveLosses;
}

class _SaveSlotSummary {
  const _SaveSlotSummary({
    required this.slotIndex,
    this.savedAt,
    this.totalDaysTogether,
    this.minuteOfDay,
    this.affectionLevel,
    this.trustLevel,
  });

  final int slotIndex;
  final DateTime? savedAt;
  final int? totalDaysTogether;
  final int? minuteOfDay;
  final int? affectionLevel;
  final int? trustLevel;

  bool get isEmpty => savedAt == null;

  String get title => '存档 ${slotIndex + 1}';

  String get subtitle {
    final savedTime = savedAt;
    if (savedTime == null) return '空槽';
    final day = totalDaysTogether ?? 1;
    final time = _formatMinuteLabel(minuteOfDay ?? 0);
    final savedAtLabel =
        '${savedTime.month.toString().padLeft(2, '0')}/'
        '${savedTime.day.toString().padLeft(2, '0')} '
        '${savedTime.hour.toString().padLeft(2, '0')}:'
        '${savedTime.minute.toString().padLeft(2, '0')}';
    return '第 $day 天 $time · 好感 Lv.${affectionLevel ?? 1} · 信任 Lv.${trustLevel ?? 1} · $savedAtLabel';
  }
}

class _StatPopup {
  const _StatPopup({required this.id, required this.label});

  final int id;
  final String label;
}

class _LolMatchRecord {
  const _LolMatchRecord({required this.won, required this.lpDelta});

  factory _LolMatchRecord.fromJson(Map<String, dynamic> json) {
    return _LolMatchRecord(
      won: json['won'] is bool && json['won'] as bool,
      lpDelta: json['lpDelta'] is num ? (json['lpDelta'] as num).round() : 0,
    );
  }

  final bool won;
  final int lpDelta;

  Map<String, Object?> toJson() => {'won': won, 'lpDelta': lpDelta};
}

enum _PpMessageSender { patrick, nanhe }

class _PpChatMessage {
  const _PpChatMessage({required this.sender, required this.text});

  factory _PpChatMessage.fromJson(Map<String, dynamic> json) {
    final senderName = json['sender'];
    return _PpChatMessage(
      sender: _PpMessageSender.values.firstWhere(
        (sender) => sender.name == senderName,
        orElse: () => _PpMessageSender.patrick,
      ),
      text: json['text'] is String ? json['text'] as String : '',
    );
  }

  final _PpMessageSender sender;
  final String text;

  bool get isNanhe => sender == _PpMessageSender.nanhe;

  Map<String, Object?> toJson() => {'sender': sender.name, 'text': text};
}

const _initialPpMessages = <_PpChatMessage>[
  _PpChatMessage(
    sender: _PpMessageSender.patrick,
    text: '嗨，小南河！欢迎使用PP，我是派大星博士教授先生。',
  ),
  _PpChatMessage(
    sender: _PpMessageSender.patrick,
    text: 'PP是通讯软件。朋友发来的消息、聊天和以后的接单信息，都会显示在这里。',
  ),
  _PpChatMessage(
    sender: _PpMessageSender.patrick,
    text: '掌盟可以查看段位、进行排位，也能回顾最近的战绩。',
  ),
  _PpChatMessage(
    sender: _PpMessageSender.patrick,
    text: '以后我还会通过PP告诉你更多功能，记得留意未读消息。',
  ),
];

class _PpContact {
  const _PpContact({
    required this.name,
    required this.signature,
    required this.avatarAsset,
  });

  final String name;
  final String signature;
  final String avatarAsset;
}

const _patrickPpContact = _PpContact(
  name: '派大星博士教授先生',
  signature: '请你叫我派大星博士教授加先生',
  avatarAsset: phonePpPatrickAvatarAsset,
);

class _LolMatchResult {
  const _LolMatchResult({
    required this.won,
    required this.lpDelta,
    required this.afterPosition,
    required this.rankChangeLabel,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.reachedMidnight,
  });

  final bool won;
  final int lpDelta;
  final LolRankPosition afterPosition;
  final String rankChangeLabel;
  final int consecutiveWins;
  final int consecutiveLosses;
  final bool reachedMidnight;
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
  int _money = 0;
  int _lastChoresDay = -1;
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
  GrowthStage _growthStage = GrowthStage.mini;
  YardHomeTier _yardHomeTier = YardHomeTier.box;
  HomeRoom _homeRoom = HomeRoom.bedroom;
  CompanionLocation _companionLocation = CompanionLocation.garden;
  NanheAppearance _selectedAppearance = NanheAppearance.mini;
  bool _hasBeenHit = false;
  int _hitCount = 0;
  bool _bondLockedByPreEvolutionHit = false;
  bool _deathPending = false;
  bool _deathEndingReached = false;
  bool _feedEventTriggered = false;
  bool _feedEventCompleted = false;
  bool _firstHitEventTriggered = false;
  bool _daySevenSicknessTriggered = false;
  bool _sicknessEventCompleted = false;
  bool _sicknessStoryPending = false;
  bool _showingSicknessStory = false;
  bool _sickEndingOnsetTriggered = false;
  bool _sickEndingOnsetStoryPending = false;
  bool _showingSickEndingOnsetStory = false;
  bool _sickEndingCareActive = false;
  bool _sickEndingFinalStoryPending = false;
  bool _showingSickEndingFinalStory = false;
  bool _doghouseUnlockPending = false;
  bool _doghouseUnlockStoryPending = false;
  bool _showingDoghouseUnlockStory = false;
  bool _doghouseUnlocked = false;
  bool _luxuryUnlockPending = false;
  bool _luxuryUnlockStoryPending = false;
  bool _showingLuxuryUnlockStory = false;
  bool _luxuryUnlocked = false;
  bool _showingEvolutionStory = false;
  bool _homeBedtimeStoryCompleted = false;
  bool _homeInteriorUnlocked = false;
  bool _showingHomeBedtimeStory = false;
  bool _feedEventResolvedCorrectly = false;
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
  int _lolTotalLp = 0;
  int _lolHistoricalPeakTotalLp = 0;
  int _lolConsecutiveWins = 0;
  int _lolConsecutiveLosses = 0;
  final List<_LolMatchRecord> _lolMatchHistory = [];
  final List<_PpChatMessage> _ppMessages = List.of(_initialPpMessages);
  int _ppUnreadCount = _initialPpMessages.length;
  int? _pendingLolRankedEnergyCost;
  bool _phoneNavigationLocked = false;
  double _musicVolume = 0.7;
  double _soundEffectVolume = 0.8;
  double _voiceVolume = 0.9;
  double _musicVolumeBeforeMute = 0.7;
  double _soundEffectVolumeBeforeMute = 0.8;
  double _voiceVolumeBeforeMute = 0.9;
  bool _showDebugTools = false;
  BgmTrack _selectedBgm = BgmTrack.cozyNanhe2;
  int _nextStatPopupId = 0;
  final List<_StatPopup> _statPopups = [];
  final List<Timer> _statPopupTimers = [];
  List<_SaveSlotSummary> _saveSlots = List.generate(
    _saveSlotCount,
    (index) => _SaveSlotSummary(slotIndex: index),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaveSlotSummaries());
    final debug = widget.debugInitialState;
    if (debug == null) return;
    if (debug.totalDaysTogether != null) {
      _setCalendarFromTotalDays(debug.totalDaysTogether!);
    }
    _minuteOfDay = debug.minuteOfDay ?? _minuteOfDay;
    _affectionLevel = debug.affectionLevel ?? _affectionLevel;
    _affectionProgress = debug.affectionProgress ?? _affectionProgress;
    _trustLevel = debug.trustLevel ?? _trustLevel;
    _trustProgress = debug.trustProgress ?? _trustProgress;
    _energy = debug.energy ?? _energy;
    _money = max(0, debug.money ?? _money);
    _healthValue = debug.healthValue ?? _healthValue;
    _exhaustionCount = debug.exhaustionCount ?? _exhaustionCount;
    _injury = debug.injury ?? _injury;
    _cleanliness = debug.cleanliness ?? _cleanliness;
    _growthStage = debug.growthStage ?? _growthStage;
    _homeBedtimeStoryCompleted =
        debug.homeBedtimeStoryCompleted ?? _homeBedtimeStoryCompleted;
    _homeInteriorUnlocked = debug.homeInteriorUnlocked ?? _homeInteriorUnlocked;
    if (_growthStage == GrowthStage.childhood) {
      _selectedAppearance = NanheAppearance.childhood;
    }
    if (_homeInteriorUnlocked) {
      _companionLocation = CompanionLocation.home;
    }
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
    if (debug.sicknessEventResolvedCorrectly != null) {
      _sicknessEventCompleted = true;
      _daySevenSicknessTriggered = true;
    }
    _doghouseUnlocked = debug.doghouseUnlocked ?? _doghouseUnlocked;
    _luxuryUnlocked = debug.luxuryUnlocked ?? _luxuryUnlocked;
    _skill = _clampStat(debug.skill ?? _skill);
    _lolTotalLp = max(0, debug.lolTotalLp ?? _lolTotalLp);
    _lolHistoricalPeakTotalLp = max(
      _lolTotalLp,
      debug.lolHistoricalPeakTotalLp ?? _lolHistoricalPeakTotalLp,
    );
    _lolConsecutiveWins = max(
      0,
      debug.lolConsecutiveWins ?? _lolConsecutiveWins,
    );
    _lolConsecutiveLosses = max(
      0,
      debug.lolConsecutiveLosses ?? _lolConsecutiveLosses,
    );
    if (_luxuryUnlocked) {
      _doghouseUnlocked = true;
      _yardHomeTier = YardHomeTier.luxury;
    } else if (_doghouseUnlocked) {
      _yardHomeTier = YardHomeTier.doghouse;
    }
    _applyTimedEvents(showStory: false);
    _applyHealthDeathIfNeeded();
    _clampEnergyToMax();
  }

  Future<void> _loadSaveSlotSummaries() async {
    final preferences = await SharedPreferences.getInstance();
    final slots = <_SaveSlotSummary>[];
    for (var index = 0; index < _saveSlotCount; index += 1) {
      slots.add(
        _readSaveSlotSummary(preferences.getString(_saveSlotKey(index)), index),
      );
    }
    if (mounted) setState(() => _saveSlots = slots);
  }

  _SaveSlotSummary _readSaveSlotSummary(String? rawSave, int slotIndex) {
    if (rawSave == null) return _SaveSlotSummary(slotIndex: slotIndex);
    try {
      final decoded = jsonDecode(rawSave);
      if (decoded is! Map<String, dynamic>) {
        return _SaveSlotSummary(slotIndex: slotIndex);
      }
      final state = decoded['state'];
      final savedAtRaw = decoded['savedAt'];
      final savedAt = savedAtRaw is String
          ? DateTime.tryParse(savedAtRaw)
          : null;
      if (state is! Map<String, dynamic> || savedAt == null) {
        return _SaveSlotSummary(slotIndex: slotIndex);
      }
      return _SaveSlotSummary(
        slotIndex: slotIndex,
        savedAt: savedAt,
        totalDaysTogether: _jsonInt(state, 'totalDaysTogether', 1),
        minuteOfDay: _jsonInt(state, 'minuteOfDay', 6 * 60),
        affectionLevel: _jsonInt(state, 'affectionLevel', 1),
        trustLevel: _jsonInt(state, 'trustLevel', 1),
      );
    } catch (_) {
      return _SaveSlotSummary(slotIndex: slotIndex);
    }
  }

  String _saveSlotKey(int slotIndex) => '$_saveSlotKeyPrefix$slotIndex';

  Future<void> _saveGameToSlot(int slotIndex) async {
    final preferences = await SharedPreferences.getInstance();
    final saveData = <String, Object?>{
      'schemaVersion': _saveSchemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'state': _buildSaveState(),
    };
    await preferences.setString(_saveSlotKey(slotIndex), jsonEncode(saveData));
    await _loadSaveSlotSummaries();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已保存到存档 ${slotIndex + 1}')));
  }

  Future<void> _loadGameFromSlot(int slotIndex) async {
    final preferences = await SharedPreferences.getInstance();
    final rawSave = preferences.getString(_saveSlotKey(slotIndex));
    if (rawSave == null) return;
    try {
      final decoded = jsonDecode(rawSave);
      if (decoded is! Map<String, dynamic>) return;
      final state = decoded['state'];
      if (state is! Map<String, dynamic>) return;
      setState(() => _applySaveState(state));
      _syncAudioControllerWithState();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已读取存档 ${slotIndex + 1}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('存档 ${slotIndex + 1} 无法读取')));
    }
  }

  Future<void> _exportSaveSlot(int slotIndex) async {
    final preferences = await SharedPreferences.getInstance();
    final rawSave = preferences.getString(_saveSlotKey(slotIndex));
    if (rawSave == null) return;
    final saveCode = _encodeSaveCode(rawSave);
    await Clipboard.setData(ClipboardData(text: saveCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('存档 ${slotIndex + 1} 的存档码已复制')));
  }

  Future<void> _showImportSaveDialog() async {
    final result = await showDialog<_SaveImportResult>(
      context: context,
      builder: (context) => const _ImportSaveDialog(),
    );
    if (result == null) return;
    await _importSaveCodeToSlot(result.saveCode, result.slotIndex);
  }

  Future<void> _importSaveCodeToSlot(String saveCode, int slotIndex) async {
    final rawSave = _decodeSaveCode(saveCode);
    if (rawSave == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('存档码无法读取')));
      return;
    }
    final summary = _readSaveSlotSummary(rawSave, slotIndex);
    if (summary.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('存档码内容无效')));
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_saveSlotKey(slotIndex), rawSave);
    await _loadSaveSlotSummaries();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已导入到存档 ${slotIndex + 1}')));
  }

  String _encodeSaveCode(String rawSave) {
    final encoded = base64UrlEncode(utf8.encode(rawSave));
    return '$_saveCodePrefix$encoded';
  }

  String? _decodeSaveCode(String saveCode) {
    final trimmed = saveCode.trim();
    if (!trimmed.startsWith(_saveCodePrefix)) return null;
    final encoded = trimmed.substring(_saveCodePrefix.length);
    try {
      return utf8.decode(base64Url.decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _buildSaveState() {
    return {
      'totalDaysTogether': _totalDaysTogether,
      'year': _year,
      'month': _month,
      'day': _day,
      'minuteOfDay': _minuteOfDay,
      'energy': _energy,
      'money': _money,
      'lastChoresDay': _lastChoresDay,
      'affectionLevel': _affectionLevel,
      'affectionProgress': _affectionProgress,
      'trustLevel': _trustLevel,
      'trustProgress': _trustProgress,
      'pressure': _pressure,
      'cleanliness': _cleanliness,
      'healthValue': _healthValue,
      'injury': _injury,
      'exhaustionCount': _exhaustionCount,
      'actionPage': _actionPage,
      'growthStage': _growthStage.name,
      'yardHomeTier': _yardHomeTier.name,
      'homeRoom': _homeRoom.name,
      'companionLocation': _companionLocation.name,
      'selectedAppearance': _selectedAppearance.name,
      'homeBedtimeStoryCompleted': _homeBedtimeStoryCompleted,
      'homeInteriorUnlocked': _homeInteriorUnlocked,
      'hasBeenHit': _hasBeenHit,
      'hitCount': _hitCount,
      'bondLockedByPreEvolutionHit': _bondLockedByPreEvolutionHit,
      'deathPending': _deathPending,
      'deathEndingReached': _deathEndingReached,
      'feedEventTriggered': _feedEventTriggered,
      'feedEventCompleted': _feedEventCompleted,
      'firstHitEventTriggered': _firstHitEventTriggered,
      'daySevenSicknessTriggered': _daySevenSicknessTriggered,
      'sicknessEventCompleted': _sicknessEventCompleted,
      'sickEndingOnsetTriggered': _sickEndingOnsetTriggered,
      'sickEndingCareActive': _sickEndingCareActive,
      'doghouseUnlocked': _doghouseUnlocked,
      'luxuryUnlocked': _luxuryUnlocked,
      'feedEventResolvedCorrectly': _feedEventResolvedCorrectly,
      'sicknessEventResolvedCorrectly': _sicknessEventResolvedCorrectly,
      'memoryIds': _permanentMemoryIds.toList(),
      'achievementIds': _permanentAchievementIds.toList(),
      'decorationIds': _permanentDecorationIds.toList(),
      'strength': _strength,
      'intelligence': _intelligence,
      'charm': _charm,
      'art': _art,
      'skill': _skill,
      'endurance': _endurance,
      'lolTotalLp': _lolTotalLp,
      'lolHistoricalPeakTotalLp': _lolHistoricalPeakTotalLp,
      'lolConsecutiveWins': _lolConsecutiveWins,
      'lolConsecutiveLosses': _lolConsecutiveLosses,
      'lolMatchHistory': _lolMatchHistory
          .map((record) => record.toJson())
          .toList(),
      'ppMessages': _ppMessages.map((message) => message.toJson()).toList(),
      'ppUnreadCount': _ppUnreadCount,
      'musicVolume': _musicVolume,
      'soundEffectVolume': _soundEffectVolume,
      'voiceVolume': _voiceVolume,
      'musicVolumeBeforeMute': _musicVolumeBeforeMute,
      'soundEffectVolumeBeforeMute': _soundEffectVolumeBeforeMute,
      'voiceVolumeBeforeMute': _voiceVolumeBeforeMute,
      'selectedBgm': _selectedBgm.name,
    };
  }

  void _applySaveState(Map<String, dynamic> state) {
    _selectedDestination = 0;
    _totalDaysTogether = _jsonInt(state, 'totalDaysTogether', 1);
    _year = _jsonInt(state, 'year', 1);
    _month = _jsonInt(state, 'month', 1);
    _day = _jsonInt(state, 'day', 1);
    _minuteOfDay = _jsonInt(
      state,
      'minuteOfDay',
      6 * 60,
    ).clamp(0, _postMidnightSickEndingMinute);
    _energy = _jsonInt(
      state,
      'energy',
      _initialMaxEnergy,
    ).clamp(0, _maxStatValue);
    _money = max(0, _jsonInt(state, 'money', 0));
    _lastChoresDay = _jsonInt(state, 'lastChoresDay', -1);
    _affectionLevel = _clampStat(_jsonInt(state, 'affectionLevel', 1));
    _affectionProgress = _jsonInt(state, 'affectionProgress', 0).clamp(0, 99);
    _trustLevel = _clampStat(_jsonInt(state, 'trustLevel', 1));
    _trustProgress = _jsonInt(state, 'trustProgress', 0).clamp(0, 99);
    _pressure = _clampPercent(_jsonInt(state, 'pressure', 0));
    _cleanliness = _clampPercent(_jsonInt(state, 'cleanliness', 100));
    _healthValue = _clampPercent(_jsonInt(state, 'healthValue', 80));
    _injury = _clampPercent(_jsonInt(state, 'injury', 0));
    _exhaustionCount = _clampPercent(_jsonInt(state, 'exhaustionCount', 0));
    _actionPage = _jsonInt(state, 'actionPage', 0).clamp(0, 1);
    _growthStage = _growthStageFromName(
      _jsonString(state, 'growthStage', GrowthStage.mini.name),
    );
    _yardHomeTier = _yardHomeFromName(
      _jsonString(state, 'yardHomeTier', YardHomeTier.box.name),
    );
    _homeRoom = _homeRoomFromName(
      _jsonString(state, 'homeRoom', HomeRoom.bedroom.name),
    );
    _companionLocation = _companionLocationFromName(
      _jsonString(state, 'companionLocation', CompanionLocation.garden.name),
    );
    _selectedAppearance = _nanheAppearanceFromName(
      _jsonString(
        state,
        'selectedAppearance',
        _growthStage == GrowthStage.childhood
            ? NanheAppearance.childhood.name
            : NanheAppearance.mini.name,
      ),
    );
    _homeBedtimeStoryCompleted = _jsonBool(
      state,
      'homeBedtimeStoryCompleted',
      false,
    );
    _homeInteriorUnlocked = _jsonBool(state, 'homeInteriorUnlocked', false);
    _hasBeenHit = _jsonBool(state, 'hasBeenHit', false);
    _hitCount = _jsonInt(state, 'hitCount', 0);
    _bondLockedByPreEvolutionHit = _jsonBool(
      state,
      'bondLockedByPreEvolutionHit',
      false,
    );
    _deathPending = _jsonBool(state, 'deathPending', false);
    _deathEndingReached = _jsonBool(state, 'deathEndingReached', false);
    _feedEventTriggered = _jsonBool(state, 'feedEventTriggered', false);
    _feedEventCompleted = _jsonBool(state, 'feedEventCompleted', false);
    _firstHitEventTriggered = _jsonBool(state, 'firstHitEventTriggered', false);
    _daySevenSicknessTriggered = _jsonBool(
      state,
      'daySevenSicknessTriggered',
      false,
    );
    _sicknessEventCompleted = _jsonBool(state, 'sicknessEventCompleted', false);
    _sickEndingOnsetTriggered = _jsonBool(
      state,
      'sickEndingOnsetTriggered',
      false,
    );
    _sickEndingCareActive = _jsonBool(state, 'sickEndingCareActive', false);
    _doghouseUnlocked = _jsonBool(state, 'doghouseUnlocked', false);
    _luxuryUnlocked = _jsonBool(state, 'luxuryUnlocked', false);
    _feedEventResolvedCorrectly = _jsonBool(
      state,
      'feedEventResolvedCorrectly',
      false,
    );
    _sicknessEventResolvedCorrectly = _jsonBool(
      state,
      'sicknessEventResolvedCorrectly',
      false,
    );
    _permanentMemoryIds
      ..clear()
      ..addAll(_jsonStringList(state, 'memoryIds', const ['opening-memory']));
    _permanentAchievementIds
      ..clear()
      ..addAll(_jsonStringList(state, 'achievementIds', const ['rainy-day']));
    _permanentDecorationIds
      ..clear()
      ..addAll(_jsonStringList(state, 'decorationIds', const ['yard-box']));
    _strength = _clampStat(_jsonInt(state, 'strength', 1));
    _intelligence = _clampStat(_jsonInt(state, 'intelligence', 1));
    _charm = _clampStat(_jsonInt(state, 'charm', 1));
    _art = _clampStat(_jsonInt(state, 'art', 1));
    _skill = _clampStat(_jsonInt(state, 'skill', 1));
    _endurance = _clampStat(_jsonInt(state, 'endurance', 1));
    _lolTotalLp = max(0, _jsonInt(state, 'lolTotalLp', 0));
    _lolHistoricalPeakTotalLp = max(
      _lolTotalLp,
      _jsonInt(state, 'lolHistoricalPeakTotalLp', _lolTotalLp),
    );
    _lolConsecutiveWins = max(0, _jsonInt(state, 'lolConsecutiveWins', 0));
    _lolConsecutiveLosses = max(0, _jsonInt(state, 'lolConsecutiveLosses', 0));
    _lolMatchHistory
      ..clear()
      ..addAll(_jsonLolMatchHistory(state, 'lolMatchHistory'));
    _ppMessages
      ..clear()
      ..addAll(_jsonPpMessages(state, 'ppMessages'));
    _ppUnreadCount = max(
      0,
      _jsonInt(state, 'ppUnreadCount', _initialPpMessages.length),
    );
    _musicVolume = _jsonDouble(state, 'musicVolume', 0.7).clamp(0, 1);
    _soundEffectVolume = _jsonDouble(
      state,
      'soundEffectVolume',
      0.8,
    ).clamp(0, 1);
    _voiceVolume = _jsonDouble(state, 'voiceVolume', 0.9).clamp(0, 1);
    _musicVolumeBeforeMute = _jsonDouble(
      state,
      'musicVolumeBeforeMute',
      0.7,
    ).clamp(0, 1);
    _soundEffectVolumeBeforeMute = _jsonDouble(
      state,
      'soundEffectVolumeBeforeMute',
      0.8,
    ).clamp(0, 1);
    _voiceVolumeBeforeMute = _jsonDouble(
      state,
      'voiceVolumeBeforeMute',
      0.9,
    ).clamp(0, 1);
    _selectedBgm = _bgmFromName(
      _jsonString(state, 'selectedBgm', BgmTrack.cozyNanhe2.name),
    );
    _sleepPending = false;
    _sicknessStoryPending = false;
    _showingSicknessStory = false;
    _sickEndingOnsetStoryPending = false;
    _showingSickEndingOnsetStory = false;
    _sickEndingFinalStoryPending = false;
    _showingSickEndingFinalStory = false;
    _doghouseUnlockStoryPending = false;
    _showingDoghouseUnlockStory = false;
    _luxuryUnlockStoryPending = false;
    _showingLuxuryUnlockStory = false;
    _showingHomeBedtimeStory = false;
    _reaction = null;
    _isReacting = false;
    _applyTimedEvents(showStory: false);
    _applyHealthDeathIfNeeded();
    _clampEnergyToMax();
    _queueProgressionUnlocks();
    if (!_unlockedYardHomes.contains(_yardHomeTier)) {
      _yardHomeTier = _unlockedYardHomes.last;
    }
    if (!_homeInteriorUnlocked) {
      _companionLocation = CompanionLocation.garden;
    }
    if (_growthStage == GrowthStage.mini) {
      _selectedAppearance = NanheAppearance.mini;
    }
  }

  void _syncAudioControllerWithState() {
    widget.audioController.setMusicVolume(_musicVolume);
    widget.audioController.setSoundEffectVolume(_soundEffectVolume);
    widget.audioController.setVoiceVolume(_voiceVolume);
    unawaited(widget.audioController.changeBgm(_selectedBgm));
  }

  int _jsonInt(Map<String, dynamic> source, String key, int fallback) {
    final value = source[key];
    return value is num ? value.round() : fallback;
  }

  double _jsonDouble(Map<String, dynamic> source, String key, double fallback) {
    final value = source[key];
    return value is num ? value.toDouble() : fallback;
  }

  bool _jsonBool(Map<String, dynamic> source, String key, bool fallback) {
    final value = source[key];
    return value is bool ? value : fallback;
  }

  String _jsonString(Map<String, dynamic> source, String key, String fallback) {
    final value = source[key];
    return value is String ? value : fallback;
  }

  List<String> _jsonStringList(
    Map<String, dynamic> source,
    String key,
    List<String> fallback,
  ) {
    final value = source[key];
    if (value is! List) return fallback;
    return value.whereType<String>().toList();
  }

  List<_LolMatchRecord> _jsonLolMatchHistory(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (entry) => _LolMatchRecord.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .take(10)
        .toList();
  }

  List<_PpChatMessage> _jsonPpMessages(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key];
    if (value is! List) return List.of(_initialPpMessages);
    return value
        .whereType<Map>()
        .map(
          (entry) => _PpChatMessage.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((message) => message.text.isNotEmpty)
        .toList();
  }

  YardHomeTier _yardHomeFromName(String name) {
    return YardHomeTier.values.firstWhere(
      (tier) => tier.name == name,
      orElse: () => YardHomeTier.box,
    );
  }

  HomeRoom _homeRoomFromName(String name) {
    return HomeRoom.values.firstWhere(
      (room) => room.name == name,
      orElse: () => HomeRoom.bedroom,
    );
  }

  CompanionLocation _companionLocationFromName(String name) {
    return CompanionLocation.values.firstWhere(
      (location) => location.name == name,
      orElse: () => CompanionLocation.garden,
    );
  }

  NanheAppearance _nanheAppearanceFromName(String name) {
    return NanheAppearance.values.firstWhere(
      (appearance) => appearance.name == name,
      orElse: () => NanheAppearance.mini,
    );
  }

  GrowthStage _growthStageFromName(String name) {
    return GrowthStage.values.firstWhere(
      (stage) => stage.name == name,
      orElse: () => GrowthStage.mini,
    );
  }

  BgmTrack _bgmFromName(String name) {
    return BgmTrack.values.firstWhere(
      (track) => track.name == name,
      orElse: () => BgmTrack.cozyNanhe2,
    );
  }

  bool get _isExhausted => _energy <= 0;
  bool get _isMidnight => _minuteOfDay >= _midnightMinute;
  bool get _isForcedSleep =>
      !_sickEndingCareActive && (_isExhausted || _isMidnight);
  bool get _canSleepByTime => _minuteOfDay >= _sleepAvailableMinute;
  bool get _isTired => _energy <= max(1, (_maxEnergy * 0.35).ceil());
  bool get _hasHighPressure => _pressure >= 70;
  bool get _hasLowTrust => _trustLevel == 1 && _trustProgress < 20;
  bool get _hasHighTrust => _trustLevel >= 2 || _trustProgress >= 70;
  bool get _hasHighAffection =>
      _affectionLevel >= 2 || _affectionProgress >= 50;
  bool get _hasLowAffection => _affectionLevel < 2;
  bool get _isDirty => _cleanliness <= 35;
  bool get _isDead => _healthValue <= 0;
  bool get _isSick => !_isDead && (_cleanliness <= 20 || _healthValue < 30);
  bool get _isInjured => _injury >= 10;
  bool get _isFatigued => _isExhausted || _exhaustionCount >= 2;
  bool get _isVeryHealthy =>
      !_isDead && !_isInjured && !_isSick && !_isFatigued && _healthValue >= 90;
  bool get _isSubHealthy =>
      !_isDead &&
      !_isInjured &&
      !_isSick &&
      !_isFatigued &&
      _healthValue >= 50 &&
      _healthValue < 70;
  bool get _isUnhealthy =>
      !_isDead &&
      !_isInjured &&
      !_isSick &&
      !_isFatigued &&
      _healthValue >= 30 &&
      _healthValue < 50;
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
      _growthStage == GrowthStage.mini &&
      !_sickEndingOnsetTriggered &&
      _totalDaysTogether > 60 &&
      _luxuryUnlocked;
  bool get _canTriggerSickEnding =>
      !_sickEndingOnsetTriggered &&
      !_deathEndingReached &&
      !_luxuryUnlocked &&
      _hasSickEndingRoute &&
      _totalDaysTogether == 60 &&
      (_minuteOfDay >= _sickEndingTriggerMinute || _isExhausted);
  bool get _isPreEvolutionPeriod =>
      _growthStage == GrowthStage.mini && _totalDaysTogether <= 60;
  bool get _isBondLocked =>
      _bondLockedByPreEvolutionHit && _isPreEvolutionPeriod;
  bool get _hasSickEndingRoute =>
      _bondLockedByPreEvolutionHit ||
      (_feedEventCompleted && !_feedEventResolvedCorrectly) ||
      (_sicknessEventCompleted && !_sicknessEventResolvedCorrectly);
  bool get _isEndingReached => _deathEndingReached || _isDead;
  bool get _hasUnlockedChildhoodRoutine =>
      _growthStage == GrowthStage.childhood && _homeInteriorUnlocked;
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
    if (_homeInteriorUnlocked) ...{
      'home-bedroom',
      'home-living-room',
      'home-study',
    },
  };
  Set<String> get _unlockedMemoryIds => {
    ..._permanentMemoryIds,
    'opening-memory',
    if (_feedEventCompleted) 'first-feeding-memory',
    if (_sicknessEventCompleted) 'day-seven-sickness-memory',
    if (_doghouseUnlocked) 'doghouse-unlock-memory',
    if (_luxuryUnlocked) 'luxury-unlock-memory',
    if (_homeBedtimeStoryCompleted) 'home-bedtime-memory',
    if (_firstHitEventTriggered) 'first-abuse-memory',
  };
  Set<String> get _unlockedAchievementIds => {
    ..._permanentAchievementIds,
    'rainy-day',
    if (_feedEventResolvedCorrectly) 'curry-favorite',
    if (_sicknessEventCompleted && !_sicknessEventResolvedCorrectly)
      'hot-water-cure',
    if (_hitCount >= _deathHitThreshold || _deathPending) 'roadside-one',
    if (_homeBedtimeStoryCompleted) 'home-sweet-home',
  };
  int get _maxEnergy {
    final enduranceBonus =
        (_endurance - _minStatValue) ~/ _endurancePerMaxEnergy;
    final baseMaxEnergy = _initialMaxEnergy + enduranceBonus;
    if (_isFatigued) return max(1, baseMaxEnergy ~/ 2);
    if (_isVeryHealthy) return max(1, (baseMaxEnergy * 1.5).floor());
    return _clampStat(baseMaxEnergy);
  }

  String get _timeLabel {
    return _formatMinuteLabel(_minuteOfDay);
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

  String get _backgroundAsset {
    if (_isViewingHome) {
      final room = switch (_homeRoom) {
        HomeRoom.bedroom => 'bedroom',
        HomeRoom.livingRoom => 'living_room',
        HomeRoom.study => 'study',
      };
      return homeBackgroundAsset(room: room, timeOfDay: _timeOfDayAssetKey);
    }
    return yardBackgroundAsset(
      home: _yardHomeTier.name,
      season: _seasonAssetKey,
      timeOfDay: _timeOfDayAssetKey,
    );
  }

  bool get _isViewingHome =>
      _homeInteriorUnlocked && _companionLocation == CompanionLocation.home;

  int get _backgroundCount =>
      _isViewingHome ? HomeRoom.values.length : _unlockedYardHomes.length;

  void _changeBackground(int direction) {
    if (_isViewingHome) {
      final currentIndex = HomeRoom.values.indexOf(_homeRoom);
      final nextIndex =
          (currentIndex + direction + HomeRoom.values.length) %
          HomeRoom.values.length;
      setState(() => _homeRoom = HomeRoom.values[nextIndex]);
      return;
    }
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
    _cancelStatPopupTimers();
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
    if (_isDead) return ['死亡'];
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

  String get _characterAsset {
    if (_isEndingReached) return miniNanheDeadAsset;
    if (_selectedAppearance == NanheAppearance.childhood &&
        _growthStage == GrowthStage.childhood) {
      return switch (_currentEmotion) {
        NanheEmotion.happy => childNanheHappyAsset,
        NanheEmotion.affectionate => childNanheAffectionateAsset,
        NanheEmotion.curious => childNanheCuriousAsset,
        NanheEmotion.sleepy => childNanheSleepyAsset,
        NanheEmotion.sad => childNanheSadAsset,
        NanheEmotion.angry => childNanheAngryAsset,
        NanheEmotion.frustrated => childNanheFrustratedAsset,
        NanheEmotion.calm => childNanheAsset,
      };
    }
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

  void _clampEnergyToMax() {
    _energy = _energy.clamp(0, _maxEnergy);
  }

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

  void _queueStatPopups(List<_StatPopup> popups) {
    if (popups.isEmpty) return;
    _statPopups.addAll(popups);
    if (_statPopups.length > 3) {
      _statPopups.removeRange(0, _statPopups.length - 3);
    }
    for (final popup in popups) {
      late final Timer timer;
      timer = Timer(const Duration(seconds: 2), () {
        _statPopupTimers.remove(timer);
        if (!mounted) return;
        setState(() {
          _statPopups.removeWhere((item) => item.id == popup.id);
        });
      });
      _statPopupTimers.add(timer);
    }
  }

  void _cancelStatPopupTimers() {
    for (final timer in _statPopupTimers) {
      timer.cancel();
    }
    _statPopupTimers.clear();
  }

  int _healthEnergyCostMultiplier({required bool isPhysicalAction}) {
    var multiplier = 1;
    if (_isSick) multiplier *= 2;
    if (_isInjured && isPhysicalAction) multiplier *= 3;
    if (_isSubHealthy && _random.nextDouble() < 0.25) multiplier *= 2;
    if (_isUnhealthy && _random.nextDouble() < 0.5) multiplier *= 2;
    return multiplier;
  }

  int _healthPressureGainMultiplier({required bool isPhysicalAction}) {
    var multiplier = 1;
    if (_isSick) multiplier *= 2;
    if (_isFatigued) multiplier *= 2;
    if (_isInjured && isPhysicalAction) multiplier *= 2;
    if (_isUnhealthy && _random.nextDouble() < 0.5) multiplier *= 2;
    return multiplier;
  }

  int _effectivePressureDelta(
    int pressureDelta, {
    required bool isPhysicalAction,
  }) {
    if (pressureDelta <= 0) return pressureDelta;
    return pressureDelta *
        _healthPressureGainMultiplier(isPhysicalAction: isPhysicalAction);
  }

  int _effectiveEnergyDelta(int energyDelta, {required bool isPhysicalAction}) {
    if (energyDelta >= 0) return energyDelta;
    final baseCost = -energyDelta;
    final healthMultiplier = _healthEnergyCostMultiplier(
      isPhysicalAction: isPhysicalAction,
    );
    final pressureMultiplier = 1 + (_pressure / 100);
    return -(baseCost * healthMultiplier * pressureMultiplier).ceil();
  }

  int _effectiveActionDuration(
    int durationMinutes, {
    required bool canEndEarly,
  }) {
    if (!canEndEarly || durationMinutes <= 0) return durationMinutes;
    final startMinute = _minuteOfDay;
    var effectiveDuration = min(durationMinutes, _midnightMinute - startMinute);
    final daySevenSicknessInRange =
        !_daySevenSicknessTriggered &&
        _totalDaysTogether == 7 &&
        startMinute < _daySevenSickMinute &&
        startMinute + durationMinutes > _daySevenSickMinute;
    if (daySevenSicknessInRange) {
      effectiveDuration = min(
        effectiveDuration,
        _daySevenSickMinute - startMinute,
      );
    }
    final sickEndingInRange =
        !_sickEndingOnsetTriggered &&
        !_deathEndingReached &&
        !_luxuryUnlocked &&
        _hasSickEndingRoute &&
        _totalDaysTogether == 60 &&
        startMinute < _sickEndingTriggerMinute &&
        startMinute + durationMinutes > _sickEndingTriggerMinute;
    if (sickEndingInRange) {
      effectiveDuration = min(
        effectiveDuration,
        _sickEndingTriggerMinute - startMinute,
      );
    }
    return max(0, effectiveDuration);
  }

  void _settleExhaustedTimedStory() {
    if (_energy > 0 ||
        _deathPending ||
        _deathEndingReached ||
        _sickEndingOnsetTriggered ||
        _sickEndingCareActive ||
        _sicknessStoryPending) {
      return;
    }

    if (!_daySevenSicknessTriggered &&
        _totalDaysTogether == 7 &&
        _minuteOfDay < _daySevenSickMinute) {
      _minuteOfDay = _daySevenSickMinute;
      _applyTimedEvents();
    }
  }

  void _applyHealthDeathIfNeeded() {
    if (_healthValue > 0 ||
        _deathEndingReached ||
        _sickEndingCareActive ||
        _sickEndingOnsetStoryPending ||
        _sickEndingFinalStoryPending ||
        _showingSickEndingOnsetStory ||
        _showingSickEndingFinalStory) {
      return;
    }
    _deathEndingReached = true;
    _reaction = null;
    _isReacting = false;
    _selectedDestination = 0;
  }

  List<_StatPopup> _buildStatPopups({
    required int moneyDelta,
    required int strengthDelta,
    required int intelligenceDelta,
    required int charmDelta,
    required int artDelta,
    required int skillDelta,
    required int enduranceDelta,
  }) {
    final deltas = <String, int>{
      '金钱': moneyDelta,
      '力量': strengthDelta,
      '智力': intelligenceDelta,
      '魅力': charmDelta,
      '艺术': artDelta,
      '技巧': skillDelta,
      '耐力': enduranceDelta,
    };
    return [
      for (final entry in deltas.entries)
        if (entry.value != 0)
          _StatPopup(
            id: _nextStatPopupId++,
            label: '${entry.key}${entry.value > 0 ? '+' : ''}${entry.value}',
          ),
    ];
  }

  void _applyAction(
    List<CharacterReaction> responses, {
    int energyDelta = -1,
    int moneyDelta = 0,
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
    bool advancesTime = true,
    int durationMinutes = _minutesPerInteraction,
    bool canEndEarlyForTimedStory = false,
    bool settleExhaustedTimedStory = true,
    bool isPhysicalAction = false,
    Duration voiceDelay = const Duration(milliseconds: 90),
  }) {
    if (_sleepPending) return;

    final actualEnergyDelta = _effectiveEnergyDelta(
      energyDelta,
      isPhysicalAction: isPhysicalAction,
    );
    final actualPressureDelta = _effectivePressureDelta(
      pressureDelta,
      isPhysicalAction: isPhysicalAction,
    );

    if (actualEnergyDelta < 0 && _isForcedSleep) {
      setState(() => _reaction = exhaustedReaction);
      widget.audioController.playVoice(exhaustedReaction.voice);
      return;
    }

    final actualDurationMinutes = advancesTime
        ? _effectiveActionDuration(
            durationMinutes,
            canEndEarly: canEndEarlyForTimedStory,
          )
        : 0;

    final reaction = _pickReaction(responses);

    setState(() {
      _changeAffection(affectionDelta);
      _changeTrust(trustDelta);
      _pressure = _clampPercent(_pressure + actualPressureDelta);
      _cleanliness = _clampPercent(_cleanliness + cleanlinessDelta);
      _healthValue = _clampPercent(_healthValue + healthDelta);
      _injury = _clampPercent(_injury + injuryDelta);
      final previousMoney = _money;
      final previousStrength = _strength;
      final previousIntelligence = _intelligence;
      final previousCharm = _charm;
      final previousArt = _art;
      final previousSkill = _skill;
      final previousEndurance = _endurance;
      _strength = _clampStat(_strength + strengthDelta);
      _intelligence = _clampStat(_intelligence + intelligenceDelta);
      _charm = _clampStat(_charm + charmDelta);
      _art = _clampStat(_art + artDelta);
      _skill = _clampStat(_skill + skillDelta);
      _endurance = _clampStat(_endurance + enduranceDelta);
      _money = max(0, _money + moneyDelta);
      _energy = (_energy + actualEnergyDelta).clamp(0, _maxEnergy);
      if (advancesTime) _advanceMinutes(actualDurationMinutes);
      _applyTimedEvents();
      if (settleExhaustedTimedStory) _settleExhaustedTimedStory();
      _applyHealthDeathIfNeeded();
      _queueProgressionUnlocks();
      if (!_deathEndingReached) {
        _queueStatPopups(
          _buildStatPopups(
            moneyDelta: _money - previousMoney,
            strengthDelta: _strength - previousStrength,
            intelligenceDelta: _intelligence - previousIntelligence,
            charmDelta: _charm - previousCharm,
            artDelta: _art - previousArt,
            skillDelta: _skill - previousSkill,
            enduranceDelta: _endurance - previousEndurance,
          ),
        );
        _reaction = reaction;
        _isReacting = true;
      }
    });
    if (!_deathEndingReached) {
      widget.audioController.playVoice(reaction.voice, delay: voiceDelay);
    }

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
      settleExhaustedTimedStory: false,
      isPhysicalAction: true,
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

  Future<void> _handleEvolution() async {
    if (!_canShowEvolutionButton || _showingEvolutionStory) return;

    widget.audioController.playPageTurn();
    _showingEvolutionStory = true;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return EvolutionStoryScreen(
            config: const EvolutionStoryConfig(
              fromName: '迷你南河',
              toName: '小南河',
              fromAsset: miniNanheHappyAsset,
              toAsset: childNanheAsset,
              resultText: '恭喜，迷你南河进化为了小南河',
            ),
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
    final reaction = const CharacterReaction(
      emotion: NanheEmotion.happy,
      nanheSpeech: '南河会自己走了。',
      meaning: '幼年期开始了。',
      voice: NanheVoice.affectionDouble,
    );
    setState(() {
      _showingEvolutionStory = false;
      _growthStage = GrowthStage.childhood;
      _selectedAppearance = NanheAppearance.childhood;
      _energy = _maxEnergy;
      _healthValue = max(_healthValue, 85);
      _cleanliness = max(_cleanliness, 80);
      _pressure = _clampPercent(_pressure - 10);
      _sleepPending = false;
      _reaction = reaction;
      _isReacting = true;
      _selectedDestination = 0;
    });
    widget.audioController.playVoice(reaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _advanceOneDay() {
    _day += 1;
    if (_day > _daysInMonth[_month - 1]) {
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

  void _applyTimedEvents({bool showStory = true}) {
    if (!_daySevenSicknessTriggered &&
        _totalDaysTogether == 7 &&
        _minuteOfDay >= _daySevenSickMinute) {
      _daySevenSicknessTriggered = true;
      _sicknessStoryPending = showStory;
      _healthValue = max(10, _healthValue < 30 ? _healthValue - 5 : 25);
      _pressure = _clampPercent(_pressure + 12);
      _reaction = null;
      _isReacting = false;
      if (showStory) _scheduleSicknessStory();
    }
    if (_canTriggerSickEnding) {
      _sickEndingOnsetTriggered = true;
      _sickEndingOnsetStoryPending = showStory;
      _healthValue = min(_healthValue, 5);
      _pressure = _clampPercent(_pressure + 20);
      _energy = min(_energy, 1);
      _yardHomeTier = _doghouseUnlocked
          ? YardHomeTier.doghouse
          : YardHomeTier.box;
      _selectedDestination = 0;
      _reaction = null;
      _isReacting = false;
      if (showStory) _scheduleSickEndingOnsetStory();
    }
  }

  void _scheduleSicknessStory() {
    if (!_sicknessStoryPending || _showingSicknessStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sicknessStoryPending || _showingSicknessStory) return;
      _showSicknessStory();
    });
  }

  void _scheduleSickEndingOnsetStory() {
    if (!_sickEndingOnsetStoryPending || _showingSickEndingOnsetStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_sickEndingOnsetStoryPending ||
          _showingSickEndingOnsetStory) {
        return;
      }
      _showSickEndingOnsetStory();
    });
  }

  void _scheduleSickEndingFinalStory() {
    if (!_sickEndingFinalStoryPending || _showingSickEndingFinalStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_sickEndingFinalStoryPending ||
          _showingSickEndingFinalStory) {
        return;
      }
      _showSickEndingFinalStory();
    });
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
      _doghouseUnlockStoryPending = true;
      _yardHomeTier = YardHomeTier.doghouse;
      _permanentDecorationIds.add('yard-doghouse');
      _permanentMemoryIds.add('doghouse-unlock-memory');
      _scheduleDoghouseUnlockStory();
    }
    if (_luxuryUnlockPending) {
      _luxuryUnlockPending = false;
      _luxuryUnlocked = true;
      _luxuryUnlockStoryPending = true;
      _yardHomeTier = YardHomeTier.luxury;
      _permanentDecorationIds.add('yard-luxury');
      _permanentMemoryIds.add('luxury-unlock-memory');
      _changeAffection(100);
      _changeTrust(100);
      _scheduleLuxuryUnlockStory();
    }
    if (!_unlockedYardHomes.contains(_yardHomeTier)) {
      _yardHomeTier = _unlockedYardHomes.last;
    }
  }

  void _scheduleDoghouseUnlockStory() {
    if (!_doghouseUnlockStoryPending || _showingDoghouseUnlockStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_doghouseUnlockStoryPending ||
          _showingDoghouseUnlockStory) {
        return;
      }
      _showDoghouseUnlockStory();
    });
  }

  void _scheduleLuxuryUnlockStory() {
    if (!_luxuryUnlockStoryPending || _showingLuxuryUnlockStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_luxuryUnlockStoryPending || _showingLuxuryUnlockStory) {
        return;
      }
      _showLuxuryUnlockStory();
    });
  }

  void _requestSleep() {
    if (_sleepPending) return;

    if (_canTriggerSickEnding) {
      setState(() => _applyTimedEvents());
      return;
    }

    if (!_isForcedSleep && !_canSleepByTime) {
      setState(() => _reaction = tooEarlyToSleepReaction);
      return;
    }

    if (_growthStage == GrowthStage.childhood &&
        _luxuryUnlocked &&
        !_homeBedtimeStoryCompleted &&
        !_showingHomeBedtimeStory) {
      unawaited(_showHomeBedtimeStory(startSleepAfter: true));
      return;
    }

    _beginSleep();
  }

  void _beginSleep() {
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

  Future<void> _showHomeBedtimeStory({bool startSleepAfter = false}) async {
    if (_showingHomeBedtimeStory) return;
    _showingHomeBedtimeStory = true;
    unawaited(_precacheStoryAssets(homeBedtimeStoryAssets));

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return HomeBedtimeStoryScreen(
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
    setState(() {
      _showingHomeBedtimeStory = false;
      _homeBedtimeStoryCompleted = true;
      _permanentMemoryIds.add('home-bedtime-memory');
      _permanentAchievementIds.add('home-sweet-home');
    });
    if (startSleepAfter) _beginSleep();
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
      if (_homeBedtimeStoryCompleted && !_homeInteriorUnlocked) {
        _homeInteriorUnlocked = true;
        _homeRoom = HomeRoom.bedroom;
        _companionLocation = CompanionLocation.home;
        _permanentDecorationIds.addAll({
          'home-bedroom',
          'home-living-room',
          'home-study',
        });
      }
      _minuteOfDay = wakeMinute;
      _pressure = _clampPercent(_pressure - 4);
      _healthValue = _clampPercent(_healthValue + 3);
      _injury = _clampPercent(_injury - 2);
      _exhaustionCount = sleptFromExhaustion
          ? _clampPercent(_exhaustionCount + 1)
          : _clampPercent(_exhaustionCount - 1);
      _energy = 1;
      _energy = _maxEnergy;
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
    );
  }

  void _pet() {
    _applyAction(
      _contextualResponses(ReactionAction.pet),
      energyDelta: -1,
      affectionDelta: _affectionGainPerInteraction,
      trustDelta: 1,
      pressureDelta: -2,
    );
  }

  void _play() {
    _applyAction(
      _contextualResponses(ReactionAction.play),
      energyDelta: -2,
      affectionDelta: 2,
      trustDelta: 1,
      pressureDelta: -4,
      isPhysicalAction: true,
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
      isPhysicalAction: true,
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
      _energy = (_energy - 1).clamp(0, _maxEnergy);
      _advanceMinutes(_minutesPerInteraction);
      _applyTimedEvents();
      _settleExhaustedTimedStory();
      _applyHealthDeathIfNeeded();
      _queueProgressionUnlocks();
      _reaction = reaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(reaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  Future<void> _showSicknessStory() async {
    if (_showingSicknessStory || !_sicknessStoryPending) return;
    _showingSicknessStory = true;
    _sicknessStoryPending = false;

    unawaited(_precacheStoryAssets(sicknessStoryAssets));
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return SicknessStoryScreen(
            onFinished: (storyContext, choice) {
              Navigator.of(storyContext).pop();
              _resolveSicknessEvent(choice);
            },
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (mounted) _showingSicknessStory = false;
  }

  Future<void> _showSickEndingOnsetStory() async {
    if (_showingSickEndingOnsetStory || !_sickEndingOnsetStoryPending) return;
    _showingSickEndingOnsetStory = true;
    _sickEndingOnsetStoryPending = false;

    unawaited(_precacheStoryAssets(sickEndingStoryAssets));
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return SickEndingStoryScreen(
            assets: sickEndingOnsetStoryAssets,
            panelCounts: const [3, 3],
            tapAreaKey: const Key('sick-ending-onset-story-tap-area'),
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
    setState(() {
      _showingSickEndingOnsetStory = false;
      _sickEndingCareActive = true;
      _selectedDestination = 0;
      _reaction = _sickEndingCareReactions.first;
      _isReacting = false;
    });
    widget.audioController.playVoice(_sickEndingCareReactions.first.voice);
  }

  Future<void> _showSickEndingFinalStory() async {
    if (_showingSickEndingFinalStory || !_sickEndingFinalStoryPending) return;
    _showingSickEndingFinalStory = true;
    _sickEndingFinalStoryPending = false;

    unawaited(_precacheStoryAssets(sickEndingFinalStoryAssets));
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return SickEndingStoryScreen(
            assets: sickEndingFinalStoryAssets,
            panelCounts: const [3, 2, 1],
            tapAreaKey: const Key('sick-ending-final-story-tap-area'),
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
    setState(() {
      _showingSickEndingFinalStory = false;
      if (_minuteOfDay >= _midnightMinute) {
        _advanceOneDay();
        _totalDaysTogether += 1;
      }
      _minuteOfDay = _earliestWakeMinute;
      _sickEndingCareActive = false;
      _deathEndingReached = true;
      _healthValue = 0;
      _permanentMemoryIds.add('sick-ending-memory');
      _permanentAchievementIds.add('sick-death');
      _reaction = null;
      _isReacting = false;
      _selectedDestination = 0;
    });
  }

  void _resolveSicknessEvent(SicknessStoryChoice choice) {
    final isCorrectChoice = choice == SicknessStoryChoice.attentiveCare;
    final reaction = isCorrectChoice
        ? const CharacterReaction(
            emotion: NanheEmotion.happy,
            nanheSpeech: '南河……南河。',
            meaning: '好像已经不难受了。',
            voice: NanheVoice.affectionDouble,
          )
        : const CharacterReaction(
            emotion: NanheEmotion.calm,
            nanheSpeech: '南河……',
            meaning: '烧退了，但是还有一点没精神。',
            voice: NanheVoice.calmSingle,
          );

    setState(() {
      _sicknessEventCompleted = true;
      _sicknessEventResolvedCorrectly = isCorrectChoice;
      _permanentMemoryIds.add('day-seven-sickness-memory');
      if (!isCorrectChoice) {
        _permanentAchievementIds.add('hot-water-cure');
      }
      if (isCorrectChoice) {
        _changeAffection(100);
        _changeTrust(100);
      }
      _advanceOneDay();
      _totalDaysTogether += 1;
      _applyNextDayUnlocks();
      _minuteOfDay = _earliestWakeMinute;
      _energy = _maxEnergy;
      _healthValue = max(_healthValue, isCorrectChoice ? 80 : 50);
      _cleanliness = max(_cleanliness, 55);
      _injury = _clampPercent(_injury - 5);
      _pressure = _clampPercent(_pressure + (isCorrectChoice ? -12 : 4));
      _exhaustionCount = 0;
      _sleepPending = false;
      _reaction = reaction;
      _isReacting = true;
      _queueProgressionUnlocks();
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
      energyDelta: 2,
      pressureDelta: -3,
      healthDelta: 1,
    );
  }

  void _study() {
    _applyAction(
      _contextualResponses(ReactionAction.study),
      energyDelta: -8,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: 6,
      intelligenceDelta: 1,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
    );
  }

  void _exercise() {
    _applyAction(
      _contextualResponses(ReactionAction.exercise),
      energyDelta: -12,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: 8,
      cleanlinessDelta: -8,
      healthDelta: 1,
      strengthDelta: 1,
      enduranceDelta: 1,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
      isPhysicalAction: true,
    );
  }

  void _game() {
    _applyAction(
      _contextualResponses(ReactionAction.game),
      energyDelta: -8,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: 4,
      cleanlinessDelta: -3,
      skillDelta: 1,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
    );
  }

  void _create() {
    _applyAction(
      _contextualResponses(ReactionAction.create),
      energyDelta: -8,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: 2,
      artDelta: 1,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
    );
  }

  void _perform() {
    _applyAction(
      _contextualResponses(ReactionAction.perform),
      energyDelta: -8,
      affectionDelta: 1,
      trustDelta: 1,
      pressureDelta: 8,
      charmDelta: 1,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
      isPhysicalAction: true,
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

  void _chores() {
    if (_lastChoresDay == _totalDaysTogether) return;
    final canStart = !_sleepPending && !_isForcedSleep;
    _applyAction(
      _contextualResponses(ReactionAction.chores),
      energyDelta: -8,
      moneyDelta: 10,
      durationMinutes: _minutesPerTraining,
      canEndEarlyForTimedStory: true,
      isPhysicalAction: true,
    );
    if (canStart) {
      setState(() => _lastChoresDay = _totalDaysTogether);
    }
  }

  void _careSickEnding() {
    if (!_sickEndingCareActive || _deathEndingReached) return;
    final reaction =
        _sickEndingCareReactions[_random.nextInt(
          _sickEndingCareReactions.length,
        )];
    setState(() {
      _minuteOfDay = min(
        _minuteOfDay + _minutesPerInteraction,
        _postMidnightSickEndingMinute,
      );
      _healthValue = min(_healthValue, 5);
      _pressure = _clampPercent(
        _pressure + _effectivePressureDelta(1, isPhysicalAction: false),
      );
      _reaction = reaction;
      _isReacting = true;
      if (_minuteOfDay >= _postMidnightSickEndingMinute) {
        _sickEndingCareActive = false;
        _sickEndingFinalStoryPending = true;
        _reaction = null;
        _isReacting = false;
        _scheduleSickEndingFinalStory();
      }
    });
    if (_sickEndingCareActive) {
      widget.audioController.playVoice(reaction.voice);
      Future<void>.delayed(const Duration(milliseconds: 170), () {
        if (mounted) setState(() => _isReacting = false);
      });
    }
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
    if (_selectedDestination == 2 &&
        _phoneNavigationLocked &&
        index != _selectedDestination) {
      return;
    }
    setState(() {
      _selectedDestination = index;
      if (index != 2) _phoneNavigationLocked = false;
    });
  }

  LolHealthCondition get _lolHealthCondition {
    if (_isSick || _healthValue < 30) return LolHealthCondition.sick;
    if (_healthValue < 50) return LolHealthCondition.unhealthy;
    if (_healthValue < 70) return LolHealthCondition.subHealthy;
    if (_healthValue < 90) return LolHealthCondition.healthy;
    return LolHealthCondition.veryHealthy;
  }

  int _lolRankProgressIndex(LolRankPosition position) {
    if (position.tier == LolRankTier.challenger) return 30;
    if (position.tier == LolRankTier.grandmaster) return 29;
    if (position.tier == LolRankTier.master) return 28;
    return position.tier.index * 4 + position.division!.index;
  }

  String? _prepareLolRankedMatch() {
    if (_isMidnight) return '该睡觉了';
    if (_sleepPending ||
        _isEndingReached ||
        _pendingLolRankedEnergyCost != null) {
      return '有点累了，休息一会再玩吧';
    }
    final energyCost = -_effectiveEnergyDelta(-8, isPhysicalAction: false);
    if (_energy < energyCost) return '有点累了，休息一会再玩吧';
    _pendingLolRankedEnergyCost = energyCost;
    return null;
  }

  void _cancelPreparedLolRankedMatch() {
    _pendingLolRankedEnergyCost = null;
  }

  _LolMatchResult _resolveLolRankedMatch(double chance) {
    final beforePosition = LolRankPosition.fromTotalLp(_lolTotalLp);
    final won = _random.nextDouble() * 100 < chance;
    final lpDelta = LolRankRules.lpDeltaForRoll(
      won: won,
      roll: _random.nextInt(6),
    );
    final afterTotalLp = max(0, _lolTotalLp + lpDelta);
    final afterPosition = LolRankPosition.fromTotalLp(afterTotalLp);
    final beforeIndex = _lolRankProgressIndex(beforePosition);
    final afterIndex = _lolRankProgressIndex(afterPosition);
    final rankChangeLabel = afterIndex > beforeIndex
        ? '晋级'
        : afterIndex < beforeIndex
        ? '掉段'
        : '段位未变';
    final energyCost =
        _pendingLolRankedEnergyCost ??
        -_effectiveEnergyDelta(-8, isPhysicalAction: false);
    final durationMinutes = _effectiveActionDuration(
      _minutesPerTraining,
      canEndEarly: true,
    );

    setState(() {
      _pendingLolRankedEnergyCost = null;
      _energy = (_energy - energyCost).clamp(0, _maxEnergy);
      _advanceMinutes(durationMinutes);
      _lolTotalLp = afterTotalLp;
      _lolHistoricalPeakTotalLp = max(_lolHistoricalPeakTotalLp, _lolTotalLp);
      if (won) {
        _lolConsecutiveWins += 1;
        _lolConsecutiveLosses = 0;
        _pressure = _clampPercent(_pressure - _lolConsecutiveWins * 2);
      } else {
        _lolConsecutiveLosses += 1;
        _lolConsecutiveWins = 0;
        _pressure = _clampPercent(_pressure + _lolConsecutiveLosses * 2);
      }
      _lolMatchHistory.insert(0, _LolMatchRecord(won: won, lpDelta: lpDelta));
      if (_lolMatchHistory.length > 10) {
        _lolMatchHistory.removeRange(10, _lolMatchHistory.length);
      }
      _applyTimedEvents();
      _settleExhaustedTimedStory();
      _applyHealthDeathIfNeeded();
      _queueProgressionUnlocks();
    });

    return _LolMatchResult(
      won: won,
      lpDelta: lpDelta,
      afterPosition: afterPosition,
      rankChangeLabel: rankChangeLabel,
      consecutiveWins: _lolConsecutiveWins,
      consecutiveLosses: _lolConsecutiveLosses,
      reachedMidnight: _isMidnight,
    );
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

  void _replaySicknessStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(sicknessStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return SicknessStoryScreen(
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

  Future<void> _showDoghouseUnlockStory() async {
    if (_showingDoghouseUnlockStory || !_doghouseUnlockStoryPending) return;
    _showingDoghouseUnlockStory = true;
    _doghouseUnlockStoryPending = false;

    unawaited(_precacheStoryAssets(doghouseUnlockStoryAssets));
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return DoghouseUnlockStoryScreen(
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
    _showingDoghouseUnlockStory = false;
    await _showTrainingUnlockDialog();
  }

  Future<void> _showLuxuryUnlockStory() async {
    if (_showingLuxuryUnlockStory || !_luxuryUnlockStoryPending) return;
    _showingLuxuryUnlockStory = true;
    _luxuryUnlockStoryPending = false;

    unawaited(_precacheStoryAssets(luxuryUnlockStoryAssets));
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return LuxuryUnlockStoryScreen(
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
    _showingLuxuryUnlockStory = false;
  }

  Future<void> _showTrainingUnlockDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('训练页已解锁'),
          content: const Text('迷你南河有了新的住处，现在可以开始进行训练了。'),
          actions: [
            FilledButton(
              key: const Key('training-unlock-confirm-button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _replayDoghouseUnlockStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(doghouseUnlockStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return DoghouseUnlockStoryScreen(
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

  void _replayLuxuryUnlockStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(luxuryUnlockStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return LuxuryUnlockStoryScreen(
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

  void _replayHomeBedtimeStory() {
    widget.audioController.playPageTurn();
    unawaited(_precacheStoryAssets(homeBedtimeStoryAssets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return HomeBedtimeStoryScreen(
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

  void _replaySickEndingStory() {
    widget.audioController.playPageTurn();
    const assets = <String>[
      ...sickEndingOnsetStoryAssets,
      ...sickEndingFinalStoryAssets,
    ];
    unawaited(_precacheStoryAssets(assets));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) {
          return SickEndingStoryScreen(
            assets: assets,
            panelCounts: const [3, 3, 3, 2, 1],
            tapAreaKey: const Key('sick-ending-memory-story-tap-area'),
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
      _applyTimedEvents(showStory: false);
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

  void _setDebugTrustLevel(int value) {
    setState(() {
      _trustLevel = _clampStat(value);
      _trustProgress = _trustProgress.clamp(0, 99);
      _queueProgressionUnlocks();
    });
  }

  void _setDebugEvolutionReady() {
    setState(() {
      _setCalendarFromTotalDays(61);
      _minuteOfDay = _earliestWakeMinute;
      _growthStage = GrowthStage.mini;
      _yardHomeTier = YardHomeTier.luxury;
      _homeRoom = HomeRoom.bedroom;
      _companionLocation = CompanionLocation.garden;
      _selectedAppearance = NanheAppearance.mini;
      _hasBeenHit = false;
      _bondLockedByPreEvolutionHit = false;
      _deathPending = false;
      _deathEndingReached = false;
      _feedEventTriggered = true;
      _feedEventCompleted = true;
      _firstHitEventTriggered = false;
      _daySevenSicknessTriggered = true;
      _sicknessEventCompleted = true;
      _sicknessStoryPending = false;
      _showingSicknessStory = false;
      _sickEndingOnsetTriggered = false;
      _sickEndingOnsetStoryPending = false;
      _showingSickEndingOnsetStory = false;
      _sickEndingCareActive = false;
      _sickEndingFinalStoryPending = false;
      _showingSickEndingFinalStory = false;
      _doghouseUnlockPending = false;
      _doghouseUnlockStoryPending = false;
      _showingDoghouseUnlockStory = false;
      _doghouseUnlocked = true;
      _luxuryUnlockPending = false;
      _luxuryUnlockStoryPending = false;
      _showingLuxuryUnlockStory = false;
      _luxuryUnlocked = true;
      _showingEvolutionStory = false;
      _homeBedtimeStoryCompleted = false;
      _homeInteriorUnlocked = false;
      _showingHomeBedtimeStory = false;
      _permanentMemoryIds.remove('home-bedtime-memory');
      _permanentAchievementIds.remove('home-sweet-home');
      _permanentDecorationIds.remove('home-interior');
      _permanentDecorationIds.removeAll({
        'home-bedroom',
        'home-living-room',
        'home-study',
      });
      _feedEventResolvedCorrectly = true;
      _sicknessEventResolvedCorrectly = true;
      _permanentDecorationIds.addAll({'yard-doghouse', 'yard-luxury'});
      _permanentMemoryIds.addAll({
        'first-feeding-memory',
        'day-seven-sickness-memory',
        'doghouse-unlock-memory',
        'luxury-unlock-memory',
      });
      _permanentAchievementIds.add('curry-favorite');
      _affectionLevel = max(_affectionLevel, 8);
      _affectionProgress = 0;
      _trustLevel = max(_trustLevel, 4);
      _trustProgress = 0;
      _pressure = 0;
      _cleanliness = 100;
      _healthValue = 100;
      _injury = 0;
      _exhaustionCount = 0;
      _energy = _maxEnergy;
      _sleepPending = false;
      _reaction = null;
      _isReacting = false;
      _selectedDestination = 0;
    });
  }

  void _setCalendarFromTotalDays(int totalDaysTogether) {
    final clampedDays = totalDaysTogether.clamp(1, _maxStatValue);
    final zeroBasedDay = clampedDays - 1;
    _totalDaysTogether = clampedDays;
    _year = (zeroBasedDay ~/ _daysPerCommonYear) + 1;
    var remainingDay = zeroBasedDay % _daysPerCommonYear;
    _month = 1;
    while (remainingDay >= _daysInMonth[_month - 1]) {
      remainingDay -= _daysInMonth[_month - 1];
      _month += 1;
    }
    _day = remainingDay + 1;
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
      _money = 0;
      _lastChoresDay = -1;
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
      _growthStage = GrowthStage.mini;
      _yardHomeTier = YardHomeTier.box;
      _homeRoom = HomeRoom.bedroom;
      _companionLocation = CompanionLocation.garden;
      _selectedAppearance = NanheAppearance.mini;
      _hasBeenHit = false;
      _hitCount = 0;
      _bondLockedByPreEvolutionHit = false;
      _deathPending = false;
      _deathEndingReached = false;
      _feedEventTriggered = false;
      _feedEventCompleted = false;
      _firstHitEventTriggered = false;
      _daySevenSicknessTriggered = false;
      _sicknessEventCompleted = false;
      _sicknessStoryPending = false;
      _showingSicknessStory = false;
      _sickEndingOnsetTriggered = false;
      _sickEndingOnsetStoryPending = false;
      _showingSickEndingOnsetStory = false;
      _sickEndingCareActive = false;
      _sickEndingFinalStoryPending = false;
      _showingSickEndingFinalStory = false;
      _doghouseUnlockPending = false;
      _doghouseUnlockStoryPending = false;
      _showingDoghouseUnlockStory = false;
      _doghouseUnlocked = false;
      _luxuryUnlockPending = false;
      _luxuryUnlockStoryPending = false;
      _showingLuxuryUnlockStory = false;
      _luxuryUnlocked = false;
      _showingEvolutionStory = false;
      _homeBedtimeStoryCompleted = false;
      _homeInteriorUnlocked = false;
      _showingHomeBedtimeStory = false;
      _feedEventResolvedCorrectly = false;
      _sicknessEventResolvedCorrectly = false;
      _strength = 1;
      _intelligence = 1;
      _charm = 1;
      _art = 1;
      _skill = 1;
      _endurance = 1;
      _lolTotalLp = 0;
      _lolHistoricalPeakTotalLp = 0;
      _lolConsecutiveWins = 0;
      _lolConsecutiveLosses = 0;
      _lolMatchHistory.clear();
      _ppMessages
        ..clear()
        ..addAll(_initialPpMessages);
      _ppUnreadCount = _initialPpMessages.length;
      _phoneNavigationLocked = false;
      _showDebugTools = false;
      _cancelStatPopupTimers();
      _statPopups.clear();
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

  Future<void> _confirmStartNewGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重新开始？'),
          content: const Text('当前游戏进度将重新开始，但现有存档不会被删除。'),
          actions: [
            TextButton(
              key: const Key('restart-game-cancel-button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('restart-game-confirm-button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认重新开始'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _permanentMemoryIds
        ..clear()
        ..add('opening-memory');
      _permanentAchievementIds
        ..clear()
        ..add('rainy-day');
      _permanentDecorationIds
        ..clear()
        ..add('yard-box');
    });
    await _resetRunAndReplayOpening();
  }

  Future<void> _openLocationSelection() async {
    widget.audioController.playRegularInteraction();
    final location = await Navigator.of(context).push<CompanionLocation>(
      MaterialPageRoute(
        builder: (_) => _LocationSelectionPage(
          currentLocation: _companionLocation,
          homeUnlocked: _homeInteriorUnlocked,
        ),
      ),
    );
    if (!mounted || location == null) return;
    setState(() => _companionLocation = location);
  }

  Future<void> _openAppearanceSelection() async {
    widget.audioController.playRegularInteraction();
    final appearance = await Navigator.of(context).push<NanheAppearance>(
      MaterialPageRoute(
        builder: (_) => _AppearanceSelectionPage(
          currentAppearance: _selectedAppearance,
          childhoodUnlocked: _growthStage == GrowthStage.childhood,
        ),
      ),
    );
    if (!mounted || appearance == null) return;
    setState(() => _selectedAppearance = appearance);
  }

  void _updatePpConversation(List<_PpChatMessage> messages, int unreadCount) {
    setState(() {
      _ppMessages
        ..clear()
        ..addAll(messages);
      _ppUnreadCount = max(0, unreadCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selectedDestination) {
      1 => _StatusPage(
        growthStage: _growthStage,
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
        characterAsset: _characterAsset,
        strength: _strength,
        intelligence: _intelligence,
        charm: _charm,
        art: _art,
        skill: _skill,
        endurance: _endurance,
      ),
      2 => _PhoneShell(
        audioController: widget.audioController,
        skill: _skill,
        pressure: _pressure,
        healthCondition: _lolHealthCondition,
        injured: _isInjured,
        totalLp: _lolTotalLp,
        historicalPeakTotalLp: _lolHistoricalPeakTotalLp,
        consecutiveWins: _lolConsecutiveWins,
        consecutiveLosses: _lolConsecutiveLosses,
        matchHistory: List.unmodifiable(_lolMatchHistory),
        ppMessages: List.unmodifiable(_ppMessages),
        ppUnreadCount: _ppUnreadCount,
        onPpConversationChanged: _updatePpConversation,
        onPrepareRankedMatch: _prepareLolRankedMatch,
        onCancelPreparedRankedMatch: _cancelPreparedLolRankedMatch,
        onResolveMatch: _resolveLolRankedMatch,
        onNavigationLockChanged: (locked) {
          if (_phoneNavigationLocked == locked) return;
          setState(() => _phoneNavigationLocked = locked);
        },
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
        onReplaySicknessStory: _replaySicknessStory,
        onReplayDoghouseUnlockStory: _replayDoghouseUnlockStory,
        onReplayLuxuryUnlockStory: _replayLuxuryUnlockStory,
        onReplayHomeBedtimeStory: _replayHomeBedtimeStory,
        onReplayAbuseStory: _replayAbuseStory,
        onReplaySickEndingStory: _replaySickEndingStory,
        onPageTurn: widget.audioController.playPageTurn,
      ),
      5 => _SettingsPage(
        selectedBgm: _selectedBgm,
        musicVolume: _musicVolume,
        soundEffectVolume: _soundEffectVolume,
        voiceVolume: _voiceVolume,
        showDebugTools: _showDebugTools,
        saveSlots: _saveSlots,
        totalDaysTogether: _totalDaysTogether,
        minuteOfDay: _minuteOfDay,
        affectionLevel: _affectionLevel,
        trustLevel: _trustLevel,
        onMusicChanged: _setMusicVolume,
        onSoundEffectChanged: _setSoundEffectVolume,
        onVoiceChanged: _setVoiceVolume,
        onMusicMuteToggle: _toggleMusicMute,
        onSoundEffectMuteToggle: _toggleSoundEffectMute,
        onVoiceMuteToggle: _toggleVoiceMute,
        onBgmChanged: _changeBgm,
        onSaveSlot: _saveGameToSlot,
        onLoadSlot: _loadGameFromSlot,
        onExportSlot: _exportSaveSlot,
        onImportSave: _showImportSaveDialog,
        onRestartGame: _confirmStartNewGame,
        onVersionLongPress: () => setState(() => _showDebugTools = true),
        onDebugTimelineChanged: _setDebugTimeline,
        onDebugAffectionLevelChanged: _setDebugAffectionLevel,
        onDebugTrustLevelChanged: _setDebugTrustLevel,
        onDebugEvolutionReady: _setDebugEvolutionReady,
      ),
      _ => _CompanionPage(
        totalDaysTogether: _totalDaysTogether,
        growthStage: _growthStage,
        money: _money,
        childhoodRoutineUnlocked: _hasUnlockedChildhoodRoutine,
        season: _season,
        year: _year,
        month: _month,
        day: _day,
        timeLabel: _timeLabel,
        weatherLabel: _weatherLabel,
        weatherCondition: _isViewingHome
            ? WeatherCondition.sunny
            : _visibleWeatherCondition,
        backgroundAsset: _backgroundAsset,
        canSwitchBackground: _backgroundCount > 1,
        reaction: _reaction,
        isReacting: _isReacting,
        emotionLabel: _emotionLabel,
        characterAsset: _characterAsset,
        statPopups: List.unmodifiable(_statPopups),
        isEndingReached: _isEndingReached,
        isSickEndingCareActive: _sickEndingCareActive,
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
        onCareSickEnding: _careSickEnding,
        onEvolution: _handleEvolution,
        onPreviousBackground: () => _changeBackground(-1),
        onNextBackground: () => _changeBackground(1),
        onOpenLocationSelector: _openLocationSelection,
        onOpenAppearanceSelector: _openAppearanceSelection,
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
        onChores: _lastChoresDay == _totalDaysTogether
            ? null
            : () {
                widget.audioController.playRegularInteraction();
                _chores();
              },
        onOuting: () {
          _openLocationSelection();
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

class _PpConversationSnapshot {
  const _PpConversationSnapshot({
    required this.messages,
    required this.unreadCount,
  });

  final List<_PpChatMessage> messages;
  final int unreadCount;
}

class _PhoneShell extends StatefulWidget {
  const _PhoneShell({
    required this.audioController,
    required this.skill,
    required this.pressure,
    required this.healthCondition,
    required this.injured,
    required this.totalLp,
    required this.historicalPeakTotalLp,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.matchHistory,
    required this.ppMessages,
    required this.ppUnreadCount,
    required this.onPpConversationChanged,
    required this.onPrepareRankedMatch,
    required this.onCancelPreparedRankedMatch,
    required this.onResolveMatch,
    required this.onNavigationLockChanged,
  });

  final GameAudioController audioController;
  final int skill;
  final int pressure;
  final LolHealthCondition healthCondition;
  final bool injured;
  final int totalLp;
  final int historicalPeakTotalLp;
  final int consecutiveWins;
  final int consecutiveLosses;
  final List<_LolMatchRecord> matchHistory;
  final List<_PpChatMessage> ppMessages;
  final int ppUnreadCount;
  final void Function(List<_PpChatMessage>, int) onPpConversationChanged;
  final String? Function() onPrepareRankedMatch;
  final VoidCallback onCancelPreparedRankedMatch;
  final _LolMatchResult Function(double chance) onResolveMatch;
  final ValueChanged<bool> onNavigationLockChanged;

  @override
  State<_PhoneShell> createState() => _PhoneShellState();
}

class _PhoneShellState extends State<_PhoneShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _random = Random();
  bool _navigationLocked = false;
  late int _totalLp;
  late int _historicalPeakTotalLp;
  late int _consecutiveWins;
  late int _consecutiveLosses;
  late List<_LolMatchRecord> _matchHistory;
  late final ValueNotifier<_PpConversationSnapshot> _ppConversation;

  @override
  void initState() {
    super.initState();
    _syncRankedState();
    _ppConversation = ValueNotifier(
      _PpConversationSnapshot(
        messages: List.unmodifiable(widget.ppMessages),
        unreadCount: widget.ppUnreadCount,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _PhoneShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRankedState();
    _ppConversation.value = _PpConversationSnapshot(
      messages: List.unmodifiable(widget.ppMessages),
      unreadCount: widget.ppUnreadCount,
    );
  }

  @override
  void dispose() {
    _ppConversation.dispose();
    super.dispose();
  }

  void _syncRankedState() {
    _totalLp = widget.totalLp;
    _historicalPeakTotalLp = widget.historicalPeakTotalLp;
    _consecutiveWins = widget.consecutiveWins;
    _consecutiveLosses = widget.consecutiveLosses;
    _matchHistory = List.of(widget.matchHistory);
  }

  void _setNavigationLocked(bool locked) {
    if (_navigationLocked == locked) return;
    setState(() => _navigationLocked = locked);
    widget.onNavigationLockChanged(locked);
  }

  void _returnToPhoneHome() {
    if (_navigationLocked) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _goBack() {
    if (_navigationLocked) return;
    _navigatorKey.currentState?.maybePop();
  }

  void _openZhangmeng() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => _buildZhangmengHome()),
    );
  }

  void _setPpConversation(List<_PpChatMessage> messages, int unreadCount) {
    final snapshot = _PpConversationSnapshot(
      messages: List.unmodifiable(messages),
      unreadCount: max(0, unreadCount),
    );
    _ppConversation.value = snapshot;
    widget.onPpConversationChanged(snapshot.messages, snapshot.unreadCount);
  }

  void _openPp() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _PpHomePage(
          conversation: _ppConversation,
          onOpenPatrick: _openPatrickChat,
        ),
      ),
    );
  }

  void _openPatrickChat() {
    final current = _ppConversation.value;
    if (current.unreadCount > 0) {
      _setPpConversation(current.messages, 0);
    }
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _PpChatPage(
          initialMessages: _ppConversation.value.messages,
          onReply: (message) {
            _setPpConversation(message, 0);
          },
        ),
      ),
    );
  }

  Widget _buildZhangmengHome() {
    return _ZhangmengHomePage(
      totalLp: _totalLp,
      historicalPeakTotalLp: _historicalPeakTotalLp,
      matchHistory: _matchHistory,
      onStartRanked: _openMatchFound,
      onOpenHistory: _openMatchHistory,
    );
  }

  void _returnToZhangmengHome() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => _buildZhangmengHome()),
    );
  }

  void _openMatchFound() {
    final blockedMessage = widget.onPrepareRankedMatch();
    if (blockedMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(blockedMessage)));
      return;
    }
    final position = LolRankPosition.fromTotalLp(_totalLp);
    final chance = LolRankRules.calculateWinChance(
      skill: widget.skill,
      position: position,
      pressure: widget.pressure,
      healthCondition: widget.healthCondition,
      injured: widget.injured,
      consecutiveWins: _consecutiveWins,
      consecutiveLosses: _consecutiveLosses,
      randomModifier: _random.nextDouble() * 10 - 5,
    );
    _setNavigationLocked(true);
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _ZhangmengMatchFoundPage(
          audioController: widget.audioController,
          position: position,
          winChanceLabel: LolRankRules.winChanceLabel(chance),
          onAccept: () => _acceptMatch(chance),
          onDecline: _declineMatch,
        ),
      ),
    );
  }

  void _acceptMatch(double chance) {
    final result = widget.onResolveMatch(chance);
    setState(() {
      _totalLp = max(0, _totalLp + result.lpDelta);
      _historicalPeakTotalLp = max(_historicalPeakTotalLp, _totalLp);
      _consecutiveWins = result.consecutiveWins;
      _consecutiveLosses = result.consecutiveLosses;
      _matchHistory.insert(
        0,
        _LolMatchRecord(won: result.won, lpDelta: result.lpDelta),
      );
      if (_matchHistory.length > 10) {
        _matchHistory.removeRange(10, _matchHistory.length);
      }
    });
    _setNavigationLocked(false);
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _ZhangmengResultPage(
          result: result,
          onContinueRanked: _openMatchFoundFromResult,
          onReturnHome: _returnToZhangmengHome,
        ),
      ),
    );
    if (result.reachedMidnight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('该睡觉了')));
      });
    }
  }

  void _openMatchFoundFromResult() {
    _navigatorKey.currentState?.pop();
    _openMatchFound();
  }

  void _declineMatch() {
    widget.onCancelPreparedRankedMatch();
    _setNavigationLocked(false);
    _navigatorKey.currentState?.pop();
  }

  void _openMatchHistory() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _ZhangmengHistoryPage(matchHistory: _matchHistory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Navigator(
          key: _navigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => _PhoneHomePage(
              ppConversation: _ppConversation,
              onOpenPp: _openPp,
              onOpenZhangmeng: _openZhangmeng,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _PhoneNavigationBar(
            onHome: _returnToPhoneHome,
            onBack: _goBack,
          ),
        ),
      ],
    );
  }
}

class _PhoneHomePage extends StatelessWidget {
  const _PhoneHomePage({
    required this.ppConversation,
    required this.onOpenPp,
    required this.onOpenZhangmeng,
  });

  final ValueListenable<_PpConversationSnapshot> ppConversation;
  final VoidCallback onOpenPp;
  final VoidCallback onOpenZhangmeng;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('phone-page'),
      decoration: const BoxDecoration(
        color: Color(0xFFB9D8F1),
        image: DecorationImage(
          image: AssetImage(phoneDemaciaGuardianWallpaperAsset),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        key: const Key('phone-empty-app-area'),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<_PpConversationSnapshot>(
                valueListenable: ppConversation,
                builder: (context, conversation, _) => _PhoneAppIcon(
                  key: const Key('phone-pp-app'),
                  assetName: phonePpIconAsset,
                  label: 'PP',
                  unreadCount: conversation.unreadCount,
                  onTap: onOpenPp,
                ),
              ),
              const SizedBox(width: 22),
              _PhoneAppIcon(
                key: const Key('phone-zhangmeng-app'),
                assetName: phoneZhangmengIconAsset,
                label: '掌盟',
                onTap: onOpenZhangmeng,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneAppIcon extends StatelessWidget {
  const _PhoneAppIcon({
    super.key,
    required this.assetName,
    required this.label,
    this.onTap,
    this.unreadCount = 0,
  });

  final String assetName;
  final String label;
  final VoidCallback? onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      assetName,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      key: const Key('phone-pp-unread'),
                      top: -6,
                      right: -7,
                      child: _UnreadBadge(count: unreadCount),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _PpHomePage extends StatelessWidget {
  const _PpHomePage({required this.conversation, required this.onOpenPatrick});

  final ValueListenable<_PpConversationSnapshot> conversation;
  final VoidCallback onOpenPatrick;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('pp-home-page'),
      color: const Color(0xFFF4F5F7),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8E9EB))),
              ),
              child: const Text(
                '消息',
                style: TextStyle(
                  color: Color(0xFF17191C),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ValueListenableBuilder<_PpConversationSnapshot>(
              valueListenable: conversation,
              builder: (context, snapshot, _) {
                final preview = snapshot.messages.isEmpty
                    ? '暂无消息'
                    : snapshot.messages.last.text;
                return Material(
                  color: Colors.white,
                  child: InkWell(
                    key: const Key('pp-friend-patrick'),
                    onTap: onOpenPatrick,
                    child: SizedBox(
                      height: 82,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const _PpPatrickAvatar(radius: 27),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _patrickPpContact.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF17191C),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF9A9DA3),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '刚刚',
                                  style: TextStyle(
                                    color: Color(0xFFB1B3B7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                if (snapshot.unreadCount > 0)
                                  _UnreadBadge(
                                    key: const Key('pp-friend-unread'),
                                    count: snapshot.unreadCount,
                                  )
                                else
                                  const SizedBox(height: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 82, color: Color(0xFFE8E9EB)),
            const Spacer(),
            const SizedBox(height: 76),
          ],
        ),
      ),
    );
  }
}

class _PpPatrickAvatar extends StatelessWidget {
  const _PpPatrickAvatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF1F2F4),
      backgroundImage: AssetImage(_patrickPpContact.avatarAsset),
    );
  }
}

class _PpNanheAvatar extends StatelessWidget {
  const _PpNanheAvatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      key: const Key('pp-nanhe-logo-avatar'),
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: const AssetImage(miniNanheOriginalAsset),
    );
  }
}

class _PpChatHeader extends StatelessWidget {
  const _PpChatHeader({required this.contact});

  final _PpContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E6E9))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17191C),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF20C77A),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 9, height: 9),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            contact.signature,
            key: const Key('pp-contact-signature'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8B8F96),
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PpChatPage extends StatefulWidget {
  const _PpChatPage({required this.initialMessages, required this.onReply});

  final List<_PpChatMessage> initialMessages;
  final ValueChanged<List<_PpChatMessage>> onReply;

  @override
  State<_PpChatPage> createState() => _PpChatPageState();
}

class _PpChatPageState extends State<_PpChatPage> {
  final _scrollController = ScrollController();
  late final List<_PpChatMessage> _messages;

  bool get _hasReplied => _messages.any((message) => message.isNanhe);

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.initialMessages);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _reply(String text) {
    if (_hasReplied) return;
    setState(() {
      _messages.add(_PpChatMessage(sender: _PpMessageSender.nanhe, text: text));
    });
    widget.onReply(List.unmodifiable(_messages));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('pp-chat-page'),
      color: const Color(0xFFF3F4F6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 76),
          child: Column(
            children: [
              const _PpChatHeader(contact: _patrickPpContact),
              Expanded(
                child: ListView.builder(
                  key: const Key('pp-chat-list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _PpMessageBubble(message: _messages[index]),
                ),
              ),
              if (!_hasReplied)
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    border: Border(top: BorderSide(color: Color(0xFFE3E5E8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('pp-reply-received'),
                          onPressed: () => _reply('收到'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1289F6),
                            side: const BorderSide(color: Color(0xFF65B6FF)),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('收到'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('pp-reply-understood'),
                          onPressed: () => _reply('明白'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1289F6),
                            side: const BorderSide(color: Color(0xFF65B6FF)),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('明白'),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: 52,
                padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E4E7))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('pp-input'),
                        enabled: false,
                        maxLines: 1,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '暂不支持输入文字',
                          hintStyle: const TextStyle(
                            color: Color(0xFFAAADB2),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F3F5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: Color(0xFF777B82),
                      size: 25,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PpMessageBubble extends StatelessWidget {
  const _PpMessageBubble({required this.message});

  final _PpChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isNanhe = message.isNanhe;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.67,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNanhe ? const Color(0xFFBDE5FF) : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        message.text,
        style: const TextStyle(
          color: Color(0xFF202226),
          fontSize: 15,
          height: 1.42,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        mainAxisAlignment: isNanhe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNanhe) ...[
            const _PpPatrickAvatar(radius: 19),
            const SizedBox(width: 9),
          ],
          bubble,
          if (isNanhe) ...[
            const SizedBox(width: 9),
            const _PpNanheAvatar(radius: 19),
          ],
        ],
      ),
    );
  }
}

class _ZhangmengHomePage extends StatelessWidget {
  const _ZhangmengHomePage({
    required this.totalLp,
    required this.historicalPeakTotalLp,
    required this.matchHistory,
    required this.onStartRanked,
    required this.onOpenHistory,
  });

  final int totalLp;
  final int historicalPeakTotalLp;
  final List<_LolMatchRecord> matchHistory;
  final VoidCallback onStartRanked;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final current = LolRankPosition.fromTotalLp(totalLp);
    final peak = LolRankPosition.fromTotalLp(historicalPeakTotalLp);
    final wins = matchHistory.where((match) => match.won).length;
    final losses = matchHistory.length - wins;
    return _ZhangmengBackground(
      key: const Key('zhangmeng-home-page'),
      child: SafeArea(
        bottom: false,
        child: _ZhangmengAdaptiveScrollableInset(
          child: Column(
            children: [
              const _ZhangmengPageHeader(title: '掌盟'),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ZhangmengRankBadge(position: current, size: 118),
                        const SizedBox(height: 2),
                        const Text(
                          '当前段位',
                          style: TextStyle(
                            color: Color(0xFF847761),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          current.displayLabel,
                          key: const Key('zhangmeng-current-rank'),
                          style: const TextStyle(
                            color: Color(0xFF332C24),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    _ZhangmengInfoCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ZhangmengSummaryItem(
                              label: '历史最高',
                              value: peak.displayLabel,
                              valueKey: const Key('zhangmeng-historical-peak'),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: const Color(0xFFD9C9A9),
                          ),
                          Expanded(
                            child: _ZhangmengSummaryItem(
                              label: '最近战绩',
                              value: matchHistory.isEmpty
                                  ? '暂无记录'
                                  : '$wins 胜 $losses 负',
                              valueKey: const Key('zhangmeng-recent-summary'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ZhangmengButton(
                          key: const Key('zhangmeng-start-ranked'),
                          label: '开始排位',
                          icon: Icons.sports_esports_rounded,
                          primary: true,
                          onPressed: onStartRanked,
                        ),
                        const SizedBox(height: 10),
                        _ZhangmengButton(
                          key: const Key('zhangmeng-open-history'),
                          label: '战绩记录',
                          icon: Icons.history_rounded,
                          onPressed: onOpenHistory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZhangmengMatchFoundPage extends StatefulWidget {
  const _ZhangmengMatchFoundPage({
    required this.audioController,
    required this.position,
    required this.winChanceLabel,
    required this.onAccept,
    required this.onDecline,
  });

  final GameAudioController audioController;
  final LolRankPosition position;
  final String winChanceLabel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_ZhangmengMatchFoundPage> createState() =>
      _ZhangmengMatchFoundPageState();
}

class _ZhangmengMatchFoundPageState extends State<_ZhangmengMatchFoundPage> {
  bool _decisionMade = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.audioController.playRankedQueueFound());
  }

  Future<void> _accept() async {
    if (_decisionMade) return;
    setState(() => _decisionMade = true);
    await widget.audioController.playRankedAccept();
    if (!mounted) return;
    widget.onAccept();
  }

  Future<void> _decline() async {
    if (_decisionMade) return;
    setState(() => _decisionMade = true);
    await widget.audioController.playRankedDecline();
    if (!mounted) return;
    widget.onDecline();
  }

  @override
  void dispose() {
    if (!_decisionMade) {
      unawaited(widget.audioController.stopRankedQueueFound());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: _ZhangmengBackground(
        key: const Key('zhangmeng-match-found-page'),
        child: SafeArea(
          bottom: false,
          child: _ZhangmengAdaptiveScrollableInset(
            child: Column(
              children: [
                const _ZhangmengPageHeader(title: '排位赛'),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ZhangmengRankBadge(
                            position: widget.position,
                            size: 142,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '对局已找到',
                            style: TextStyle(
                              color: Color(0xFF332C24),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '本场胜算：${widget.winChanceLabel}',
                            key: const Key('zhangmeng-win-chance'),
                            style: const TextStyle(
                              color: Color(0xFF75664F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_decisionMade) ...[
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF9B7433),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '正在确认……',
                              key: Key('zhangmeng-decision-pending'),
                              style: TextStyle(
                                color: Color(0xFF75664F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _ZhangmengButton(
                            key: const Key('zhangmeng-accept-match'),
                            label: '接受',
                            icon: Icons.check_rounded,
                            primary: true,
                            onPressed: _decisionMade ? null : _accept,
                          ),
                          const SizedBox(height: 10),
                          _ZhangmengButton(
                            key: const Key('zhangmeng-decline-match'),
                            label: '拒绝',
                            icon: Icons.close_rounded,
                            onPressed: _decisionMade ? null : _decline,
                          ),
                        ],
                      ),
                    ],
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

class _ZhangmengResultPage extends StatelessWidget {
  const _ZhangmengResultPage({
    required this.result,
    required this.onContinueRanked,
    required this.onReturnHome,
  });

  final _LolMatchResult result;
  final VoidCallback onContinueRanked;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    final streakLabel = result.won
        ? '当前连胜：${result.consecutiveWins}'
        : '当前连败：${result.consecutiveLosses}';
    final deltaLabel = result.lpDelta >= 0
        ? '+${result.lpDelta} LP'
        : '${result.lpDelta} LP';
    return _ZhangmengBackground(
      key: const Key('zhangmeng-result-page'),
      child: SafeArea(
        bottom: false,
        child: _ZhangmengAdaptiveScrollableInset(
          child: Column(
            children: [
              const _ZhangmengPageHeader(title: '排位结果'),
              const SizedBox(height: 14),
              _ZhangmengRankBadge(position: result.afterPosition, size: 142),
              const SizedBox(height: 4),
              Text(
                result.won ? '胜利' : '失败',
                key: const Key('zhangmeng-result-title'),
                style: TextStyle(
                  color: result.won
                      ? const Color(0xFF9B6A20)
                      : const Color(0xFF74544D),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _ZhangmengInfoCard(
                child: Column(
                  children: [
                    Text(
                      deltaLabel,
                      key: const Key('zhangmeng-lp-delta'),
                      style: TextStyle(
                        color: result.won
                            ? const Color(0xFF9B6A20)
                            : const Color(0xFF74544D),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(result.afterPosition.displayLabel),
                    const SizedBox(height: 8),
                    Text(
                      result.rankChangeLabel,
                      key: const Key('zhangmeng-rank-change'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      streakLabel,
                      key: const Key('zhangmeng-streak'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _ZhangmengButton(
                key: const Key('zhangmeng-continue-ranked'),
                label: '继续排位',
                icon: Icons.refresh_rounded,
                primary: true,
                onPressed: result.reachedMidnight ? null : onContinueRanked,
              ),
              const SizedBox(height: 12),
              _ZhangmengButton(
                key: const Key('zhangmeng-return-home'),
                label: '返回掌盟首页',
                icon: Icons.home_outlined,
                onPressed: onReturnHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZhangmengHistoryPage extends StatelessWidget {
  const _ZhangmengHistoryPage({required this.matchHistory});

  final List<_LolMatchRecord> matchHistory;

  @override
  Widget build(BuildContext context) {
    return _ZhangmengBackground(
      key: const Key('zhangmeng-history-page'),
      child: SafeArea(
        bottom: false,
        child: _ZhangmengAdaptiveInset(
          bottomInset: 70,
          child: Column(
            children: [
              const _ZhangmengPageHeader(title: '战绩记录'),
              const SizedBox(height: 20),
              Expanded(
                child: matchHistory.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无排位记录',
                          key: Key('zhangmeng-history-empty'),
                          style: TextStyle(
                            color: Color(0xFF746751),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: const Key('zhangmeng-history-list'),
                        itemCount: min(10, matchHistory.length),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final match = matchHistory[index];
                          return _ZhangmengHistoryRow(
                            key: Key('zhangmeng-history-row-$index'),
                            match: match,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _zhangmengHorizontalInset(double width) {
  final proportionalInset = (width * 0.1).clamp(20.0, 44.0);
  final centeredInset = max(0.0, (width - 430) / 2);
  return max(proportionalInset, centeredInset);
}

class _ZhangmengAdaptiveScrollableInset extends StatelessWidget {
  const _ZhangmengAdaptiveScrollableInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = _zhangmengHorizontalInset(constraints.maxWidth);
        final topInset = (constraints.maxHeight * 0.03).clamp(12.0, 24.0);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            topInset,
            horizontalInset,
            76,
          ),
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: innerConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(child: child),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ZhangmengAdaptiveInset extends StatelessWidget {
  const _ZhangmengAdaptiveInset({
    required this.child,
    required this.bottomInset,
  });

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = _zhangmengHorizontalInset(constraints.maxWidth);
        final topInset = (constraints.maxHeight * 0.03).clamp(12.0, 24.0);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            topInset,
            horizontalInset,
            bottomInset,
          ),
          child: child,
        );
      },
    );
  }
}

class _ZhangmengHistoryRow extends StatelessWidget {
  const _ZhangmengHistoryRow({super.key, required this.match});

  final _LolMatchRecord match;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: match.won ? const Color(0xFFC6A35A) : const Color(0xFFC7BDB0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            key: const Key('zhangmeng-history-logo'),
            radius: 27,
            backgroundColor: const Color(0xFFF8F4EB),
            backgroundImage: const AssetImage(miniNanheOriginalAsset),
          ),
          const SizedBox(width: 14),
          Text(
            match.won ? '胜利' : '失败',
            style: TextStyle(
              color: match.won
                  ? const Color(0xFF8E641C)
                  : const Color(0xFF5C5550),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Icon(
            match.won ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: match.won
                ? const Color(0xFFB4893A)
                : const Color(0xFF8E7F74),
          ),
        ],
      ),
    );
  }
}

class _ZhangmengBackground extends StatelessWidget {
  const _ZhangmengBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE1),
        image: const DecorationImage(
          image: AssetImage(phoneZhangmengBackgroundAsset),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

class _ZhangmengPageHeader extends StatelessWidget {
  const _ZhangmengPageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 30, height: 1, color: const Color(0xFFB89550)),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF332C24),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 30, height: 1, color: const Color(0xFFB89550)),
      ],
    );
  }
}

class _ZhangmengRankBadge extends StatelessWidget {
  const _ZhangmengRankBadge({required this.position, required this.size});

  final LolRankPosition position;
  final double size;

  @override
  Widget build(BuildContext context) {
    final index = position.tier.index.clamp(0, 9);
    final column = index % 5;
    final row = index ~/ 5;
    final sheetWidth = size * 5;
    final sheetHeight = sheetWidth / 2;
    final cellHeight = sheetHeight / 2;
    const horizontalCorrections = <double>[
      -0.056,
      -0.035,
      -0.014,
      0,
      -0.004,
      -0.028,
      -0.035,
      -0.021,
      0,
      -0.007,
    ];
    final horizontalCorrection = size * horizontalCorrections[index];
    final verticalCorrection = size * (row == 0 ? -0.15 : 0.03);
    final spriteAsset = position.tier == LolRankTier.master
        ? phoneZhangmengRankBadgesVividAsset
        : phoneZhangmengRankBadgesCleanAsset;

    return SizedBox(
      key: Key('zhangmeng-rank-badge-${position.tier.name}'),
      width: size,
      height: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: sheetWidth,
          maxWidth: sheetWidth,
          minHeight: sheetHeight,
          maxHeight: sheetHeight,
          child: Transform.translate(
            offset: Offset(
              -column * size + horizontalCorrection,
              -row * cellHeight + verticalCorrection,
            ),
            child: Image.asset(
              spriteAsset,
              width: sheetWidth,
              height: sheetHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZhangmengInfoCard extends StatelessWidget {
  const _ZhangmengInfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xEAFDF9F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5AA74), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C4A3820),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ZhangmengSummaryItem extends StatelessWidget {
  const _ZhangmengSummaryItem({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF847761), fontSize: 12),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          key: valueKey,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF3E352B),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ZhangmengButton extends StatelessWidget {
  const _ZhangmengButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? FilledButton.styleFrom(
            backgroundColor: const Color(0xFF9B7433),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFBEB4A3),
            disabledForegroundColor: const Color(0xFFE9E3D8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE0C783)),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5A4933),
            disabledForegroundColor: const Color(0xFFA99F92),
            backgroundColor: const Color(0xDDFDF9EF),
            side: const BorderSide(color: Color(0xFFB99A5B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: primary
          ? FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 21),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 21),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

class _PhoneNavigationBar extends StatelessWidget {
  const _PhoneNavigationBar({required this.onHome, required this.onBack});

  final VoidCallback onHome;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('phone-system-navigation-overlay'),
      color: const Color(0x70111820),
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PhoneNavigationButton(
              key: const Key('phone-home-button'),
              icon: Icons.circle_outlined,
              label: '回到主页',
              onPressed: onHome,
            ),
            _PhoneNavigationButton(
              key: const Key('phone-back-button'),
              icon: Icons.arrow_back_rounded,
              label: '返回',
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneNavigationButton extends StatelessWidget {
  const _PhoneNavigationButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 25),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    required this.growthStage,
    required this.money,
    required this.childhoodRoutineUnlocked,
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
    required this.statPopups,
    required this.isEndingReached,
    required this.isSickEndingCareActive,
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
    required this.onCareSickEnding,
    required this.onEvolution,
    required this.onPreviousBackground,
    required this.onNextBackground,
    required this.onOpenLocationSelector,
    required this.onOpenAppearanceSelector,
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
    required this.onChores,
    required this.onOuting,
    required this.onHit,
    required this.onSleep,
  });

  final int totalDaysTogether;
  final GrowthStage growthStage;
  final int money;
  final bool childhoodRoutineUnlocked;
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
  final List<_StatPopup> statPopups;
  final bool isEndingReached;
  final bool isSickEndingCareActive;
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
  final VoidCallback onCareSickEnding;
  final VoidCallback onEvolution;
  final VoidCallback onPreviousBackground;
  final VoidCallback onNextBackground;
  final VoidCallback onOpenLocationSelector;
  final VoidCallback onOpenAppearanceSelector;
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
  final VoidCallback? onChores;
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
            const fixedContentHeight = 282.0;
            final contentWidth = constraints.maxWidth - (horizontalPadding * 2);
            final availableStageHeight =
                constraints.maxHeight - fixedContentHeight;
            final protectedStageHeight = (contentWidth * 1.05).clamp(
              380.0,
              520.0,
            );
            final needsScrolling = availableStageHeight < protectedStageHeight;

            final stage = isSickEndingCareActive
                ? _SickEndingCareStage(
                    reaction: reaction,
                    onReadDialogue: onReadDialogue,
                  )
                : _CharacterStage(
                    backgroundAsset: backgroundAsset,
                    canSwitchBackground: canSwitchBackground,
                    canShowEvolutionButton: canShowEvolutionButton,
                    weatherCondition: weatherCondition,
                    reaction: reaction,
                    isReacting: isReacting,
                    emotionLabel: emotionLabel,
                    characterAsset: characterAsset,
                    statPopups: statPopups,
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
                    onOpenLocationSelector: onOpenLocationSelector,
                    onOpenAppearanceSelector: onOpenAppearanceSelector,
                    onEvolution: onEvolution,
                  );
            final actions = _ActionPanel(
              growthStage: growthStage,
              childhoodRoutineUnlocked: childhoodRoutineUnlocked,
              isEndingReached: isEndingReached,
              isSickEndingCareActive: isSickEndingCareActive,
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
              onChores: onChores,
              onOuting: onOuting,
              onHit: onHit,
              onSleep: onSleep,
              onResetGame: onResetGame,
              onCareSickEnding: onCareSickEnding,
            );

            if (needsScrolling) {
              return SingleChildScrollView(
                key: const Key('companion-scroll-view'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  children: [
                    _Header(
                      totalDaysTogether: totalDaysTogether,
                      growthStage: growthStage,
                      money: money,
                    ),
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
                  _Header(
                    totalDaysTogether: totalDaysTogether,
                    growthStage: growthStage,
                    money: money,
                  ),
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
  const _Header({
    required this.totalDaysTogether,
    required this.growthStage,
    required this.money,
  });

  final int totalDaysTogether;
  final GrowthStage growthStage;
  final int money;

  String get _growthStageLabel {
    return switch (growthStage) {
      GrowthStage.mini => '迷你期',
      GrowthStage.childhood => '幼年期',
    };
  }

  String get _characterName {
    return switch (growthStage) {
      GrowthStage.mini => '迷你南河',
      GrowthStage.childhood => '小南河',
    };
  }

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
                Text(
                  _characterName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '$_growthStageLabel · 第 $totalDaysTogether 天',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            key: const Key('money-indicator'),
            constraints: const BoxConstraints(minWidth: 82),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE3BE61)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 20,
                  color: Color(0xFFB7791F),
                ),
                const SizedBox(width: 6),
                Text(
                  '$money',
                  key: const Key('money-value'),
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
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
              '$season | 第$year年 · $month月$day日 · '
              '${_weekdayLabelForDate(year, month, day)} | '
              '$timeLabel | $weatherLabel',
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
    required this.statPopups,
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
    required this.onOpenLocationSelector,
    required this.onOpenAppearanceSelector,
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
  final List<_StatPopup> statPopups;
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
  final VoidCallback onOpenLocationSelector;
  final VoidCallback onOpenAppearanceSelector;
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
                final isDeadCharacter = characterAsset == miniNanheDeadAsset;
                final maxCharacterWidth =
                    constraints.maxWidth * (isDeadCharacter ? 0.6 : 0.5);
                final maxCharacterHeight =
                    constraints.maxHeight * (isDeadCharacter ? 0.56 : 0.48);

                return Align(
                  alignment: const Alignment(0, 0.2),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 86),
                    child: Semantics(
                      button: true,
                      label: '南河，点击互动',
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
                              key: const Key('companion-character-image'),
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
          Positioned.fill(
            child: IgnorePointer(child: _StatPopupStack(popups: statPopups)),
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
          Positioned(
            right: 20,
            bottom: reaction == null ? 18 : 118,
            child: _CompanionShortcutBar(
              onOpenLocationSelector: onOpenLocationSelector,
              onOpenAppearanceSelector: onOpenAppearanceSelector,
            ),
          ),
        ],
      ),
    );
  }
}

class _SickEndingCareStage extends StatelessWidget {
  const _SickEndingCareStage({
    required this.reaction,
    required this.onReadDialogue,
  });

  final CharacterReaction? reaction;
  final VoidCallback onReadDialogue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sick-ending-care-stage'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        image: const DecorationImage(
          image: AssetImage(sickEndingBedAsset),
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                ),
              ),
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

class _CompanionShortcutBar extends StatelessWidget {
  const _CompanionShortcutBar({
    required this.onOpenLocationSelector,
    required this.onOpenAppearanceSelector,
  });

  final VoidCallback onOpenLocationSelector;
  final VoidCallback onOpenAppearanceSelector;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompanionShortcutButton(
          key: const Key('location-shortcut-button'),
          tooltip: '外出',
          onPressed: onOpenLocationSelector,
          child: const Icon(Icons.public_rounded, color: deepBlue, size: 22),
        ),
        const SizedBox(width: 8),
        _CompanionShortcutButton(
          key: const Key('appearance-shortcut-button'),
          tooltip: '切换外观',
          onPressed: onOpenAppearanceSelector,
          child: ClipOval(
            child: Image.asset(
              miniNanheCalmAsset,
              width: 25,
              height: 25,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanionShortcutButton extends StatelessWidget {
  const _CompanionShortcutButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x339B7B4B),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _LocationSelectionPage extends StatelessWidget {
  const _LocationSelectionPage({
    required this.currentLocation,
    required this.homeUnlocked,
  });

  final CompanionLocation currentLocation;
  final bool homeUnlocked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外出')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const Key('location-home-button'),
                        onPressed: homeUnlocked
                            ? () => Navigator.of(
                                context,
                              ).pop(CompanionLocation.home)
                            : null,
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('家'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const Key('location-garden-button'),
                        onPressed: () =>
                            Navigator.of(context).pop(CompanionLocation.garden),
                        icon: const Icon(Icons.local_florist_rounded),
                        label: const Text('花园'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('幼年期地点规划', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '场景与专属互动尚在开发，完成后开放。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: mutedInk),
                ),
                const SizedBox(height: 12),
                const _PlannedLocationTile(
                  tileKey: Key('location-school-button'),
                  icon: Icons.school_rounded,
                  label: '小学',
                  plannedFeature: '上课、考试与同学互动',
                ),
                const SizedBox(height: 10),
                const _PlannedLocationTile(
                  tileKey: Key('location-shopping-street-button'),
                  icon: Icons.storefront_rounded,
                  label: '商店街',
                  plannedFeature: '购物、设备与金钱用途',
                ),
                const SizedBox(height: 10),
                const _PlannedLocationTile(
                  tileKey: Key('location-hospital-button'),
                  icon: Icons.local_hospital_rounded,
                  label: '医院',
                  plannedFeature: '治疗生病与受伤状态',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlannedLocationTile extends StatelessWidget {
  const _PlannedLocationTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.plannedFeature,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final String plannedFeature;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: tileKey,
      elevation: 0,
      color: blueMist.withValues(alpha: 0.72),
      child: ListTile(
        leading: Icon(icon, color: deepBlue),
        title: Text(label),
        subtitle: Text(plannedFeature),
        trailing: const Text(
          '开发中',
          style: TextStyle(color: mutedInk, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AppearanceSelectionPage extends StatelessWidget {
  const _AppearanceSelectionPage({
    required this.currentAppearance,
    required this.childhoodUnlocked,
  });

  final NanheAppearance currentAppearance;
  final bool childhoodUnlocked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('切换外观')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  _AppearanceOption(
                    buttonKey: const Key('appearance-mini-button'),
                    label: '迷你南河',
                    imageAsset: miniNanheCalmAsset,
                    selected: currentAppearance == NanheAppearance.mini,
                    onTap: () =>
                        Navigator.of(context).pop(NanheAppearance.mini),
                  ),
                  if (childhoodUnlocked)
                    _AppearanceOption(
                      buttonKey: const Key('appearance-childhood-button'),
                      label: '小南河',
                      imageAsset: childNanheAsset,
                      selected: currentAppearance == NanheAppearance.childhood,
                      onTap: () =>
                          Navigator.of(context).pop(NanheAppearance.childhood),
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

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.buttonKey,
    required this.label,
    required this.imageAsset,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: selected ? blueMist : frost,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? azure : const Color(0xFFD7E8FA),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: Image.asset(imageAsset, fit: BoxFit.contain)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
            ],
          ),
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

class _StatPopupStack extends StatelessWidget {
  const _StatPopupStack({required this.popups});

  final List<_StatPopup> popups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseBottom = constraints.maxHeight * 0.42;
        final right = constraints.maxWidth * 0.22;

        return Stack(
          children: [
            for (var index = 0; index < popups.length; index += 1)
              Positioned(
                right: right,
                bottom: baseBottom + ((popups.length - 1 - index) * 30),
                child: _StatPopupChip(
                  key: ValueKey('stat-popup-${popups[index].id}'),
                  label: popups[index].label,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatPopupChip extends StatelessWidget {
  const _StatPopupChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = value < 0.72 ? 1.0 : (1 - value) / 0.28;
        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -10 * value),
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEFFFFFF8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2C77D)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF274467),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
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
    required this.growthStage,
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
    required this.characterAsset,
    required this.strength,
    required this.intelligence,
    required this.charm,
    required this.art,
    required this.skill,
    required this.endurance,
  });

  final GrowthStage growthStage;
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
  final String characterAsset;
  final int strength;
  final int intelligence;
  final int charm;
  final int art;
  final int skill;
  final int endurance;

  String get _characterName => switch (growthStage) {
    GrowthStage.mini => '迷你南河',
    GrowthStage.childhood => '小南河',
  };

  String get _growthStageLabel => switch (growthStage) {
    GrowthStage.mini => '迷你期',
    GrowthStage.childhood => '幼年期',
  };

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
                        _characterName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _growthStageLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
    required this.growthStage,
    required this.childhoodRoutineUnlocked,
    required this.isEndingReached,
    required this.isSickEndingCareActive,
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
    required this.onChores,
    required this.onOuting,
    required this.onHit,
    required this.onSleep,
    required this.onResetGame,
    required this.onCareSickEnding,
  });

  final GrowthStage growthStage;
  final bool childhoodRoutineUnlocked;
  final bool isEndingReached;
  final bool isSickEndingCareActive;
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
  final VoidCallback? onChores;
  final VoidCallback onOuting;
  final VoidCallback onHit;
  final VoidCallback onSleep;
  final VoidCallback onResetGame;
  final VoidCallback onCareSickEnding;

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

    if (isSickEndingCareActive) {
      return Center(
        child: SizedBox(
          width: 220,
          child: _ActionButton(
            key: const Key('sick-ending-care-button'),
            label: '照顾',
            emphasized: true,
            onPressed: onCareSickEnding,
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
    final usesChildhoodRoutine = childhoodRoutineUnlocked;
    final restOrSleepButton = canSleep
        ? _ActionButton(
            key: const Key('sleep-button'),
            label: '睡觉',
            detail: '体力恢复至上限',
            emphasized: true,
            onPressed: onSleep,
          )
        : _ActionButton(
            key: const Key('daily-rest-button'),
            label: '休息',
            detail: '体力+2',
            onPressed: onRest,
          );
    final primaryActions = <Widget>[
      if (usesChildhoodRoutine && hasUnlockedAllDailyActions)
        _ActionButton(
          key: const Key('outing-button'),
          label: '外出',
          detail: '选择地点',
          special: true,
          onPressed: onOuting,
        ),
      _ActionButton(
        key: const Key('chat-button'),
        label: '聊天',
        detail: '体力-1',
        onPressed: onChat,
      ),
      _ActionButton(
        key: const Key('pet-button'),
        label: '抚摸',
        detail: '体力-1',
        onPressed: onPet,
      ),
      _ActionButton(
        key: const Key('observe-button'),
        label: '观察',
        detail: '体力-1',
        onPressed: onObserve,
      ),
      if (!usesChildhoodRoutine || !hasUnlockedAllDailyActions)
        restOrSleepButton,
    ];
    final unlockedExtraActions = <Widget>[
      if (usesChildhoodRoutine && hasUnlockedAllDailyActions) restOrSleepButton,
      if (hasUnlockedAllDailyActions)
        _ActionButton(
          key: const Key('play-button'),
          label: '玩耍',
          detail: '体力-2',
          onPressed: onPlay,
        ),
      if (!usesChildhoodRoutine && hasUnlockedAllDailyActions)
        _ActionButton(
          key: const Key('walk-button'),
          label: '散步',
          detail: '体力-2',
          onPressed: onWalk,
        ),
      if (hasUnlockedFeed)
        _ActionButton(
          key: const Key('feed-button'),
          label: growthStage == GrowthStage.childhood ? '吃饭' : '喂食',
          detail: '体力-1',
          onPressed: onFeed,
        ),
      if (hasUnlockedHit)
        _ActionButton(
          key: const Key('hit-button'),
          label: '殴打',
          detail: '体力-1 · 健康-2',
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
    final usesChildhoodRoutine = childhoodRoutineUnlocked;
    return Column(
      children: [
        _ActionButtonRow(
          children: [
            _ActionButton(
              key: const Key('study-button'),
              label: '学习',
              detail: '体力-8 · 智力+1',
              onPressed: onStudy,
            ),
            _ActionButton(
              key: const Key('exercise-button'),
              label: '运动',
              detail: '体力-12 · 力量+1 · 耐力+1',
              onPressed: onExercise,
            ),
            _ActionButton(
              key: const Key('game-button'),
              label: '打游戏',
              detail: '体力-8 · 技巧+1',
              onPressed: onGame,
            ),
            _ActionButton(
              key: const Key('create-button'),
              label: '创作',
              detail: '体力-8 · 艺术+1',
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
              detail: '体力-8 · 魅力+1',
              onPressed: onPerform,
            ),
            if (usesChildhoodRoutine)
              _ActionButton(
                key: const Key('chores-button'),
                label: '做家务',
                detail: onChores == null ? '今日已完成' : '体力-8 · 金钱+10',
                onPressed: onChores,
              )
            else
              _ActionButton(
                key: const Key('bath-button'),
                label: '洗澡',
                detail: '体力-1 · 清洁+35',
                onPressed: onBath,
              ),
            if (usesChildhoodRoutine)
              _ActionButton(
                key: const Key('bath-button'),
                label: '洗澡',
                detail: '体力-1 · 清洁+35',
                onPressed: onBath,
              )
            else
              _ActionButton(
                key: const Key('outing-button'),
                label: '外出',
                detail: '选择地点',
                onPressed: onOuting,
              ),
            _ActionButton(
              key: const Key('rest-button'),
              label: '休息',
              detail: '体力+2',
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
    this.detail,
    this.onPressed,
    this.emphasized = false,
    this.special = false,
    this.destructive = false,
  });

  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool special;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (detail != null) ...[
          const SizedBox(height: 1),
          Text(
            detail!,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
    final minimumHeight = detail == null ? 42.0 : 56.0;

    if (destructive) {
      return FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFF9B1C1C),
          backgroundColor: const Color(0xFFFFE1E1),
          minimumSize: Size(0, minimumHeight),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

    if (special) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: gold,
          minimumSize: Size(0, minimumHeight),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

    if (emphasized) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, minimumHeight),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, minimumHeight),
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
    required this.showDebugTools,
    required this.saveSlots,
    required this.totalDaysTogether,
    required this.minuteOfDay,
    required this.affectionLevel,
    required this.trustLevel,
    required this.onMusicChanged,
    required this.onSoundEffectChanged,
    required this.onVoiceChanged,
    required this.onMusicMuteToggle,
    required this.onSoundEffectMuteToggle,
    required this.onVoiceMuteToggle,
    required this.onBgmChanged,
    required this.onSaveSlot,
    required this.onLoadSlot,
    required this.onExportSlot,
    required this.onImportSave,
    required this.onRestartGame,
    required this.onVersionLongPress,
    required this.onDebugTimelineChanged,
    required this.onDebugAffectionLevelChanged,
    required this.onDebugTrustLevelChanged,
    required this.onDebugEvolutionReady,
  });

  final BgmTrack selectedBgm;
  final double musicVolume;
  final double soundEffectVolume;
  final double voiceVolume;
  final bool showDebugTools;
  final List<_SaveSlotSummary> saveSlots;
  final int totalDaysTogether;
  final int minuteOfDay;
  final int affectionLevel;
  final int trustLevel;
  final ValueChanged<double> onMusicChanged;
  final ValueChanged<double> onSoundEffectChanged;
  final ValueChanged<double> onVoiceChanged;
  final VoidCallback onMusicMuteToggle;
  final VoidCallback onSoundEffectMuteToggle;
  final VoidCallback onVoiceMuteToggle;
  final ValueChanged<BgmTrack> onBgmChanged;
  final ValueChanged<int> onSaveSlot;
  final ValueChanged<int> onLoadSlot;
  final ValueChanged<int> onExportSlot;
  final VoidCallback onImportSave;
  final VoidCallback onRestartGame;
  final VoidCallback onVersionLongPress;
  final void Function({required int totalDaysTogether, required int minute})
  onDebugTimelineChanged;
  final ValueChanged<int> onDebugAffectionLevelChanged;
  final ValueChanged<int> onDebugTrustLevelChanged;
  final VoidCallback onDebugEvolutionReady;

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
          _SaveSlotsPanel(
            slots: saveSlots,
            onSaveSlot: onSaveSlot,
            onLoadSlot: onLoadSlot,
            onExportSlot: onExportSlot,
            onImportSave: onImportSave,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('restart-game-button'),
            onPressed: onRestartGame,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9B3F3F),
              side: const BorderSide(color: Color(0xFFD9A3A3)),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('重新开始'),
          ),
          if (showDebugTools) ...[
            const SizedBox(height: 8),
            _DebugToolsPanel(
              totalDaysTogether: totalDaysTogether,
              minuteOfDay: minuteOfDay,
              affectionLevel: affectionLevel,
              trustLevel: trustLevel,
              onTimelineChanged: onDebugTimelineChanged,
              onAffectionLevelChanged: onDebugAffectionLevelChanged,
              onTrustLevelChanged: onDebugTrustLevelChanged,
              onEvolutionReady: onDebugEvolutionReady,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onLongPress: onVersionLongPress,
              child: const Text(
                '版本 $appVersion',
                key: Key('app-version'),
                style: TextStyle(
                  color: Color(0xFF7A8796),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SaveSlotsPanel extends StatelessWidget {
  const _SaveSlotsPanel({
    required this.slots,
    required this.onSaveSlot,
    required this.onLoadSlot,
    required this.onExportSlot,
    required this.onImportSave,
  });

  final List<_SaveSlotSummary> slots;
  final ValueChanged<int> onSaveSlot;
  final ValueChanged<int> onLoadSlot;
  final ValueChanged<int> onExportSlot;
  final VoidCallback onImportSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('save-slots-panel'),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(
        color: frost,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E8FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('本机存档', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '网页存档保存在当前浏览器，清除网站数据后会消失。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final slot in slots) ...[
            _SaveSlotTile(
              slot: slot,
              onSave: () => onSaveSlot(slot.slotIndex),
              onLoad: slot.isEmpty ? null : () => onLoadSlot(slot.slotIndex),
              onExport: slot.isEmpty
                  ? null
                  : () => onExportSlot(slot.slotIndex),
            ),
            if (slot.slotIndex != slots.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('import-save-code-button'),
            onPressed: onImportSave,
            icon: const Icon(Icons.input_rounded),
            label: const Text('导入存档码'),
          ),
        ],
      ),
    );
  }
}

class _SaveSlotTile extends StatelessWidget {
  const _SaveSlotTile({
    required this.slot,
    required this.onSave,
    required this.onLoad,
    required this.onExport,
  });

  final _SaveSlotSummary slot;
  final VoidCallback onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueMist.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              slot.isEmpty ? Icons.inventory_2_outlined : Icons.save_rounded,
              color: slot.isEmpty ? mutedInk : deepBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedInk,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                FilledButton.tonal(
                  key: Key('save-slot-${slot.slotIndex}-save'),
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('保存'),
                ),
                FilledButton(
                  key: Key('save-slot-${slot.slotIndex}-load'),
                  onPressed: onLoad,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('读取'),
                ),
                OutlinedButton(
                  key: Key('save-slot-${slot.slotIndex}-export'),
                  onPressed: onExport,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('导出'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveImportResult {
  const _SaveImportResult({required this.saveCode, required this.slotIndex});

  final String saveCode;
  final int slotIndex;
}

class _ImportSaveDialog extends StatefulWidget {
  const _ImportSaveDialog();

  @override
  State<_ImportSaveDialog> createState() => _ImportSaveDialogState();
}

class _ImportSaveDialogState extends State<_ImportSaveDialog> {
  final _controller = TextEditingController();
  int _slotIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final saveCode = _controller.text.trim();
    if (saveCode.isEmpty) return;
    Navigator.of(
      context,
    ).pop(_SaveImportResult(saveCode: saveCode, slotIndex: _slotIndex));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入存档码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('import-save-code-field'),
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '存档码',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const Key('import-save-slot-selector'),
            initialValue: _slotIndex,
            decoration: const InputDecoration(
              labelText: '导入到',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var index = 0; index < _saveSlotCount; index += 1)
                DropdownMenuItem(value: index, child: Text('存档 ${index + 1}')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _slotIndex = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('import-save-confirm-button'),
          onPressed: _submit,
          child: const Text('导入'),
        ),
      ],
    );
  }
}

class _DebugToolsPanel extends StatelessWidget {
  const _DebugToolsPanel({
    required this.totalDaysTogether,
    required this.minuteOfDay,
    required this.affectionLevel,
    required this.trustLevel,
    required this.onTimelineChanged,
    required this.onAffectionLevelChanged,
    required this.onTrustLevelChanged,
    required this.onEvolutionReady,
  });

  final int totalDaysTogether;
  final int minuteOfDay;
  final int affectionLevel;
  final int trustLevel;
  final void Function({required int totalDaysTogether, required int minute})
  onTimelineChanged;
  final ValueChanged<int> onAffectionLevelChanged;
  final ValueChanged<int> onTrustLevelChanged;
  final VoidCallback onEvolutionReady;

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
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            key: const Key('debug-evolution-ready-button'),
            onPressed: onEvolutionReady,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('第 61 天 · 可进化'),
          ),
          const SizedBox(height: 8),
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
            key: const Key('debug-trust-level-slider'),
            label: '信任等级',
            valueLabel: 'Lv.$trustLevel',
            value: trustLevel,
            min: 1,
            max: 10,
            onChanged: onTrustLevelChanged,
          ),
        ],
      ),
    );
  }
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
