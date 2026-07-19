const defaultGardenDoghouseAsset = 'assets/images/default_garden_doghouse.png';
const loadingRainyBoxAsset = 'assets/images/loading_rainy_box.png';
const yardBackgroundAssetDirectory = 'assets/images/backgrounds';
const miniNanheOriginalAsset = 'assets/images/mini_nanhe.png';
const miniNanheTransparentAsset = 'assets/images/mini_nanhe_transparent.png';

const miniNanheCalmAsset = 'assets/images/nanhe_emotions/mini_nanhe_calm.png';
const miniNanheHappyAsset = 'assets/images/nanhe_emotions/mini_nanhe_happy.png';
const miniNanheAffectionateAsset =
    'assets/images/nanhe_emotions/mini_nanhe_affectionate.png';
const miniNanheCuriousAsset =
    'assets/images/nanhe_emotions/mini_nanhe_curious.png';
const miniNanheSleepyAsset =
    'assets/images/nanhe_emotions/mini_nanhe_sleepy.png';
const miniNanheSadAsset = 'assets/images/nanhe_emotions/mini_nanhe_sad.png';
const miniNanheAngryAsset = 'assets/images/nanhe_emotions/mini_nanhe_angry.png';
const miniNanheFrustratedAsset =
    'assets/images/nanhe_emotions/mini_nanhe_frustrated.png';
const miniNanheDeadAsset = 'assets/images/nanhe_emotions/mini_nanhe_dead.png';
const collectionAlbumAsset = 'assets/images/collection/collection_album.webp';
const openingStoryPage1Asset =
    'assets/images/story/opening/opening_page_1.webp';
const openingStoryPage2Asset =
    'assets/images/story/opening/opening_page_2.webp';
const openingStoryPage3Asset =
    'assets/images/story/opening/opening_page_3.webp';
const feedingStoryPage1Asset =
    'assets/images/story/feeding/feeding_page_1.webp';
const feedingStoryPage2CurryAsset =
    'assets/images/story/feeding/feeding_page_2.webp';
const feedingStoryPage2VegetablesAsset =
    'assets/images/story/feeding/feeding_page_2_vegetables.webp';
const feedingChoiceVegetablesAsset =
    'assets/images/story/feeding/feeding_choice_vegetables.webp';
const feedingChoiceCurryAsset =
    'assets/images/story/feeding/feeding_choice_curry.webp';
const curryFavoriteAchievementAsset =
    'assets/images/collection/achievement_curry_favorite.webp';
const sicknessStoryPage1Asset =
    'assets/images/story/sickness/sickness_page_1.webp';
const sicknessStoryPage2HotWaterAsset =
    'assets/images/story/sickness/sickness_page_2_hot_water.webp';
const sicknessStoryPage2CareAsset =
    'assets/images/story/sickness/sickness_page_2_care.webp';
const hotWaterAchievementAsset =
    'assets/images/collection/achievement_hot_water.webp';
const sickEndingBedAsset = 'assets/images/endings/mini_nanhe_sick_bed.webp';
const sickEndingOnsetPage1Asset =
    'assets/images/story/sick_ending/sick_ending_onset_page_1.webp';
const sickEndingOnsetPage2Asset =
    'assets/images/story/sick_ending/sick_ending_onset_page_2.webp';
const sickEndingFinalPage1Asset =
    'assets/images/story/sick_ending/sick_ending_final_page_1.webp';
const sickEndingFinalPage2Asset =
    'assets/images/story/sick_ending/sick_ending_final_page_2.webp';
const sickEndingFinalPage3Asset =
    'assets/images/story/sick_ending/sick_ending_final_page_3.webp';
const sickDeathAchievementAsset =
    'assets/images/collection/achievement_sick_death.webp';
const doghouseUnlockStoryPage1Asset =
    'assets/images/story/doghouse/doghouse_unlock_page_1.webp';
const luxuryUnlockStoryPage1Asset =
    'assets/images/story/luxury/luxury_unlock_page_1.webp';
const luxuryUnlockStoryPage2Asset =
    'assets/images/story/luxury/luxury_unlock_page_2.webp';
const abuseStoryPage1Asset = 'assets/images/story/abuse/abuse_page_1.png';
const roadsideOneAchievementAsset =
    'assets/images/collection/achievement_roadside_one.webp';

const openingStoryPageAssets = <String>[
  openingStoryPage1Asset,
  openingStoryPage2Asset,
  openingStoryPage3Asset,
];

const feedingStoryAssets = <String>[
  feedingStoryPage1Asset,
  feedingStoryPage2CurryAsset,
  feedingStoryPage2VegetablesAsset,
  feedingChoiceVegetablesAsset,
  feedingChoiceCurryAsset,
  curryFavoriteAchievementAsset,
];

const sicknessStoryAssets = <String>[
  sicknessStoryPage1Asset,
  sicknessStoryPage2HotWaterAsset,
  sicknessStoryPage2CareAsset,
  hotWaterAchievementAsset,
];

const doghouseUnlockStoryAssets = <String>[doghouseUnlockStoryPage1Asset];

const sickEndingOnsetStoryAssets = <String>[
  sickEndingOnsetPage1Asset,
  sickEndingOnsetPage2Asset,
];

const sickEndingFinalStoryAssets = <String>[
  sickEndingFinalPage1Asset,
  sickEndingFinalPage2Asset,
  sickEndingFinalPage3Asset,
];

const sickEndingStoryAssets = <String>[
  sickEndingBedAsset,
  ...sickEndingOnsetStoryAssets,
  ...sickEndingFinalStoryAssets,
];

const luxuryUnlockStoryAssets = <String>[
  luxuryUnlockStoryPage1Asset,
  luxuryUnlockStoryPage2Asset,
];

const abuseStoryAssets = <String>[
  abuseStoryPage1Asset,
  roadsideOneAchievementAsset,
];

String yardBackgroundAsset({
  required String home,
  required String season,
  required String timeOfDay,
}) {
  return '$yardBackgroundAssetDirectory/yard_${home}_${season}_$timeOfDay.webp';
}

const startupPreloadAssets = <String>[
  defaultGardenDoghouseAsset,
  loadingRainyBoxAsset,
  miniNanheCalmAsset,
  miniNanheHappyAsset,
  collectionAlbumAsset,
];

const deferredPreloadAssets = <String>[
  miniNanheOriginalAsset,
  miniNanheTransparentAsset,
  miniNanheAffectionateAsset,
  miniNanheCuriousAsset,
  miniNanheSleepyAsset,
  miniNanheSadAsset,
  miniNanheAngryAsset,
  miniNanheFrustratedAsset,
  miniNanheDeadAsset,
  ...openingStoryPageAssets,
  ...feedingStoryAssets,
  ...sicknessStoryAssets,
  ...sickEndingStoryAssets,
  ...doghouseUnlockStoryAssets,
  ...luxuryUnlockStoryAssets,
  ...abuseStoryAssets,
];
