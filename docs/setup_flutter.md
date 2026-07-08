# Flutter Frontend Setup Guide

This guide covers setting up the Flutter environment to run the **Pinesphere Stay** offline-first client on Mobile (Android/iOS) and Web.

## Prerequisites

- **Dart SDK**: >= 3.1.0 < 4.0.0
- **Flutter SDK**: 3.13.0 or higher
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Chrome** (for Web debugging)

## 1. Install Flutter & Dart

1. Download the Flutter SDK from the [official website](https://docs.flutter.dev/get-started/install).
2. Extract the archive and add the `flutter/bin` directory to your system's `PATH`.
3. Run `flutter doctor` to verify your installation and resolve any missing platform dependencies (like Android SDK command-line tools).

## 2. Project Initialization

Navigate to the Flutter project directory:
```bash
cd pinesphere_stay
```

Fetch all dependencies:
```bash
flutter pub get
```

## 3. Code Generation (Required)

This project heavily utilizes code generation for state management (Riverpod), models (Freezed), routing (GoRouter), and local database (ObjectBox). 

**You MUST run the build_runner before running the app for the first time, or whenever you change annotated classes.**

Run the generator in one-time build mode:
```bash
dart run build_runner build -d
```
*Or, keep it watching for changes during active development:*
```bash
dart run build_runner watch -d
```

## 4. Running the App

### Running on Android/iOS (Emulator or Physical Device)
```bash
flutter run
```

### Running on Web (Development)
```bash
flutter run -d chrome
```

## 5. Building for Production

### Build Android APK / AppBundle
```bash
flutter build apk --release
flutter build appbundle --release
```

### Build Web (Wasm / HTML)
To build an optimized web production bundle:
```bash
flutter build web --release --web-renderer canvaskit
```
The compiled files will be in `build/web/`. You can serve them using any static web server (e.g., Nginx, Python http.server, etc.).

## Troubleshooting
- **ObjectBox Sync Errors**: Ensure you have the `objectbox_flutter_libs` package correctly fetched.
- **Generator Conflicts**: If `build_runner` fails with conflicting outputs, always use the `-d` (delete conflicting outputs) flag: `dart run build_runner build -d`.
