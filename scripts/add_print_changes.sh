#!/bin/zsh

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_ROOT_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"

find "$REPOSITORY_ROOT_DIR" -name "*.swift" -exec sed -i '' '/var body: some View {/a\
let _ = Self._printChanges()
' {} \;
