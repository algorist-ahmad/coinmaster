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
TAGS_LIST="auto:+auto bill:+bill wishlist:+wish next:+next grocery:+grocery supplies:+supplies"
PRIORITY_LIST="trivial:T low:L normal:N elevated:E high:H critical:C"
PRIORITY_DEFAULT='normal'
RECURRING_FLAG=""
RECURRING_TAG="+bill"
GUM_INPUT_PROMPT_FOREGROUND="38"
ctrlc_count=0

trap no_ctrlc SIGINT

main() {
  # get user input
  
  collect_user_input
  # data=$(collect_user_input) # YAML
  # from user input create a valid Taskwarrior syntax string
  # query=$(collect_user_input)
  # echo "$query"
  # query=$(convert_to_query "$data")
  # query=(printf "%s" "${data[@]}")
  # echo "$query"
  # create fake database TASKDATA using same TASKRC
  # execute
  # task add $query
  # successful?
    # if not, exit with error
    # if yes, exit 0 with YAML
}

# collect user input and return as YAML
collect_user_input() {
  # Phase 1: Data Collection
  local -A data=()

  # Core fields
  data[description]=$(_get_desc) || continue
  data[payee]=$(_get_payee) || continue
  data[amount]=$(_get_amount) || continue
  data[due]=$(_get_due) || continue
  data[priority]=$(_get_priority) || continue

  # Recurring transaction fields
  if is_recurring; then
    RECURRING=1
    data[recurring_frequency]=$(_get_recur) || continue
    data[recurring_source]=$(_get_source) || continue
    data[recurring_until]=$(_get_until) || continue
  fi

  # Tags collection
  if tags_requested; then
    data[tags]=$(_get_tags) || continue
  fi

  # Build YAML (your existing code here)
  # build_yaml data

  # Phase 2: YAML Construction
  local yaml=""
  
  # Core fields (always present)
  yaml+="description: \"${data[description]}\"\n"
  yaml+="payee: \"${data[payee]}\"\n"
  yaml+="amount: ${data[amount]}\n"
  yaml+="due: \"${data[due]}\"\n"
  yaml+="priority: \"${data[priority]}\"\n"

  # Conditional recurring block
  if [[ -v data[recurring_frequency] ]]; then
    yaml+="recurring:\n"
    yaml+="  frequency: \"${data[recurring_frequency]}\"\n"
    yaml+="  source: \"${data[recurring_source]}\"\n"
    yaml+="  until: \"${data[recurring_until]}\"\n"
  fi

  # Optional tags
  if [[ -v data[tags] ]]; then
    yaml+="tags: [${data[tags]}]\n"
  fi

  # Phase 3: Validation & Output
  printf "%s" "$yaml" | yq eval -P -
}

construct_query() {
  while [[ $# -gt 0 ]]; do
    >&2 echo $1 $2
    shift
  done
}

is_recurring()   {
  if [[ -z "$RECURRING_FLAG" ]]
    then 
      if gum confirm "Is this a recurring transaction?"
        then
          RECURRING_FLAG=1
        else
          RECURRING_FLAG=0
      fi
    else
      if [[ "$RECURRING_FLAG" == "1" ]]
        then
          exit 0 # affirmative
        else
          exit 1 # negative
      fi
  fi  
}

tags_requested() { gum confirm "Add tags?" ; }

_get_desc() {
  export GUM_INPUT_HEADER=""
  export GUM_INPUT_PROMPT="Description (required): "

  input=$(gum input --no-show-help --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_amount() {
  export GUM_INPUT_HEADER="What's the amount which must be paid?"
  export GUM_INPUT_PROMPT="$ "
  export GUM_INPUT_PLACEHOLDER="0.00$"

  input=$(gum input --no-show-help --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_payee() {
  export GUM_INPUT_HEADER="To whom must you pay this amount?"
  export GUM_INPUT_PROMPT="To "
  export GUM_INPUT_PLACEHOLDER=""

  input=$(gum input --no-show-help --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_due() {
  export GUM_INPUT_HEADER="By when must this amount be paid?"
  export GUM_INPUT_PROMPT="Deadline: "
  export GUM_INPUT_PLACEHOLDER="ex: tomorrow, 3 days, 1 week, 21st, etc."

  input=$(gum input --no-show-help --placeholder.italic --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_recur() {
  export GUM_INPUT_HEADER="How often must this bill be paid?"
  export GUM_INPUT_PROMPT="Recurrence: "
  export GUM_INPUT_PLACEHOLDER="ex: 1 month, 2 weeks, 7 days... see \`task help\`"

  input=$(gum input --no-show-help --placeholder.italic --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}


_get_source() {
  export GUM_INPUT_HEADER="From which account is the money withdrawed from? (Leave blank if unknown)"
  export GUM_INPUT_PROMPT="From "
  export GUM_INPUT_PLACEHOLDER="dj, rbc, td..."

  input=$(gum input --no-show-help --placeholder.italic --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_until() {
  export GUM_INPUT_HEADER="Is there an end date to this agreement? (Leave blank if none)"
  export GUM_INPUT_PROMPT="From "
  export GUM_INPUT_PLACEHOLDER="date"

  input=$(gum input --no-show-help --placeholder.italic --prompt.bold)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_priority() {
  export GUM_CHOOSE_HEADER="How important is this transaction?"
  export GUM_INPUT_PROMPT="Priority "
  export GUM_CHOOSE_SELECTED="$PRIORITY_DEFAULT"
  export GUM_CHOOSE_LABEL_DELIMITER=":"

  input=$(gum choose --limit=1 $PRIORITY_LIST)
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_tags() {

  export GUM_INPUT_HEADER=""
  export GUM_CH_PROMPT="Tags: "
  export GUM_CHOOSE_LABEL_DELIMITER=":"
   local input=""

  if is_recurring; then
    GUM_CHOOSE_SELECTED="bill"
    input+="$RECURRING_TAG "
  fi

  input+="$(gum choose --no-limit --selected=$GUM_CHOOSE_SELECTED "$TAGS_LIST")"

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
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

convert_to_query() {
  printf "%s" "${data[@]}"
}

function no_ctrlc()
{
    let ctrlc_count++
    echo
    if [[ $ctrlc_count == 1 ]]; then
        echo "Stop that."
    elif [[ $ctrlc_count == 2 ]]; then
        echo "Once more and I quit."
    else
        echo "That's it.  I quit."
        exit
    fi
}

handle_interrupt() {
  echo -e "\n\033[1;31mInput canceled\033[0m" >&2
  exit 1
}

main
