#!/bin/bash

# Add a recurring bill to taskchampion.db

# TESTS: FAIL

# FIXME:

# TODO:
# [ ] 

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
TASKRC="$ROOT/cfg/.taskrc"
TASKDATA="$COINDATA/bills"
SUCCESS=0

main() {
  # load_config
  # check_files
  if [[ -z "$ARGS" ]]; then add_bill_interactively; fi
  if [[ -n "$ARGS" ]]; then add_bill "$ARGS" ; fi
  # if SUCCESS=1, run update_timestamp NOT IMPLEMENTED
}

edit_new_bill() {
  task add 'new bill'
  last_insert_id=$(task export last_insert | jq '.[].id')
  task edit $last_insert_id
  # if successful set SUCCESS=1
}

add_bill() {
  task add $@
}

add_bill_interactively() {
    warn "Define proj, amount, recur, due, payee, priority, and desc:"
    task=$(txtin)
    task add $task
}

warn() { echo -e "\e[33m$@\e[0m"; }

main
