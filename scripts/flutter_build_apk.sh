#!/bin/bash
echo 'building release apk'
# move to dir of this script
cd "$(dirname "$0")"
cd .. || exit
flutter build apk
open build/app/outputs/flutter-apk/
