import 'package:flutter_test/flutter_test.dart';
import 'package:mini_nanhe/src/character_reaction.dart';
import 'package:mini_nanhe/src/reaction_rules.dart';

const _normal = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: false,
  hasHighTrust: false,
  hasHighAffection: false,
  hasLowAffection: false,
  isDirty: false,
  isSick: false,
  isInjured: false,
  isLateNight: false,
);

const _hurtAndWary = ReactionContext(
  isTired: false,
  hasHighPressure: true,
  hasLowTrust: true,
  hasHighTrust: false,
  hasHighAffection: false,
  hasLowAffection: true,
  isDirty: false,
  isSick: false,
  isInjured: true,
  isLateNight: false,
);

const _sickAndWary = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: true,
  hasHighTrust: false,
  hasHighAffection: false,
  hasLowAffection: true,
  isDirty: true,
  isSick: true,
  isInjured: false,
  isLateNight: false,
);

const _tired = ReactionContext(
  isTired: true,
  hasHighPressure: false,
  hasLowTrust: false,
  hasHighTrust: false,
  hasHighAffection: false,
  hasLowAffection: false,
  isDirty: false,
  isSick: false,
  isInjured: false,
  isLateNight: false,
);

const _lowTrustOnly = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: true,
  hasHighTrust: false,
  hasHighAffection: false,
  hasLowAffection: true,
  isDirty: false,
  isSick: false,
  isInjured: false,
  isLateNight: false,
);

const _highBond = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: false,
  hasHighTrust: true,
  hasHighAffection: true,
  hasLowAffection: false,
  isDirty: false,
  isSick: false,
  isInjured: false,
  isLateNight: false,
);

const _cleanComfortableNight = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: false,
  hasHighTrust: true,
  hasHighAffection: true,
  hasLowAffection: false,
  isDirty: false,
  isSick: false,
  isInjured: false,
  isLateNight: true,
);

const _dirtyButTrusting = ReactionContext(
  isTired: false,
  hasHighPressure: false,
  hasLowTrust: false,
  hasHighTrust: true,
  hasHighAffection: true,
  hasLowAffection: false,
  isDirty: true,
  isSick: false,
  isInjured: false,
  isLateNight: false,
);

void _expectOnlyEmotions(
  List<CharacterReaction> reactions,
  Set<NanheEmotion> allowed,
) {
  for (final reaction in reactions) {
    expect(allowed, contains(reaction.emotion), reason: reaction.meaning);
  }
}

void main() {
  test(
    'injured wary state blocks active interactions from cheerful reactions',
    () {
      const activeActions = {
        ReactionAction.play,
        ReactionAction.walk,
        ReactionAction.study,
        ReactionAction.exercise,
        ReactionAction.game,
        ReactionAction.create,
        ReactionAction.perform,
        ReactionAction.outing,
      };

      for (final action in activeActions) {
        final reactions = selectContextualReactions(action, _hurtAndWary);
        expect(reactions, same(injuredActivityReactions), reason: action.name);
        _expectOnlyEmotions(reactions, {
          NanheEmotion.sad,
          NanheEmotion.frustrated,
        });
      }
    },
  );

  test(
    'sick wary state blocks active interactions from energetic reactions',
    () {
      const activeActions = {
        ReactionAction.play,
        ReactionAction.walk,
        ReactionAction.study,
        ReactionAction.exercise,
        ReactionAction.game,
        ReactionAction.create,
        ReactionAction.perform,
        ReactionAction.outing,
      };

      for (final action in activeActions) {
        final reactions = selectContextualReactions(action, _sickAndWary);
        expect(reactions, same(sickActivityReactions), reason: action.name);
        _expectOnlyEmotions(reactions, {NanheEmotion.sad, NanheEmotion.sleepy});
      }
    },
  );

  test('care interactions stay cautious instead of suddenly intimate', () {
    for (final action in {ReactionAction.pet, ReactionAction.bath}) {
      expect(
        selectContextualReactions(action, _hurtAndWary),
        same(injuredCareReactions),
        reason: action.name,
      );
      expect(
        selectContextualReactions(action, _sickAndWary),
        same(sickCareReactions),
        reason: action.name,
      );
    }

    expect(
      selectContextualReactions(ReactionAction.feed, _sickAndWary),
      same(sickFeedReactions),
    );
  });

  test('tired state keeps active reactions sleepy', () {
    final expected = {
      ReactionAction.chat: tiredChatReactions,
      ReactionAction.pet: tiredPetReactions,
      ReactionAction.play: tiredPlayReactions,
      ReactionAction.walk: tiredWalkReactions,
      ReactionAction.study: tiredStudyReactions,
      ReactionAction.exercise: tiredExerciseReactions,
      ReactionAction.game: tiredGameReactions,
      ReactionAction.create: tiredCreateReactions,
    };

    for (final entry in expected.entries) {
      expect(
        selectContextualReactions(entry.key, _tired),
        same(entry.value),
        reason: entry.key.name,
      );
      _expectOnlyEmotions(
        entry.value,
        entry.key == ReactionAction.walk
            ? {NanheEmotion.sleepy}
            : {NanheEmotion.sleepy},
      );
    }
  });

  test('low trust alone is not treated as post-harm wary state', () {
    expect(
      selectContextualReactions(ReactionAction.play, _lowTrustOnly),
      same(playReactions),
    );
    expect(
      selectContextualReactions(ReactionAction.walk, _lowTrustOnly),
      same(lowTrustWalkReactions),
    );
  });

  test('high bond state uses intimate reactions where they exist', () {
    final expected = {
      ReactionAction.pet: highBondPetReactions,
      ReactionAction.perform: highBondPerformReactions,
      ReactionAction.outing: highBondOutingReactions,
    };

    for (final entry in expected.entries) {
      final reactions = selectContextualReactions(entry.key, _highBond);
      expect(reactions, same(entry.value), reason: entry.key.name);
      _expectOnlyEmotions(reactions, {
        NanheEmotion.happy,
        NanheEmotion.affectionate,
      });
    }
  });

  test(
    'healthy high bond state keeps ordinary positive-capable interactions',
    () {
      final expected = {
        ReactionAction.chat: dialogueReactions,
        ReactionAction.observe: observeReactions,
        ReactionAction.play: playReactions,
        ReactionAction.walk: walkReactions,
        ReactionAction.feed: feedReactions,
        ReactionAction.study: studyReactions,
        ReactionAction.exercise: exerciseReactions,
        ReactionAction.game: gameReactions,
        ReactionAction.create: createReactions,
        ReactionAction.bath: bathReactions,
      };

      for (final entry in expected.entries) {
        final reactions = selectContextualReactions(entry.key, _highBond);
        expect(reactions, equals(entry.value), reason: entry.key.name);
        expect(
          reactions,
          isNot(
            anyOf(
              same(injuredActivityReactions),
              same(sickActivityReactions),
              same(waryActivityReactions),
              same(injuredCareReactions),
              same(sickCareReactions),
              same(lowTrustCareReactions),
            ),
          ),
          reason: entry.key.name,
        );
      }
    },
  );

  test('positive care states route to gentle positive care reactions', () {
    expect(
      selectContextualReactions(ReactionAction.bath, _dirtyButTrusting),
      same(dirtyBathReactions),
    );
    expect(
      selectContextualReactions(ReactionAction.rest, _cleanComfortableNight),
      same(lateRestReactions),
    );
  });

  test('normal state still uses ordinary reactions', () {
    final expected = {
      ReactionAction.chat: dialogueReactions,
      ReactionAction.pet: petReactions,
      ReactionAction.observe: observeReactions,
      ReactionAction.play: playReactions,
      ReactionAction.walk: walkReactions,
      ReactionAction.feed: feedReactions,
      ReactionAction.rest: [restReaction],
      ReactionAction.study: studyReactions,
      ReactionAction.exercise: exerciseReactions,
      ReactionAction.game: gameReactions,
      ReactionAction.create: createReactions,
      ReactionAction.perform: performReactions,
      ReactionAction.bath: bathReactions,
      ReactionAction.outing: outingReactions,
    };

    for (final entry in expected.entries) {
      expect(
        selectContextualReactions(entry.key, _normal),
        equals(entry.value),
        reason: entry.key.name,
      );
    }
  });
}
