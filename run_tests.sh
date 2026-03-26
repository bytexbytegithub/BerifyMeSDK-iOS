#!/bin/bash

# Berify.me iOS Swift SDK test script
# This script runs the SDK tests

set -e

echo "🧪 Berify.me iOS Swift SDK test script"
echo "===================================="
echo ""

# Check we're in the correct directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Please run this script from the ios-sdk directory"
    exit 1
fi

# Check Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please ensure Xcode is installed"
    exit 1
fi

echo "📦 Project info:"
echo "  - Swift Package: BerifymeSDK"
echo "  - Test target: BerifymeSDKTests"
echo ""

# Get available iOS simulator
echo "📱 Finding available iOS simulator..."
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
if [ -z "$SIMULATOR" ]; then
    SIMULATOR="iPhone 15"
    echo "  ⚠️  No simulator found, using default: $SIMULATOR"
else
    echo "  ✅ Found simulator: $SIMULATOR"
fi

echo ""
echo "🔨 Building project..."
echo ""

# Build project
xcodebuild clean build \
    -scheme BerifymeSDK \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -quiet \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "🧪 Running tests..."
echo ""

# Run tests
xcodebuild test \
    -scheme BerifymeSDK \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -quiet \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
else
    echo ""
    echo "❌ Some tests failed"
    exit 1
fi

echo ""
echo "✨ Tests complete!"
