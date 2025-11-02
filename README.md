# CP Arena

Aggregate upcoming competitive programming contests from all your favorite platforms in one clean, minimal app.

## Features

- **Multi-Platform**: Codeforces, LeetCode, AtCoder, CodeChef
- **Dark Mode**: Light/dark theme toggle
- **Smart Filtering**: Center-aligned filter dialog
- **Pull to Refresh**: Get latest contests instantly
- **Minimal Design**: Clean UI without traditional AppBar

## Quick Start

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Installation

```
git clone https://github.com/yourusername/cp_arena.git
cd cp_arena
flutter pub get
flutter run
```

## Dependencies

```
dependencies:
  http: ^1.1.0
```

## Platforms

- Android
- iOS (Coming Soon)

## Project Structure

```
lib/
├── main.dart
└── pages/
    └── home_page.dart
```

## API Sources

- Codeforces: https://codeforces.com/api/contest.list
- LeetCode: https://leetcode.com/graphql
- AtCoder: https://contest-hive.vercel.app/api/atcoder
- CodeChef: https://contest-hive.vercel.app/api/codechef

## Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:
```
<uses-permission android:name="android.permission.INTERNET"/>
```
