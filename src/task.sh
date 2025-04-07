#!/bin/bash

# Execute task commands as they areon behalf of coinmaster

# TESTS: FAIL

# FIXME:

# TODO:
# [ ] load and override variables TASKDATA and TASKRC
# [ ] 

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
COINRC="$ROOT/cfg/.taskrc"
COINDATA="$COINDATA"

main() {
  load_config
  check_files
  run_task $ARGS
}

run_task() {
  TASKRC="$COINRC"
  TASKDATA="$COINDATA"
  # >&2 echo "executing \`task $@\`"
  task $@
}

main
