#!/bin/bash
set -eu

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"


make secret

if [[ $CI_BUNDLE_ID = 'com.bannzai.yomiage.dev' ]]; then
  sed -i 's/"Production.xcconfig"/"Development.xcconfig"/g' $REPOSITORY_DIR/Yomiage/Config/Release.xcocnfig
fi
