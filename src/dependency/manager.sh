#!/bin/bash

# desc

# STATUS: 
# TESTS:  FAIL

r=$( dirname "$(dirname "$(readlink -f "$0")")")
# source "$r/src/utils/test.sh"

DEPENDENCIES=(
  'task'
  'gum'
  'jq'
)

ARGS="$@"
CONFIGFILE="$root/config.yml"

check_dependencies_warn() {
  for dep in ${DEPENDENCIES[@]}; do
    ! _cmd $dep && >&2 echo "Warning: command '$dep' is required to be installed run properly"
  done
}

# FIXME
check_dependencies_exit() {
  for dep in ${DEPENDENCIES[@]}; do
    # >&2 echo "CHECK DEP EXIT $dep"
    if ! _cmd "$dep"; then
      >&2 echo "ERROR: command '$dep' NOT FOUND. Must install"
      return 3
    fi
  done

  # if [[ "$exit" == "true" ]]
  #   then exit 2
  #   else return 0
  # fi
}

_cmd() { command -v "$1" >/dev/null ; }
