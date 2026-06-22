import 'dart:math';

import 'package:flutter/material.dart';

import 'character_reaction.dart';
import 'theme.dart';

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

  void _showReaction(List<CharacterReaction> responses) {
    final available = responses.length > 1
        ? responses.where((response) => response != _reaction).toList()
        : responses;
    setState(() {
      _reaction = available[_random.nextInt(available.length)];
      _isReacting = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (mounted) setState(() => _isReacting = false);
    });
  }

  void _observe() {
    _showReaction(observeReactions);
  }

  Future<void> _openDialogue() async {
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
          meaning: '回憶功能之後才會開放。',
        ),
      ]);
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
              _Header(onSettings: _showSettings),
              const SizedBox(height: 8),
              const _CalendarCard(),
              const SizedBox(height: 12),
              Expanded(
                child: _CharacterStage(
                  reaction: _reaction,
                  isReacting: _isReacting,
                  onTap: () => _showReaction(tapReactions),
                ),
              ),
              const SizedBox(height: 12),
              _ActionPanel(
                onCall: () => _showReaction(callReactions),
                onTalk: _openDialogue,
                onObserve: _observe,
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
            label: '回憶',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '設定'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});

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
                  '迷你期 · 第 12 天',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            key: const Key('settings-button'),
            tooltip: '設定',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: blueMist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_florist_outlined, color: deepBlue, size: 19),
          SizedBox(width: 8),
          Text(
            '春｜第 1 年・1 月 12 日',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Spacer(),
          Icon(Icons.calendar_today_outlined, color: mutedInk, size: 16),
        ],
      ),
    );
  }
}

class _CharacterStage extends StatelessWidget {
  const _CharacterStage({
    required this.reaction,
    required this.isReacting,
    required this.onTap,
  });

  final CharacterReaction? reaction;
  final bool isReacting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                const SizedBox(height: 14),
                const _MoodChip(),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '迷你南河，點擊互動',
                    child: InkWell(
                      key: const Key('character-tap-area'),
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
                const Text(
                  '迷你南河',
                  style: TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reaction == null ? '輕點角色，看看他現在想說什麼' : '可以繼續和他互動',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (reaction != null)
            Positioned(
              left: 18,
              right: 18,
              top: 54,
              child: _ReactionBubble(reaction: reaction!),
            ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: blueMist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: azure, size: 9),
          SizedBox(width: 7),
          Text(
            '心情很好',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
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
          borderRadius: BorderRadius.circular(18),
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
    required this.onCall,
    required this.onTalk,
    required this.onObserve,
  });

  final VoidCallback onCall;
  final VoidCallback onTalk;
  final VoidCallback onObserve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text('想和他做什麼？', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                key: const Key('call-button'),
                icon: Icons.campaign_outlined,
                label: '呼喚',
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
                label: '觀察',
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
              '先選一個簡單的話題。未來會由事件與成長階段決定對話。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            _DialogueChoice(label: '問問他今天的心情', reaction: dialogueReactions[0]),
            _DialogueChoice(label: '聊聊最近發生的事', reaction: dialogueReactions[1]),
            _DialogueChoice(
              label: '什麼也不說，只是陪著他',
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
            Text('設定', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.volume_up_outlined),
              title: Text('音效'),
              subtitle: Text('雛形階段尚未加入聲音'),
              trailing: Switch(value: true, onChanged: null),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.save_outlined),
              title: Text('本機存檔'),
              subtitle: Text('將在 EPIC 7 實作'),
            ),
          ],
        ),
      ),
    );
  }
}
