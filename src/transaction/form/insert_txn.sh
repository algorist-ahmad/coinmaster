#!/bin/bash

# Collect and validate user input to create a new transaction. This script does no database transactions,
# it simply collects, process, and redirects data. Output must be YAML.
# IDEA: insert task into temporary database, then export to JSON for inspection. If all looks good, import into realdb

# STATUS: IN PROGRESS - ISSUE 12
# TESTS:  FAIL

  # echo "
  # are there arguments or no?
  # If no args:
  #   Is it a recurring bill or a single transaction?

  # If single: skip recur attributes
  #   Has it been paid already?

  # If recurring:
  #   prompt for each attribute one by one, validate along the way
  # "

ROOT=$( dirname "$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")")")
ARGS="$@"
TASKDATA='/tmp'
TASKRC="$COINRC"

main() {
  # from user input create a valid Taskwarrior syntax string
  fields=$(collect_user_input)
  query=$(printf "%s" "${fields[@]}")
  echo "$query"
  # create fake database TASKDATA using same TASKRC
  # execute
  task add $query
  # successful?
    # if not, exit with error
    # if yes, exit 0 with YAML
}

collect_user_input() {
  # Interactive fields using gum
  desc=$(_get_desc)
  payee=$(_get_payee)
  amount=$(_get_amount)
  due=$(_get_due)
  if is_recurring; then
    recur=$(_get_recur)
    source=$(_get_source)
    until=$(_get_until)
  fi
  # PRIORITY=$(gum choose --header "Priority" "low" "medium" "high")
  priority=$(_get_priority)
  # TAGS=$(gum input --placeholder "comma,separated,tags" --prompt "Tags: ")
  if tags_requested; then
    >&2 echo "? tags: "
    gum choose --no-limit auto bill wishlist loan grocery supplies
  else
    >&2 echo "? tags: none"
  fi

  # Construct output string
  fields=(
    "description:$desc"
    "payee:$payee"
    "amount:$amount"
    "due:$due"
    "recur:$recur"
    "source:$source"
    "until:$until"
    "priority:$priority"
    "tags:$tags"
  )

  echo "${fields[@]}"
}

is_recurring() {
  gum confirm "Is this a recurring transaction?"
}

tags_requested() {
  gum confirm "Add tags?"
}

_get_desc() {
  export GUM_INPUT_HEADER=""
  export GUM_INPUT_PROMPT="Description (required): "

  input=$(gum input --no-show-help)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_amount() {
  export GUM_INPUT_HEADER=""
  export GUM_INPUT_PROMPT="Amount: "

  input=$(gum input --header="What's the amount which must be paid?" --placeholder "0.00$")
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_payee() {
  export GUM_INPUT_HEADER="To whom must you pay this amount?"
  export GUM_INPUT_PROMPT="Payee: "

  input=$(gum input --no-show-help)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_due() {
  export GUM_INPUT_HEADER="By when must this amount be paid?"
  export GUM_INPUT_PROMPT="Deadline: "

  input=$(gum input --no-show-help)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_recur() {
  >&2 echo how often it recurs
  gum input
}

_get_source() {
  >&2 echo from which account
  gum input
}

_get_until() {
  >&2 echo until when
  gum input
}

_get_priority() {
  >&2 echo how important
  gum choose --limit=1 C H E N L T 
}

_remove_space() {
  :
}

_validate_string() {
  :
}

_validate_numeric() {
  :
}

_validate_date() {
  :
}

_validate_duration() {
  :
}

main
