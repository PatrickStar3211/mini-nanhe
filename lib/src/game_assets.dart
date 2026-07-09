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
const collectionAlbumAsset = 'assets/images/collection/collection_album.webp';
const openingStoryPage1Asset =
    'assets/images/story/opening/opening_page_1.webp';
const openingStoryPage2Asset =
    'assets/images/story/opening/opening_page_2.webp';
const openingStoryPage3Asset =
    'assets/images/story/opening/opening_page_3.webp';
const feedingStoryPage1Asset = 'assets/images/story/feeding/feeding_page_1.png';
const feedingStoryPage2CurryAsset =
    'assets/images/story/feeding/feeding_page_2.png';
const feedingStoryPage2VegetablesAsset =
    'assets/images/story/feeding/feeding_page_2_vegetables.png';
const feedingChoiceVegetablesAsset =
    'assets/images/story/feeding/feeding_choice_vegetables.png';
const feedingChoiceCurryAsset =
    'assets/images/story/feeding/feeding_choice_curry.png';

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
  miniNanheOriginalAsset,
  miniNanheTransparentAsset,
  miniNanheCalmAsset,
  miniNanheHappyAsset,
  miniNanheAffectionateAsset,
  miniNanheCuriousAsset,
  miniNanheSleepyAsset,
  miniNanheSadAsset,
  miniNanheAngryAsset,
  miniNanheFrustratedAsset,
  collectionAlbumAsset,
  ...openingStoryPageAssets,
  ...feedingStoryAssets,
];
