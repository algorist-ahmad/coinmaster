#/bin/bash

CONFIG_FILE_INTERNAL="$ROOT/cfg/internal.yml"
CONFIG_FILE_USER="$ROOT/cfg/user.yml"

# get a value from internal config
_get() { yq ".$1" "$CONFIG_FILE_INTERNAL"; }

_get_file() {
  # prefix='path'
  root="$( _get root )"
  file="$( _get $@ )"
  echo "$root/$file"
}

_get_path() { _get_file "$@"; }

_set() {
  # set -x
  key="$1"
  val="$2"\
  yq -i ".$key = strenv(val)" "$CONFIG_FILE_INTERNAL"
}

[[ -n "$ROOT" ]] && _set 'root' "$ROOT"
