enum NanheEmotion {
  happy,
  calm,
  sad,
  angry,
  frustrated,
  curious,
  affectionate,
  sleepy,
}

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

const petReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '你来啦！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河！',
    meaning: '再摸摸也可以！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '怎么了？',
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
    meaning: '正在安静地看着周围。',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～',
    meaning: '他偷偷看了你一眼。',
  ),
];

const walkReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '想去外面看看！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河？',
    meaning: '这里闻起来不一样。',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '慢慢走也很好。',
  ),
];

const feedReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '好吃！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河～',
    meaning: '想再吃一点。',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '这是什么味道？',
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

const hitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.angry,
    nanheSpeech: '南河！南河！！',
    meaning: '不要这样！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '他缩了起来，不知道该怎么办。',
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……南河……',
    meaning: '好痛……为什么？',
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
