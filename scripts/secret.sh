#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"

# Can not use separators [/, :, @]
cat $REPOSITORY_DIR/Yomiage/Config/Secret.swift.sample | sed \
   -e "s|\[GOOGLE_TEXT_TO_SPEECH_API_KEY\]|$GOOGLE_TEXT_TO_SPEECH_API_KEY|g" \
> $REPOSITORY_DIR/Yomiage/Config/Secret.swift

echo

