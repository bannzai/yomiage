#!/bin/bash
set -eu

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"

cd $REPOSITORY_DIR
make secret
cd -

echo "BUNDLE IDENTIFIER: $CI_BUNDLE_ID"
if [[ $CI_BUNDLE_ID = 'com.bannzai.yomiage.dev' ]]; then
  sed -i '' -e 's/Production.xcconfig/Development.xcconfig/g' $REPOSITORY_DIR/Yomiage/Config/Release.xcconfig
fi
