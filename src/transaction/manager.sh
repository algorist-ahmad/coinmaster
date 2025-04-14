#!/bin/bash

# Query or update transactions database.
# Expected args: [filter] <command> [mods]

# STATUS: WORK IN PROGRESS - ISSUE 12, 13, AND 14
# TESTS:  FAIL

ROOT=$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")" )

source "$ROOT/src/transaction/forms.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
HELPFILE="$ROOT/src/transaction/help.txt"
TASKRC="$ROOT/cfg/.taskrc"
TASKDATA="$COINDATA/txn"

main() {
  dispatch $ARGS
}

dispatch() {
  case "$1" in
    help | --help | -h)   shift ; show_help ;;
    bill* | --bill | -b)  shift ; list_bills +bill "$@" ;; # ISSUE ??
    add | new)            shift ; insert_txn "$@"  ;;      # ISSUE 14
    log | -aa)            shift ; log_txn    "$@"  ;;      # ISSUE ??

    *) task "$@" ;;
  esac
}

show_help() { echo -e "$(cat $HELPFILE)" | less ; }

insert_txn() {
  if _empty "$@"
    then add_txn_interactively
    else task add "$@"
  fi
  
  # echo "
  # are there arguments or no?
  # If no args:
  #   Is it a recurring bill or a single transaction?

  # If single: skip recur attributes
  #   Has it been paid already?

  # If recurring:
  #   prompt for each attribute one by one, validate along the way
  # "
}

add_txn_interactively() {
  result=$(launch_transaction_form) # YAML expected
  echo $result
}

_empty() { [[ -z "$@" ]] ; }

main

