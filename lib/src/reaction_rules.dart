import 'character_reaction.dart';

enum ReactionAction {
  chat,
  pet,
  observe,
  play,
  walk,
  feed,
  rest,
  study,
  exercise,
  game,
  create,
  perform,
  bath,
  outing,
}

class ReactionContext {
  const ReactionContext({
    required this.isTired,
    required this.hasHighPressure,
    required this.hasLowTrust,
    required this.hasHighTrust,
    required this.hasHighAffection,
    required this.hasLowAffection,
    required this.isDirty,
    required this.isSick,
    required this.isInjured,
    required this.isLateNight,
  });

  final bool isTired;
  final bool hasHighPressure;
  final bool hasLowTrust;
  final bool hasHighTrust;
  final bool hasHighAffection;
  final bool hasLowAffection;
  final bool isDirty;
  final bool isSick;
  final bool isInjured;
  final bool isLateNight;

  bool get isWary =>
      hasLowTrust &&
      hasLowAffection &&
      (hasHighPressure || isInjured || isSick);

  bool get isEarlyWary => hasLowTrust && hasLowAffection;
}

List<CharacterReaction>? _activityBlock(ReactionContext context) {
  if (context.isInjured) return injuredActivityReactions;
  if (context.isSick) return sickActivityReactions;
  if (context.isWary) return waryActivityReactions;
  return null;
}

List<CharacterReaction>? _careCaution(ReactionContext context) {
  if (context.isInjured) return injuredCareReactions;
  if (context.isSick) return sickCareReactions;
  if (context.isWary) return lowTrustCareReactions;
  return null;
}

List<CharacterReaction> selectContextualReactions(
  ReactionAction action,
  ReactionContext context,
) {
  switch (action) {
    case ReactionAction.chat:
      if (context.isInjured && context.isWary) return injuredActivityReactions;
      if (context.isSick && context.isWary) return sickActivityReactions;
      if (context.hasHighPressure) return highPressureChatReactions;
      if (context.isTired) return tiredChatReactions;
      if (context.isEarlyWary) return lowTrustChatReactions;
      return dialogueReactions;
    case ReactionAction.pet:
      final caution = _careCaution(context);
      if (caution != null) return caution;
      if (context.isTired) return tiredPetReactions;
      if (context.isEarlyWary) return lowTrustPetReactions;
      if (context.hasHighAffection && context.hasHighTrust) {
        return highBondPetReactions;
      }
      return petReactions;
    case ReactionAction.observe:
      if (context.isInjured) return injuredObserveReactions;
      if (context.isSick) return sickObserveReactions;
      if (context.hasHighPressure) return highPressureObserveReactions;
      if (context.isEarlyWary) return lowTrustObserveReactions;
      return observeReactions;
    case ReactionAction.play:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredPlayReactions;
      if (context.hasHighPressure) return highPressurePlayReactions;
      return playReactions;
    case ReactionAction.walk:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredWalkReactions;
      if (context.hasLowTrust) return lowTrustWalkReactions;
      return walkReactions;
    case ReactionAction.feed:
      if (context.isSick) return sickFeedReactions;
      final caution = _careCaution(context);
      if (caution != null) return caution;
      if (context.hasHighPressure) return highPressureFeedReactions;
      if (context.isEarlyWary) return lowTrustFeedReactions;
      return feedReactions;
    case ReactionAction.rest:
      if (context.hasHighPressure) return highPressureRestReactions;
      if (context.isLateNight) return lateRestReactions;
      if (context.isEarlyWary) return lowTrustRestReactions;
      return [restReaction];
    case ReactionAction.study:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredStudyReactions;
      if (context.hasHighPressure) return highPressureStudyReactions;
      return studyReactions;
    case ReactionAction.exercise:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredExerciseReactions;
      if (context.hasHighPressure) return highPressureExerciseReactions;
      return exerciseReactions;
    case ReactionAction.game:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredGameReactions;
      if (context.hasHighPressure) return highPressureGameReactions;
      return gameReactions;
    case ReactionAction.create:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.isTired) return tiredCreateReactions;
      if (context.hasHighPressure) return highPressureCreateReactions;
      return createReactions;
    case ReactionAction.perform:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.hasLowTrust) return lowTrustPerformReactions;
      if (context.hasHighAffection && context.hasHighTrust) {
        return highBondPerformReactions;
      }
      return performReactions;
    case ReactionAction.bath:
      final caution = _careCaution(context);
      if (caution != null) return caution;
      if (context.hasLowTrust) return lowTrustBathReactions;
      if (context.isDirty) return dirtyBathReactions;
      return bathReactions;
    case ReactionAction.outing:
      final block = _activityBlock(context);
      if (block != null) return block;
      if (context.hasLowTrust) return lowTrustOutingReactions;
      if (context.hasHighAffection && context.hasHighTrust) {
        return highBondOutingReactions;
      }
      return outingReactions;
  }
}
