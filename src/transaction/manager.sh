#!/bin/bash

# Query or update transactions database.
# Expected args: [filter] <command> [mods]

# STATUS: WORK IN PROGRESS - ISSUE 12, 13, AND 14
# TESTS:  FAIL

ROOT=$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")" )
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
  echo "
  are there arguments or no?
  If no args:
    Is it a recurring bill or a single transaction?

  If single: skip recur attributes
    Has it been paid already?

  If recurring:
    prompt for each attribute one by one, validate along the way
  "
}

main

