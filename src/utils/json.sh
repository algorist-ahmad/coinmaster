#!/bin/bash

# helper function to execute queries in place (same file)
# SYNTAX: _jq <OUTPUT FILE> <QUERY> [ARGUMENTS]
_jq() {
  out="$1"
  query="$2"
  tmp=$(mktemp $TMPDIR/XXXXXX)
  shift 2 # remove file and query arg
  jq "$query" "$out" "$@" > "$tmp" && mv "$tmp" "$out"
}

# remove keys where values are either empty strings "", empty arrays [], or empty objects {}
jq_purge() {
  echo "$*" | jq '
    def deep_purge:
      walk(
        if type == "object" then
          with_entries(
            select(
              .value != "" and
              .value != null and
              .value != [] and
              .value != {}
            )
          )
        elif type == "array" then
          map(
            select(
              . != "" and
              . != null and
              . != [] and
              . != {}
            )
          ) | select(length > 0)
        else . end
      );
    deep_purge | until(. == (deep_purge | .); deep_purge)
  '
}
