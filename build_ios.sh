#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Building ZoomView iOS IPA (release, no-codesign)..."
echo ""

# Fix Flutter 3.41 arm64e bug: force architecture to arm64
export FLUTTER_XCODE_ARCHS=arm64

# Clean previous build artifacts
echo "🧹 Cleaning previous build..."
rm -rf ios/Flutter/ephemeral
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build IPA (archive) without code signing
echo "🔨 Building iOS archive (no-codesign)..."
flutter build ipa --release --no-codesign

echo ""
echo "✅ Archive completed!"
echo "📂 Archive: build/ios/archive/Runner.xcarchive"
echo ""

# Package .ipa from the archive
echo "📦 Packaging IPA..."
rm -rf build/ios/ipa
mkdir -p build/ios/ipa/Payload
cp -r build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app build/ios/ipa/Payload/
cd build/ios/ipa && zip -r ../ZoomView.ipa Payload
cd "$SCRIPT_DIR"

echo ""
echo "🎉 Done! IPA file: build/ios/ZoomView.ipa"
echo ""
echo "⚠️  注意: --no-codesign 打出的包没有签名，无法直接安装到真机。"
echo "   如需安装到真机测试，请："
echo "   1. 在 Xcode 中配置 DEVELOPMENT_TEAM（Apple 开发者团队 ID）"
echo "   2. 改用 flutter build ipa --release 或在 Xcode 中 Archive"
