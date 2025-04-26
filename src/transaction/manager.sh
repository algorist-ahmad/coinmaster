#!/bin/bash

# Query or update transactions database.
# Expected args: [filter] <command> [mods]

# STATUS: DONE
# TESTS:  PASS

ROOT=$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")")

source $ROOT/src/utils/json.sh
source $ROOT/src/utils/test.sh

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
    add | new)            shift ; add_txn $@  ;;        # ISSUE 14
    log | -aa)            shift ; log_txn "$@"  ;;      # ISSUE ??
    export)               shift ; export_pending_txn ;; # ISSUE 34

    *) task "$@" ;;
  esac
}

show_help() { echo -e "$(cat $HELPFILE)" | less ; }

add_txn() {
  if _empty "$@"
    then add_interactively
    else add_unsecurely "$@"
  fi
}

add_unsecurely() {
  task add "$@"
  >&2 echo "Discouraged command, use the interactive form"
}

add_interactively() {
  form=$($NEW_TXN_FORM) # data + meta
  success=$(jq '.success' $form)
  data="$(extract_data $form)"
  
  # ! ASSUMPTION: for experimental purposes
  success=true

  if   is_false "$success"; then report_error "$form"; fi
  if ! test_import "$data"; then report_error "$form"; fi

  insert_transaction "$data"
}

# give useful feedback upon successful save
insert_transaction() {
  data="$@"
  feedback=$(mktemp /tmp/coinmaster/new-transactions/feedback.XXX)
  echo "$data" | task import > $feedback ; c=$?
  if ok $c
    then
      echo "OPERATIONS:"
      tail -n +2 $feedback
      task newest limit:1
    else >&2 echo "ERROR some shit went wrong"
  fi
  return $c
}

# give useful feedback on why insertion failed and exit
report_error() {
  >&2 echo "INSERTION TEST FAILED!"
  jq . "$1"
  return 30
}

test_import() {
  export file=$(mktemp /tmp/coinmaster/XXXXXX)
  echo "$@" > $file
  # subshell
  (
    TASKRC="$COINRC"
    TASKDATA=/tmp/coinmaster
    task import "$file" &>/dev/null
  )
  return $?
}

# Function to find closest column match
match_task_column() {
    local search_term="$1"
    local columns matches
    columns=$(task _columns 2>/dev/null)
    
    # Find all matching columns (case insensitive)
    matches=$(grep -i "^$search_term" <<< "$columns" || true)
    match_count=$(wc -l <<< "$matches" | tr -d ' ')
    
    if [[ $match_count -eq 1 ]]; then
        # Single match found
        echo "$matches"
    elif [[ $match_count -gt 1 ]]; then
        # Multiple matches found
        echo "Error: '$search_term' matches multiple columns:" >&2
        echo "$matches" | sed 's/^/  /' >&2
        return 1
    else
        # No matches found
        echo "$search_term"
    fi
}

# pull form data from report and formats the JSON according to TaskWarrior's requirement
extract_data() {
  # receive
  file="$1"
  # pull data
  data="$( jq '.form.fields' $file )"
  # remove empty values
  data="$( jq_purge "$data" )"
  # surround by square bracket, they are needed to get useful diagnosis from Taskwarrior
  data="[$data]"
  # send
  echo "$data"
}

# exports pending transactions due within 2weeks
export_pending_txn() {
  set -x
  task status:pending due.before:2weeks export > /tmp/coin.export.json
  tag_txn /tmp/coin.export.json 'COIN'
}

# add special tag COIN when exporting
tag_txn() {
  set -u
  jsonfile="$1"
  newtag="$2"
  jq --arg newtag "$newtag" 'map(.tags |= . + [$newtag])' "$jsonfile"
}

# remove special tag COIN when importing
untag_txn() {
  set -u
  jsonfile="$1"
  tag="$2"
  jq --arg tag "$tag" 'map(.tags |= . - [$tag])' "$jsonfile"
}

main
