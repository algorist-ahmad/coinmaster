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

# forms
NEW_TXN_FORM="$ROOT/src/transaction/form/insert.sh"

main() {
  dispatch $ARGS
}

dispatch() {
  case "$1" in
    help | --help | -h)   shift ; show_help ;;
    bill* | --bill | -b)  shift ; list_bills +bill "$@" ;; # ISSUE ??
    add | new)            shift ; add_txn "$@"  ;;      # ISSUE 14
    log | -aa)            shift ; log_txn "$@"  ;;      # ISSUE ??

    *) task "$@" ;;
  esac
}

show_help() { echo -e "$(cat $HELPFILE)" | less ; }

add_txn() {
  if _empty "$@"
    then "$NEW_TXN_FORM"
    else task add "$@"
  fi
}

# add_txn_interactively() {
#   result=$(launch_transaction_form) # YAML expected
#   echo $result
# }

_empty() { [[ -z "$@" ]] ; }

main

