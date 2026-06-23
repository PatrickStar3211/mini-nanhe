enum NanheEmotion { happy, calm, sad, curious, affectionate, sleepy }

class CharacterReaction {
  const CharacterReaction({
    required this.emotion,
    required this.nanheSpeech,
    required this.meaning,
  });

  final NanheEmotion emotion;
  final String nanheSpeech;
  final String meaning;
}

const tapReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '你来啦！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河！',
    meaning: '再陪我一会吧！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '怎么了？',
  ),
];

const callReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '我在这里！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河？',
    meaning: '是在叫我吗？',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '听见了。',
  ),
];

const observeReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '今天心情很好！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '正在安静地看着窗外。',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～',
    meaning: '他偷偷看了你一眼。',
  ),
];

const dialogueReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '今天很开心，因为你有来！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河……南河！',
    meaning: '外面的世界很大，以后一起去看看吧！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '安静地待在一起也很好。',
  ),
];

const exhaustedReaction = CharacterReaction(
  emotion: NanheEmotion.sleepy,
  nanheSpeech: '南河……',
  meaning: '有点困了。',
);

const wakeUpReaction = CharacterReaction(
  emotion: NanheEmotion.happy,
  nanheSpeech: '南河！南河！',
  meaning: '新的一天开始了！',
);
