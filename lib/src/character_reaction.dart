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

const sadHitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……？',
    meaning: '他明明想相信你，却害怕地退了一步。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……南河……',
    meaning: '他低下头，不知道自己做错了什么。',
    voice: NanheVoice.sadDouble,
  ),
];

const playReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '一起玩的时候，他整个人都亮了起来。',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～',
    meaning: '他开心地贴近了一点。',
    voice: NanheVoice.affectionSingle,
  ),
];

const studyReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河！',
    meaning: '他认真看着书页，像是理解了什么。',
    voice: NanheVoice.curiousDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '学习有点累，但他还是努力坚持着。',
    voice: NanheVoice.calmSingle,
  ),
];

const exerciseReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '运动之后，他看起来更有精神了。',
    voice: NanheVoice.affectionSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '训练消耗了不少体力。',
    voice: NanheVoice.sleepySingle,
  ),
];

const gameReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '他盯着画面，操作越来越熟练。',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河！',
    meaning: '他好像发现了新的打法。',
    voice: NanheVoice.curiousDouble,
  ),
];

const createReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河……',
    meaning: '他安静地试着把想法画出来。',
    voice: NanheVoice.curiousSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '完成作品后，他看起来很开心。',
    voice: NanheVoice.affectionSingle,
  ),
];

const performReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '他努力表现自己，虽然还有点紧张。',
    voice: NanheVoice.affectionDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '练习之后，他似乎更有自信了。',
    voice: NanheVoice.calmSingle,
  ),
];

const bathReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '洗完澡后，他身上有干净清爽的味道。',
    voice: NanheVoice.calmSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '他甩了甩水珠，看起来舒服多了。',
    voice: NanheVoice.affectionSingle,
  ),
];

const outingReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河？',
    meaning: '外面的东西让他忍不住四处张望。',
    voice: NanheVoice.curiousDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '出去走走之后，他的心情轻快了不少。',
    voice: NanheVoice.affectionSingle,
  ),
];

const highPressureChatReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '不要一直问我……',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……南河……',
    meaning: '我有点乱。',
    voice: NanheVoice.sadDouble,
  ),
];

const lowTrustChatReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '你想说什么？',
    voice: NanheVoice.curiousSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '我在听。',
    voice: NanheVoice.calmSingle,
  ),
];

const tiredChatReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '小声一点……',
    voice: NanheVoice.sleepySingle,
  ),
];

const lowTrustPetReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……？',
    meaning: '不要突然碰我。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '轻一点。',
    voice: NanheVoice.sadSingle,
  ),
];

const highBondPetReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河！',
    meaning: '再摸摸也可以！',
    voice: NanheVoice.affectionDouble,
  ),
];

const tiredPetReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河～',
    meaning: '摸摸可以，别吵醒我。',
    voice: NanheVoice.sleepySingle,
  ),
];

const injuredObserveReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '这里还痛。',
    voice: NanheVoice.sadSingle,
  ),
];

const sickObserveReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '不太舒服。',
    voice: NanheVoice.sadSingle,
  ),
];

const highPressureObserveReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……？',
    meaning: '别一直看我。',
    voice: NanheVoice.sadSingle,
  ),
];

const lowTrustObserveReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '他看了你一眼，又很快移开视线。',
    voice: NanheVoice.calmSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '別一直看我。',
    voice: NanheVoice.curiousSingle,
  ),
];

const injuredActivityReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '现在会痛。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……？',
    meaning: '一定要现在吗？',
    voice: NanheVoice.sadSingle,
  ),
];

const sickActivityReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '今天不想动。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '想躺一下。',
    voice: NanheVoice.sleepySingle,
  ),
];

const waryActivityReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '不想和你玩。',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '为什么要跟你去？',
    voice: NanheVoice.curiousSingle,
  ),
];

const injuredCareReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '轻一点。',
    voice: NanheVoice.sadSingle,
  ),
];

const sickCareReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '慢一点。',
    voice: NanheVoice.sleepySingle,
  ),
];

const lowTrustCareReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……？',
    meaning: '你要做什么？',
    voice: NanheVoice.sadSingle,
  ),
];

const tiredPlayReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '今天玩不动了。',
    voice: NanheVoice.sleepySingle,
  ),
];

const highPressurePlayReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '再来一次！',
    voice: NanheVoice.affectionDouble,
  ),
];

const lowTrustWalkReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '要去哪里？',
    voice: NanheVoice.curiousSingle,
  ),
];

const tiredWalkReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '走慢一点……',
    voice: NanheVoice.sleepySingle,
  ),
];

const sickFeedReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……',
    meaning: '吃不太下。',
    voice: NanheVoice.sadSingle,
  ),
];

const highPressureFeedReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '先放这里。',
    voice: NanheVoice.calmSingle,
  ),
];

const lowTrustFeedReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '……可以吃吗？',
    voice: NanheVoice.curiousSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河……',
    meaning: '他等你退开后，才慢慢靠近。',
    voice: NanheVoice.calmSingle,
  ),
];

const highPressureRestReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '想安静一下。',
    voice: NanheVoice.sleepySingle,
  ),
];

const lateRestReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河～',
    meaning: '就休息一下下。',
    voice: NanheVoice.sleepySingle,
  ),
];

const lowTrustRestReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '先不要靠太近。',
    voice: NanheVoice.sleepySingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河。',
    meaning: '他缩在纸箱里，安静了一会儿。',
    voice: NanheVoice.calmSingle,
  ),
];

const tiredStudyReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '字都在晃。',
    voice: NanheVoice.sleepySingle,
  ),
];

const highPressureStudyReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '现在不想学。',
    voice: NanheVoice.sadSingle,
  ),
];

const tiredExerciseReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……南河……',
    meaning: '腿软了。',
    voice: NanheVoice.sleepyDouble,
  ),
];

const highPressureExerciseReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '动起来会好一点！',
    voice: NanheVoice.affectionSingle,
  ),
];

const tiredGameReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '眼睛要闭上了。',
    voice: NanheVoice.sleepySingle,
  ),
];

const highPressureGameReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '这局能赢！',
    voice: NanheVoice.affectionDouble,
  ),
];

const tiredCreateReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '南河……',
    meaning: '明天再画。',
    voice: NanheVoice.sleepySingle,
  ),
];

const highPressureCreateReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河……',
    meaning: '乱乱的，也能画。',
    voice: NanheVoice.curiousSingle,
  ),
];

const lowTrustPerformReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……？',
    meaning: '一定要看吗？',
    voice: NanheVoice.sadSingle,
  ),
];

const highBondPerformReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '看好了！',
    voice: NanheVoice.affectionDouble,
  ),
];

const dirtyBathReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '干净了。',
    voice: NanheVoice.calmSingle,
  ),
];

const lowTrustBathReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……',
    meaning: '不要偷看。',
    voice: NanheVoice.sadSingle,
  ),
];

const lowTrustOutingReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '你会带我回来吗？',
    voice: NanheVoice.curiousSingle,
  ),
];

const highBondOutingReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！南河！',
    meaning: '一起出去！',
    voice: NanheVoice.affectionDouble,
  ),
];

const lowBondHitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.angry,
    nanheSpeech: '南河！！',
    meaning: '不要这样！',
    voice: NanheVoice.angryDouble,
  ),
  CharacterReaction(
    emotion: NanheEmotion.angry,
    nanheSpeech: '南河！南河！',
    meaning: '走开！',
    voice: NanheVoice.angryDouble,
  ),
];

const trustedHitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……？',
    meaning: '为什么是你？',
    voice: NanheVoice.sadSingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sad,
    nanheSpeech: '南河……南河……',
    meaning: '明明相信你的。',
    voice: NanheVoice.sadDouble,
  ),
];

const confusedHitReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.frustrated,
    nanheSpeech: '南河……？',
    meaning: '我做错了吗？',
    voice: NanheVoice.sadSingle,
  ),
];

const exhaustedReaction = CharacterReaction(
  emotion: NanheEmotion.sleepy,
  nanheSpeech: '南河……',
  meaning: '有点困了。',
  voice: NanheVoice.sleepySingle,
);

const restReaction = CharacterReaction(
  emotion: NanheEmotion.sleepy,
  nanheSpeech: '南河～',
  meaning: '他靠近你身边，安静地休息了一会儿。',
  voice: NanheVoice.sleepySingle,
);

const tooEarlyToSleepReaction = CharacterReaction(
  emotion: NanheEmotion.calm,
  nanheSpeech: '还没到睡觉的时候。',
  meaning: '再陪南河一会儿吧。',
  voice: NanheVoice.calmSingle,
);

const sleepReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '晚安，南河。',
    meaning: '你轻轻道别，屋子慢慢安静下来。',
    voice: NanheVoice.sleepySingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '灯被调暗了。',
    meaning: '南河缩进柔软的被子里，呼吸渐渐平稳。',
    voice: NanheVoice.sleepySingle,
  ),
  CharacterReaction(
    emotion: NanheEmotion.sleepy,
    nanheSpeech: '今天也辛苦了。',
    meaning: '你确认他已经睡好，才把门轻轻带上。',
    voice: NanheVoice.sleepySingle,
  ),
];

const wakeUpReaction = CharacterReaction(
  emotion: NanheEmotion.happy,
  nanheSpeech: '南河！南河！',
  meaning: '新的一天开始了！',
  voice: NanheVoice.affectionDouble,
);
