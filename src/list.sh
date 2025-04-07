#!/bin/bash

# TODO DESC

# TESTS: FAIL

# FIXME:

# TODO:
# [ ] load and override variables TASKDATA and TASKRC
# [ ] 

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )
ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
COINRC="$ROOT/cfg/.taskrc"
COINDATA="$COINDATA"

main() {
  load_config
  check_rc_file_exists
  check_data_file_exists
  run_task
}

load_config() {
  >&2 echo "list.sh: LOADING CONFIG (sim)"
}

check_rc_file_exists() {
  >&2 echo "checking rc file exists"
}

check_data_file_exists() {
  >&2 echo "checking data file exists"
}

run_task() {
  TASKRC="$COINRC"
  TASKDATA="$COINDATA"
  task
}

main
