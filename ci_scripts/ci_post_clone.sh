#!/bin/bash
set -eu

make secret

if [[ $CI_BUNDLE_ID = 'com.bannzai.yomiage.dev' ]]; then
  sed -i 's/"Production.xcconfig"/"Development.xcconfig"/g' Yomiage/Config/Release.xcocnfig
fi