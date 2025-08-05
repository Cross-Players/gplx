#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get the project root directory (one level up from ios)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create a temporary directory with a simple name
TEMP_DIR="/tmp/gplx_temp"
mkdir -p "$TEMP_DIR"

echo "Copying project to temporary directory..."
rm -rf "$TEMP_DIR/gplx"
cp -R "$PROJECT_ROOT" "$TEMP_DIR/"

echo "Building in temporary directory..."
cd "$TEMP_DIR/gplx" || exit 1

# Clean and prepare the build
flutter clean
flutter pub get
cd ios || exit 1
pod install
cd .. || exit 1

# Build the app
flutter build ios --no-codesign

# Copy the built app back to the original location if the build was successful
if [ $? -eq 0 ]; then
    echo "Build successful! Copying app back to original location..."
    mkdir -p "$PROJECT_ROOT/build/ios/iphoneos/"
    cp -R "build/ios/iphoneos/Runner.app" "$PROJECT_ROOT/build/ios/iphoneos/"
    echo "Build completed successfully!"
else
    echo "Build failed!"
    exit 1
fi
