#!/bin/bash
set -eu

SCRIPT_DIR="$(cd `dirname $0` && pwd -P)"
REPOSITORY_DIR="$(cd $SCRIPT_DIR && cd .. && pwd -P)"

cd $REPOSITORY_DIR
make secret
cd -
