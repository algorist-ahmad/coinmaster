#!/bin/bash

# specific boolean testing
is_true()  { [[ "$@" == "true"  ]]; }
is_false() { [[ "$@" == "false" ]]; }

# test for truthy values
affirmative() { :; } # true, non-empty, 1, yes

# test for falsy values
negative() { :; } # false, empty, null, 0, no

# test if args are empty
_empty() { [[ -z "$@" ]] ; }

# test if arg is 0, to be used in conjuction with $?: if ok $e; then ...
ok() { [ $1 -eq 0 ] ; }
