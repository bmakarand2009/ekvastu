#!/bin/bash

# VVP - Vastu Virtual Planner Launch Script
echo "===== VVP - Vastu Virtual Planner ====="
echo "Starting app setup..."

# Set Flutter path
export PATH="$HOME/Downloads/flutter/bin:$PATH"

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Run the app
echo "Launching app..."
flutter run

echo "If the app doesn't start, please make sure Flutter is correctly installed."
echo "Path to Flutter: $HOME/Downloads/flutter/bin"
