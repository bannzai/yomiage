#!/bin/bash
set -eu

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"

echo "Log: BUNDLE IDENTIFIER: $CI_BUNDLE_ID"
if [[ $CI_BUNDLE_ID = 'com.bannzai.yomiage.dev' ]]; then
  echo "Log: Replace Release.xcconfig"
  sed -i '' -e 's/Production.xcconfig/Development.xcconfig/g' $REPOSITORY_DIR/Yomiage/Config/Release.xcconfig
fi
