#!/bin/bash

# Query or update transactions database.
# Expected args: [filter] <command> [mods]

# STATUS: WORK IN PROGRESS - ISSUE 12, 13, AND 14
# TESTS:  FAIL

ROOT=$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")")

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
HELPFILE="$ROOT/src/transaction/help.txt"
TASKRC="$ROOT/cfg/.taskrc"
TASKDATA="$COINDATA/txn"

# forms
NEW_TXN_FORM="$ROOT/src/transaction/form/insert_txn.sh"

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
    then add_interactively
    else task add "$@"
  fi
}

add_interactively() {
  form=$($NEW_TXN_FORM) # data + meta
  success=$(yq '.success' $form)

  # for debugging purposes
  success=true

  if [[ "$success" == "false" ]]; then
    >&2 echo "ERROR: $(yq '.error' $form )"
  else
    query=$(construct_task_query "$(yq '.form.fields' $form)")
  fi
  
  if test_query $query; then echo EXECUTE QUERY NOW; fi
}

construct_task_query() {
  data=$(mktemp '/tmp/coinmaster/data.XXX.yml')
  echo "$@" > $data
  echo "add
    desc:'$(yq .desc $data)'
    amount:'$(yq .amount $data)'
    payee:'$(yq .payee $data)'
    "
}

# FAIL: QUOTING ISSUE: WORKS IN TERMINAL BUT NOT IN SCRIPT
test_query() {
  >&2 echo TESTING: task $query
  (
    TASKRC="$COINRC"
    TASKDATA=/tmp/coinmaster
    task $query
    task all
  )
  exit 1
}

_empty() { [[ -z "$@" ]] ; }

main
