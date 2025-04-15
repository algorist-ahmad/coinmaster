#!/bin/bash

# Execute task commands as they are on behalf of coinmaster

# STATUS: FLAGGED FOR REMOVAL
# TESTS:  FAIL

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
TASKRC="$ROOT/cfg/.taskrc"
TASKDATA="$COINDATA/txn"

main() {
  load_config
  check_files
  run_task $ARGS
}

run_task() {
  # >&2 echo "executing \`task $@\`"
  task $@
}

main
