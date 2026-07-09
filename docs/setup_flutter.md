# Pinesphere Stay Frontend Setup Guide

This guide details the setup instructions for the Pinesphere Stay Flutter application, designed with an offline-first architecture.

## Prerequisites
- **Dart SDK**: 3.x
- **Flutter SDK**: 3.13 or higher (Stable channel)
- **Android Studio / Xcode**: For running mobile emulators.

## 1. Flutter SDK Setup
If you haven't installed Flutter, follow the official documentation:
https://docs.flutter.dev/get-started/install

Verify your installation and ensure all toolchains are valid:
```bash
flutter doctor -v
```

## 2. Project Initialization
Navigate to the Flutter project directory and fetch all dependencies:

```bash
cd pinesphere_stay
flutter clean
flutter pub get
```

## 3. Code Generation (Crucial Step)
Pinesphere Stay relies heavily on code generation for State Management (Riverpod), Data Transfer Objects (Freezed/JSON Serializable), and Local Database entities (ObjectBox).

**You MUST run the build runner before launching the app:**

```bash
dart run build_runner build -d
```
*Note: The `-d` flag deletes conflicting outputs, which is highly recommended during branch switches or major entity updates.*

## 4. Running on Emulators / Devices

### Android / iOS
To run the application on a connected device or emulator:
```bash
flutter run
```

### Web Target
To run the dashboard on Chrome for rapid UI testing:
```bash
flutter run -d chrome
```

## 5. Building for Production

### Android APK / AppBundle
```bash
flutter build apk --release
flutter build appbundle --release
```

### Web Build
For deploying the admin dashboard to a web server:
```bash
flutter build web --web-renderer canvaskit --release
```

## 6. Database Schema (ObjectBox)
Because this is an offline-first app, ObjectBox is used heavily. 
Whenever you modify an `@Entity` class inside `lib/features/.../domain/`, you must regenerate the ObjectBox schema:
```bash
flutter clean
flutter pub get
dart run build_runner build -d
```
