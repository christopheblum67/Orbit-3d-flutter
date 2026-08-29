#!/bin/bash
set -e
echo '=== 1. COMPILATION RUST FFI ==='
cd native
cargo ndk -t arm64-v8a -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
cd ..
echo '=== 2. BUILD FLUTTER APK ==='
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm64
