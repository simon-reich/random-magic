# Random Magic

Discover Magic: The Gathering cards by swiping through randomised results from the Scryfall API.

## Features

- Swipe left/right through random MTG cards with full-screen artwork
- Filter by colour, type, rarity, and release date — save filters as named presets
- Save cards to Favourites, browse in a grid, swipe through them individually
- Card detail view with prices (USD/EUR), format legalities, and double-faced card support

## Install (Android)

Download the latest APK from [Releases](https://github.com/simon-reich/random-magic/releases), enable *Install from unknown sources* on your device, and open the file.

## Tech Stack

Flutter · Riverpod · Hive CE · Dio · GoRouter · Scryfall API

## Development

```bash
flutter pub get
flutter run
flutter test
```

Requires Flutter stable channel. No API key needed — Scryfall is open.
