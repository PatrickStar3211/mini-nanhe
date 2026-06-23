# Mini Nanhe

`Mini Nanhe` is a non-commercial, unofficial fan-made character-raising game prototype built with Flutter for Android and Web.

The project explores a companion-style experience in which the character gradually grows through different life stages. Each stage can introduce, replace, or retire interactions, dialogue, events, and other features.

## Current prototype

- Tap the character for randomized reactions
- Call, chat with, and observe the character
- Dialogue choice panel
- In-game date, growth stage, and mood display
- Basic navigation and settings
- Local-first, with no paid service dependencies

## Run locally

1. Install Flutter and Android Studio.
2. Clone this repository.
3. Run `flutter pub get`.
4. Start an Android emulator or connect a device.
5. Run `flutter run`.

## Run on web

```sh
flutter run -d chrome
```

## GitHub Pages deployment

This repository includes a GitHub Actions workflow at `.github/workflows/deploy-web.yml`.

After pushing to `main`, enable GitHub Pages in the repository settings:

1. Open **Settings → Pages**.
2. Set **Source** to **GitHub Actions**.
3. Push to `main` again, or manually run **Deploy Flutter Web** from the Actions tab.

The workflow builds the web app with the repository name as the base path, so it works for a normal GitHub Pages project URL such as:

```text
https://<github-user>.github.io/<repository-name>/
```

## Checks

```sh
flutter analyze
flutter test
```

## Status

This project is in an early prototype and brainstorming stage. Features, artwork, and release plans may change.

## Disclaimer

This is a non-commercial, unofficial fan project. It is not affiliated with or endorsed by the original rights holders.
