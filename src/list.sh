#!/bin/bash

# TODO DESC

# TESTS: FAIL

# FIXME:

# TODO:
# [ ] load and override variables TASKDATA and TASKRC
# [ ] 

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
TASKRC="$ROOT/cfg/.taskrc"
TASKDATA="$COINDATA"

main() {
  load_config
  verify_files
  task
}

main
