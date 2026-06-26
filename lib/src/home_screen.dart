import 'dart:math';

import 'package:flutter/material.dart';

import 'app_version.dart';
import 'character_reaction.dart';
import 'game_audio_controller.dart';
import 'game_assets.dart';
import 'theme.dart';

const _maxEnergy = 25;
const _affectionGainPerInteraction = 3;
const _affectionGainPerQuietInteraction = 1;
const _affectionLossPerHit = 5;
const _minutesPerInteraction = 30;
const _sleepAvailableMinute = 22 * 60;
const _midnightMinute = 24 * 60;
const _earliestWakeMinute = 6 * 60;
const _sleepDurationMinutes = 8 * 60;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.audioController});

  final GameAudioController audioController;

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
  int _energy = _maxEnergy;
  int _affectionLevel = 1;
  int _affectionProgress = 0;
  int _actionPage = 0;
  bool _sleepPending = false;
  final int _strength = 1;
  final int _intelligence = 1;
  final int _endurance = 1;
  double _musicVolume = 0.7;
  double _soundEffectVolume = 0.8;
  double _voiceVolume = 0.9;
  double _musicVolumeBeforeMute = 0.7;
  double _soundEffectVolumeBeforeMute = 0.8;
  double _voiceVolumeBeforeMute = 0.9;
  BgmTrack _selectedBgm = BgmTrack.cozyNanhe2;

  bool get _isExhausted => _energy <= 0;
  bool get _isMidnight => _minuteOfDay >= _midnightMinute;
  bool get _isForcedSleep => _isExhausted || _isMidnight;
  bool get _isActionLocked => _isForcedSleep || _sleepPending;
  bool get _canSleepByTime => _minuteOfDay >= _sleepAvailableMinute;

  String get _timeLabel {
    final normalizedMinute = _minuteOfDay % _midnightMinute;
    final hour = normalizedMinute ~/ 60;
    final minute = normalizedMinute % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
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
    if (_isExhausted &&
        emotion != NanheEmotion.sad &&
        emotion != NanheEmotion.angry &&
        emotion != NanheEmotion.frustrated) {
      return NanheEmotion.sleepy;
    }
    return emotion ?? NanheEmotion.calm;
  }

  String get _season {
    if (_month >= 3 && _month <= 5) return '春';
    if (_month >= 6 && _month <= 8) return '夏';
    if (_month >= 9 && _month <= 11) return '秋';
    return '冬';
  }

  String get _moodLabel {
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

  String get _characterAsset {
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

  void _showReaction(
    List<CharacterReaction> responses, {
    bool consumesEnergy = true,
    int affectionGain = _affectionGainPerInteraction,
    bool advancesTime = true,
  }) {
    if (_sleepPending) return;

    if (consumesEnergy && _isForcedSleep) {
      setState(() => _reaction = exhaustedReaction);
      widget.audioController.playVoice(exhaustedReaction.voice);
      return;
    }

    final available = responses.length > 1
        ? responses.where((response) => response != _reaction).toList()
        : responses;
    final reaction = available[_random.nextInt(available.length)];

    setState(() {
      if (consumesEnergy) {
        _energy = (_energy - 1).clamp(0, _maxEnergy);
        _gainAffection(affectionGain);
      }
      if (advancesTime) _advanceMinutes(_minutesPerInteraction);
      _reaction = reaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(reaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _gainAffection(int amount) {
    _affectionProgress += amount;
    while (_affectionProgress >= 100) {
      _affectionLevel += 1;
      _affectionProgress -= 100;
    }
  }

  void _loseAffection(int amount) {
    _affectionProgress -= amount;
    while (_affectionProgress < 0 && _affectionLevel > 1) {
      _affectionLevel -= 1;
      _affectionProgress += 100;
    }
    if (_affectionLevel <= 1 && _affectionProgress < 0) {
      _affectionLevel = 1;
      _affectionProgress = 0;
    }
  }

  void _showHitReaction() {
    if (_sleepPending) return;

    if (_isForcedSleep) {
      setState(() => _reaction = exhaustedReaction);
      widget.audioController.playVoice(exhaustedReaction.voice);
      return;
    }

    final reaction = hitReactions[_random.nextInt(hitReactions.length)];
    setState(() {
      _energy = (_energy - 1).clamp(0, _maxEnergy);
      _advanceMinutes(_minutesPerInteraction);
      _loseAffection(_affectionLossPerHit);
      _reaction = reaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(
      reaction.voice,
      delay: const Duration(milliseconds: 180),
    );

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
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
      _advanceOneDay();
      _totalDaysTogether += 1;
      _minuteOfDay = wakeMinute;
      _energy = _maxEnergy;
      _reaction = wakeUpReaction;
      _sleepPending = false;
      _isReacting = false;
    });
    widget.audioController.playVoice(wakeUpReaction.voice);
  }

  void _observe() {
    _showReaction(
      observeReactions,
      affectionGain: _affectionGainPerQuietInteraction,
    );
  }

  void _chat() {
    if (_sleepPending) return;

    if (_isForcedSleep) {
      _showReaction(const [exhaustedReaction], consumesEnergy: false);
      return;
    }

    _showReaction(
      dialogueReactions,
      affectionGain: _affectionGainPerQuietInteraction,
    );
  }

  void _rest() {
    if (_sleepPending) return;

    if (_isForcedSleep) {
      _showReaction(const [exhaustedReaction], consumesEnergy: false);
      return;
    }

    setState(() {
      _energy = (_energy + 5).clamp(0, _maxEnergy);
      _advanceMinutes(_minutesPerInteraction);
      _reaction = restReaction;
      _isReacting = true;
    });
    widget.audioController.playVoice(restReaction.voice);

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _readDialogue() {
    if (_reaction == null) return;
    if (_sleepPending) {
      _completeSleepUntilTomorrow();
      return;
    }
    setState(() => _reaction = null);
  }

  void _setActionPage(int page) {
    setState(() => _actionPage = page);
  }

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
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

  @override
  Widget build(BuildContext context) {
    final page = switch (_selectedDestination) {
      1 => _StatusPage(
        affectionLevel: _affectionLevel,
        affectionProgress: _affectionProgress,
        energy: _energy,
        moodLabel: _moodLabel,
        characterAsset: _characterAsset,
        strength: _strength,
        intelligence: _intelligence,
        endurance: _endurance,
      ),
      2 => _SettingsPage(
        selectedBgm: _selectedBgm,
        musicVolume: _musicVolume,
        soundEffectVolume: _soundEffectVolume,
        voiceVolume: _voiceVolume,
        onMusicChanged: _setMusicVolume,
        onSoundEffectChanged: _setSoundEffectVolume,
        onVoiceChanged: _setVoiceVolume,
        onMusicMuteToggle: _toggleMusicMute,
        onSoundEffectMuteToggle: _toggleSoundEffectMute,
        onVoiceMuteToggle: _toggleVoiceMute,
        onBgmChanged: _changeBgm,
      ),
      _ => _CompanionPage(
        totalDaysTogether: _totalDaysTogether,
        season: _season,
        year: _year,
        month: _month,
        day: _day,
        timeLabel: _timeLabel,
        weatherLabel: '晴',
        reaction: _reaction,
        isReacting: _isReacting,
        moodLabel: _moodLabel,
        characterAsset: _characterAsset,
        isForcedSleep: _isActionLocked,
        isSleepPending: _sleepPending,
        canSleep: _canSleepByTime,
        actionPage: _actionPage,
        affectionLevel: _affectionLevel,
        affectionProgress: _affectionProgress,
        energy: _energy,
        onReadDialogue: _readDialogue,
        onPageChanged: _setActionPage,
        onCharacterTap: () {
          widget.audioController.playRegularInteraction();
          _showReaction(petReactions);
        },
        onChat: () {
          widget.audioController.playRegularInteraction();
          _chat();
        },
        onPet: () {
          widget.audioController.playRegularInteraction();
          _showReaction(petReactions);
        },
        onObserve: () {
          widget.audioController.playRegularInteraction();
          _observe();
        },
        onWalk: () {
          widget.audioController.playRegularInteraction();
          _showReaction(walkReactions);
        },
        onFeed: () {
          widget.audioController.playRegularInteraction();
          _showReaction(feedReactions);
        },
        onRest: () {
          widget.audioController.playRegularInteraction();
          _rest();
        },
        onHit: () {
          widget.audioController.playHitInteraction();
          _showHitReaction();
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
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '设置'),
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
    required this.reaction,
    required this.isReacting,
    required this.moodLabel,
    required this.characterAsset,
    required this.isForcedSleep,
    required this.isSleepPending,
    required this.canSleep,
    required this.actionPage,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.energy,
    required this.onReadDialogue,
    required this.onPageChanged,
    required this.onCharacterTap,
    required this.onChat,
    required this.onPet,
    required this.onObserve,
    required this.onWalk,
    required this.onFeed,
    required this.onRest,
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
  final CharacterReaction? reaction;
  final bool isReacting;
  final String moodLabel;
  final String characterAsset;
  final bool isForcedSleep;
  final bool isSleepPending;
  final bool canSleep;
  final int actionPage;
  final int affectionLevel;
  final int affectionProgress;
  final int energy;
  final VoidCallback onReadDialogue;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onCharacterTap;
  final VoidCallback onChat;
  final VoidCallback onPet;
  final VoidCallback onObserve;
  final VoidCallback onWalk;
  final VoidCallback onFeed;
  final VoidCallback onRest;
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
              reaction: reaction,
              isReacting: isReacting,
              moodLabel: moodLabel,
              characterAsset: characterAsset,
              affectionLevel: affectionLevel,
              affectionProgress: affectionProgress,
              energy: energy,
              onTap: onCharacterTap,
              onReadDialogue: onReadDialogue,
            );
            final actions = _ActionPanel(
              isForcedSleep: isForcedSleep,
              isSleepPending: isSleepPending,
              canSleep: canSleep,
              actionPage: actionPage,
              onPageChanged: onPageChanged,
              onChat: onChat,
              onPet: onPet,
              onObserve: onObserve,
              onWalk: onWalk,
              onFeed: onFeed,
              onRest: onRest,
              onHit: onHit,
              onSleep: onSleep,
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
    required this.reaction,
    required this.isReacting,
    required this.moodLabel,
    required this.characterAsset,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.energy,
    required this.onTap,
    required this.onReadDialogue,
  });

  final CharacterReaction? reaction;
  final bool isReacting;
  final String moodLabel;
  final String characterAsset;
  final int affectionLevel;
  final int affectionProgress;
  final int energy;
  final VoidCallback onTap;
  final VoidCallback onReadDialogue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: frost,
        image: const DecorationImage(
          image: AssetImage(defaultGardenDoghouseAsset),
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
              energy: energy,
            ),
          ),
          Positioned(top: 12, right: 14, child: _MoodChip(label: moodLabel)),
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

class _CompactStatusPanel extends StatelessWidget {
  const _CompactStatusPanel({
    required this.affectionLevel,
    required this.affectionProgress,
    required this.energy,
  });

  final int affectionLevel;
  final int affectionProgress;
  final int energy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
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
            label: '体力',
            valueLabel: '$energy/$_maxEnergy',
            value: energy / _maxEnergy,
            color: azure,
          ),
        ],
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
    required this.energy,
    required this.moodLabel,
    required this.characterAsset,
    required this.strength,
    required this.intelligence,
    required this.endurance,
  });

  final int affectionLevel;
  final int affectionProgress;
  final int energy;
  final String moodLabel;
  final String characterAsset;
  final int strength;
  final int intelligence;
  final int endurance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            title: '基础数值',
            children: [
              _StatusValueRow(
                label: '当前好感度',
                value: 'Lv.$affectionLevel  $affectionProgress/100',
              ),
              _StatusValueRow(label: '当前体力', value: '$energy/$_maxEnergy'),
              _StatusValueRow(label: '心情', value: moodLabel),
              _StatusValueRow(label: '力量', value: '$strength'),
              _StatusValueRow(label: '智力', value: '$intelligence'),
              _StatusValueRow(label: '耐力', value: '$endurance'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '以后增加数值的功能可以放在这里。',
            style: Theme.of(context).textTheme.bodySmall,
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
    required this.isForcedSleep,
    required this.isSleepPending,
    required this.canSleep,
    required this.actionPage,
    required this.onPageChanged,
    required this.onChat,
    required this.onPet,
    required this.onObserve,
    required this.onWalk,
    required this.onFeed,
    required this.onRest,
    required this.onHit,
    required this.onSleep,
  });

  final bool isForcedSleep;
  final bool isSleepPending;
  final bool canSleep;
  final int actionPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onChat;
  final VoidCallback onPet;
  final VoidCallback onObserve;
  final VoidCallback onWalk;
  final VoidCallback onFeed;
  final VoidCallback onRest;
  final VoidCallback onHit;
  final VoidCallback onSleep;

  @override
  Widget build(BuildContext context) {
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

    final page = actionPage == 0 ? _primaryPage() : _placeholderPage();

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
              if (actionPage > 0)
                IconButton.filledTonal(
                  key: const Key('action-page-up'),
                  tooltip: '上一页',
                  onPressed: () => onPageChanged(actionPage - 1),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              const SizedBox(height: 6),
              if (actionPage < 1)
                IconButton.filledTonal(
                  key: const Key('action-page-down'),
                  tooltip: '下一页',
                  onPressed: () => onPageChanged(actionPage + 1),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryPage() {
    return Column(
      children: [
        _ActionButtonRow(
          children: [
            _ActionButton(
              key: const Key('chat-button'),
              label: '聊天',
              emphasized: true,
              onPressed: onChat,
            ),
            _ActionButton(
              key: const Key('pet-button'),
              label: '抚摸',
              onPressed: onPet,
            ),
            _ActionButton(
              key: const Key('observe-button'),
              label: '观察',
              onPressed: onObserve,
            ),
            _ActionButton(
              key: const Key('rest-button'),
              label: '休息',
              onPressed: onRest,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ActionButtonRow(
          children: [
            _ActionButton(
              key: const Key('walk-button'),
              label: '散步',
              onPressed: onWalk,
            ),
            _ActionButton(
              key: const Key('feed-button'),
              label: '喂食',
              onPressed: onFeed,
            ),
            _ActionButton(
              key: const Key('hit-button'),
              label: '殴打',
              destructive: true,
              onPressed: onHit,
            ),
            _ActionButton(
              key: const Key('sleep-button'),
              label: '睡觉',
              emphasized: canSleep,
              disabledLook: !canSleep,
              onPressed: onSleep,
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholderPage() {
    return Column(
      children: [
        _ActionButtonRow(
          children: List.generate(
            4,
            (index) => _ActionButton(
              key: Key('placeholder-action-${index + 1}'),
              label: '${index + 1}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ActionButtonRow(
          children: List.generate(
            4,
            (index) => _ActionButton(
              key: Key('placeholder-action-${index + 5}'),
              label: '${index + 5}',
            ),
          ),
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
    this.disabledLook = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool destructive;
  final bool disabledLook;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (disabledLook) {
      return FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFF8C96A3),
          backgroundColor: const Color(0xFFF0F3F6),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: child,
      );
    }

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
    required this.onMusicChanged,
    required this.onSoundEffectChanged,
    required this.onVoiceChanged,
    required this.onMusicMuteToggle,
    required this.onSoundEffectMuteToggle,
    required this.onVoiceMuteToggle,
    required this.onBgmChanged,
  });

  final BgmTrack selectedBgm;
  final double musicVolume;
  final double soundEffectVolume;
  final double voiceVolume;
  final ValueChanged<double> onMusicChanged;
  final ValueChanged<double> onSoundEffectChanged;
  final ValueChanged<double> onVoiceChanged;
  final VoidCallback onMusicMuteToggle;
  final VoidCallback onSoundEffectMuteToggle;
  final VoidCallback onVoiceMuteToggle;
  final ValueChanged<BgmTrack> onBgmChanged;

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
