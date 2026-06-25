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

enum NanheVoice {
  affectionDouble('audio/voice/nanhe_affection_double.mp3'),
  affectionSingle('audio/voice/nanhe_affection_single.mp3'),
  angryDouble('audio/voice/nanhe_angry_double.mp3'),
  angrySingle('audio/voice/nanhe_angry_single.mp3'),
  calmDouble('audio/voice/nanhe_calm_double.mp3'),
  calmSingle('audio/voice/nanhe_calm_single.mp3'),
  curiousDouble('audio/voice/nanhe_curious_double.mp3'),
  curiousSingle('audio/voice/nanhe_curious_single.mp3'),
  sadDouble('audio/voice/nanhe_sad_double.mp3'),
  sadSingle('audio/voice/nanhe_sad_single.mp3'),
  sleepyDouble('audio/voice/nanhe_sleepy_double.mp3'),
  sleepySingle('audio/voice/nanhe_sleepy_single.mp3');

  const NanheVoice(this.assetPath);

  final String assetPath;
}

class CharacterReaction {
  const CharacterReaction({
    required this.emotion,
    required this.nanheSpeech,
    required this.meaning,
    required this.voice,
  });

  final NanheEmotion emotion;
  final String nanheSpeech;
  final String meaning;
  final NanheVoice voice;
}

const petReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '你来啦！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河！',
    meaning: '再摸摸也可以！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '怎么了？',
    voice: NanheVoice.curiousSingle,
  ),
];

const observeReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '今天心情很好！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '正在安静地看着周围。',
    voice: NanheVoice.calmSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～',
    meaning: '他偷偷看了你一眼。',
    voice: NanheVoice.affectionSingle,
  ),
];

const walkReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '想去外面看看！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河？',
    meaning: '这里闻起来不一样。',
    voice: NanheVoice.curiousDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '慢慢走也很好。',
    voice: NanheVoice.calmSingle,
  ),
];

const feedReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '好吃！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河～',
    meaning: '想再吃一点。',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '这是什么味道？',
    voice: NanheVoice.curiousSingle,
  ),
];

const dialogueReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！(*^▽^*)',
    meaning: '今天很开心，因为你有来！',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河……南河！',
    meaning: '外面的世界很大，以后一起去看看吧！',
    voice: NanheVoice.curiousDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '安静地待在一起也很好。',
    voice: NanheVoice.calmSingle,
  ),
];

const hitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.angry,
    nanheSpeech: '南河！南河！！',
    meaning: '不要这样！',
    voice: NanheVoice.angryDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '他缩了起来，不知道该怎么办。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……南河……',
    meaning: '好痛……为什么？',
    voice: NanheVoice.sadDouble,
  ),
];

const exhaustedReaction = CharacterReaction(
  emotion: NanheEmotion.sleepy,
  nanheSpeech: '南河……',
  meaning: '有点困了。',
  voice: NanheVoice.sleepySingle,
);

const wakeUpReaction = CharacterReaction(
  emotion: NanheEmotion.happy,
  nanheSpeech: '南河！南河！',
  meaning: '新的一天开始了！',
  voice: NanheVoice.affectionDouble,
);
