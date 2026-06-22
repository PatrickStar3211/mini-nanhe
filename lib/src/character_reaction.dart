enum NanheEmotion { happy, calm, sad, curious, affectionate }

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
    meaning: '你來啦！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.affectionate,
    nanheSpeech: '南河～南河！',
    meaning: '再陪我一會吧！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？',
    meaning: '怎麼了？',
  ),
];

const callReactions = <CharacterReaction>[
  CharacterReaction(
    emotion: NanheEmotion.happy,
    nanheSpeech: '南河！',
    meaning: '我在這裡！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河？南河？',
    meaning: '是在叫我嗎？',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '聽見了。',
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
    meaning: '正在安靜地看著窗外。',
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
    meaning: '今天很開心，因為你有來！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.curious,
    nanheSpeech: '南河……南河！',
    meaning: '外面的世界很大，以後一起去看看吧！',
  ),
  CharacterReaction(
    emotion: NanheEmotion.calm,
    nanheSpeech: '南河～',
    meaning: '安靜地待在一起也很好。',
  ),
];
