import 'dart:math';

import 'package:flutter/material.dart';

import 'character_reaction.dart';
import 'theme.dart';

const _maxEnergy = 50;
const _affectionGainPerInteraction = 3;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  int _energy = _maxEnergy;
  int _affectionLevel = 1;
  int _affectionProgress = 0;

  bool get _isExhausted => _energy <= 0;

  String get _season {
    if (_month >= 3 && _month <= 5) return '春';
    if (_month >= 6 && _month <= 8) return '夏';
    if (_month >= 9 && _month <= 11) return '秋';
    return '冬';
  }

  String get _moodLabel {
    final emotion = _reaction?.emotion ?? NanheEmotion.calm;
    return switch (emotion) {
      NanheEmotion.happy => '☺ 开心',
      NanheEmotion.affectionate => '♥ 亲近',
      NanheEmotion.curious => '? 好奇',
      NanheEmotion.sad => '… 低落',
      NanheEmotion.sleepy => '☾ 困了',
      NanheEmotion.calm => '☺ 平静',
    };
  }

  void _showReaction(
    List<CharacterReaction> responses, {
    bool consumesEnergy = true,
  }) {
    if (consumesEnergy && _isExhausted) {
      setState(() => _reaction = exhaustedReaction);
      return;
    }

    final available = responses.length > 1
        ? responses.where((response) => response != _reaction).toList()
        : responses;

    setState(() {
      if (consumesEnergy) {
        _energy -= 1;
        _gainAffection();
      }
      _reaction = available[_random.nextInt(available.length)];
      _isReacting = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _gainAffection() {
    _affectionProgress += _affectionGainPerInteraction;
    while (_affectionProgress >= 100) {
      _affectionLevel += 1;
      _affectionProgress -= 100;
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

  void _sleepUntilTomorrow() {
    setState(() {
      _advanceOneDay();
      _totalDaysTogether += 1;
      _energy = _maxEnergy;
      _reaction = wakeUpReaction;
      _isReacting = false;
    });
  }

  void _observe() {
    _showReaction(observeReactions);
  }

  Future<void> _openDialogue() async {
    if (_isExhausted) {
      _showReaction(const [exhaustedReaction], consumesEnergy: false);
      return;
    }

    final choice = await showModalBottomSheet<CharacterReaction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: frost,
      builder: (context) => const _DialogueSheet(),
    );

    if (choice != null && mounted) {
      _showReaction([choice]);
    }
  }

  void _selectDestination(int index) {
    setState(() => _selectedDestination = index);
    if (index == 1) {
      _showReaction(const [
        CharacterReaction(
          emotion: NanheEmotion.calm,
          nanheSpeech: '南河～',
          meaning: '回忆功能之后才会开放。',
        ),
      ], consumesEnergy: false);
    } else if (index == 2) {
      _showSettings();
    }
  }

  Future<void> _showSettings() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: frost,
      builder: (context) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              _Header(
                totalDaysTogether: _totalDaysTogether,
                onSettings: _showSettings,
              ),
              const SizedBox(height: 8),
              _CalendarCard(
                season: _season,
                year: _year,
                month: _month,
                day: _day,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _CharacterStage(
                  reaction: _reaction,
                  isReacting: _isReacting,
                  moodLabel: _moodLabel,
                  isExhausted: _isExhausted,
                  affectionLevel: _affectionLevel,
                  affectionProgress: _affectionProgress,
                  energy: _energy,
                  onTap: () => _showReaction(tapReactions),
                ),
              ),
              const SizedBox(height: 12),
              _ActionPanel(
                isExhausted: _isExhausted,
                onCall: () => _showReaction(callReactions),
                onTalk: _openDialogue,
                onObserve: _observe,
                onSleep: _sleepUntilTomorrow,
              ),
            ],
          ),
        ),
      ),
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
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: '回忆',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '设置'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalDaysTogether, required this.onSettings});

  final int totalDaysTogether;
  final VoidCallback onSettings;

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
          IconButton.filledTonal(
            key: const Key('settings-button'),
            tooltip: '设置',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
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
  });

  final String season;
  final int year;
  final int month;
  final int day;

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
          Text(
            '$season｜第 $year 年・$month 月 $day 日',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
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
    required this.isExhausted,
    required this.affectionLevel,
    required this.affectionProgress,
    required this.energy,
    required this.onTap,
  });

  final CharacterReaction? reaction;
  final bool isReacting;
  final String moodLabel;
  final bool isExhausted;
  final int affectionLevel;
  final int affectionProgress;
  final int energy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayReaction =
        reaction ??
        const CharacterReaction(
          emotion: NanheEmotion.calm,
          nanheSpeech: '南河？',
          meaning: '轻轻点我试试看。',
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: frost,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7E8FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F3155C6),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 48, 12, 118),
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
                    child: Image.asset(
                      'assets/images/mini_nanhe.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
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
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _ReactionBubble(reaction: displayReaction),
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
  const _ReactionBubble({required this.reaction});

  final CharacterReaction reaction;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(reaction),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xF5FFFFFF),
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
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isExhausted,
    required this.onCall,
    required this.onTalk,
    required this.onObserve,
    required this.onSleep,
  });

  final bool isExhausted;
  final VoidCallback onCall;
  final VoidCallback onTalk;
  final VoidCallback onObserve;
  final VoidCallback onSleep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text('想和他做什么？', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        if (isExhausted)
          _ActionButton(
            key: const Key('sleep-button'),
            icon: Icons.bedtime_outlined,
            label: '睡觉',
            emphasized: true,
            onPressed: onSleep,
          )
        else
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  key: const Key('call-button'),
                  icon: Icons.campaign_outlined,
                  label: '呼唤',
                  onPressed: onCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  key: const Key('talk-button'),
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '聊天',
                  emphasized: true,
                  onPressed: onTalk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  key: const Key('observe-button'),
                  icon: Icons.visibility_outlined,
                  label: '观察',
                  onPressed: onObserve,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 20), const SizedBox(height: 3), Text(label)],
    );

    if (emphasized) {
      return FilledButton(onPressed: onPressed, child: child);
    }

    return FilledButton.tonal(onPressed: onPressed, child: child);
  }
}

class _DialogueSheet extends StatelessWidget {
  const _DialogueSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('和南河聊聊', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '先选一个简单的话题。未来会由事件与成长阶段决定对话。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            _DialogueChoice(label: '问问他今天的心情', reaction: dialogueReactions[0]),
            _DialogueChoice(label: '聊聊最近发生的事', reaction: dialogueReactions[1]),
            _DialogueChoice(
              label: '什么也不说，只是陪着他',
              reaction: dialogueReactions[2],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogueChoice extends StatelessWidget {
  const _DialogueChoice({required this.label, required this.reaction});

  final String label;
  final CharacterReaction reaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, reaction),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.volume_up_outlined),
              title: Text('音效'),
              subtitle: Text('雏形阶段尚未加入声音'),
              trailing: Switch(value: true, onChanged: null),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.save_outlined),
              title: Text('本机存档'),
              subtitle: Text('将在 EPIC 7 实作'),
            ),
          ],
        ),
      ),
    );
  }
}
