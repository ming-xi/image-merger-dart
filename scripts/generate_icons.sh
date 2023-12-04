#!/bin/bash
echo 'start building rust binaries'
# move to dir of this script
cd "$(dirname "$0")"
cd ..
flutter pub get
flutter pub run flutter_launcher_icons