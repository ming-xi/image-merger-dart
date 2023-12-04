#!/bin/bash
echo 'building release ipa'
# move to dir of this script
cd "$(dirname "$0")"
cd .. || exit
flutter build ipa --release --export-method=ad-hoc
