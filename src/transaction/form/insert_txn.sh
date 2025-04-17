#!/bin/bash

# This script makes no database transactions, it simply collects and validates user input
# and saves to a JSON file.

# STATUS: DONE
# TESTS:  PASS

ROOT=$( dirname "$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")")")

source $ROOT/src/utils/json.sh
source $ROOT/src/utils/test.sh

ARGS="$@"
TMPDIR='/tmp/coinmaster'
OUTPUT_FILE=''
TASKDATA='/tmp'
TASKRC="$COINRC"
TAGS_LIST="auto:auto bill:bill wishlist:wish next:next grocery:grocery supplies:supply"
PRIORITY_LIST="trivial:T low:L normal:N elevated:E high:H critical:C"
PRIORITY_DEFAULT='normal'
RECURRING_FLAG=""
RECURRING_TAG="bill"
GUM_INPUT_PROMPT_FOREGROUND="38"
JQ_QUERY_META='.success = $succ | .error = $err | .form.name = $name | .form.status = $stat'
JQ_QUERY_INSERT='
  .form.fields.description = $desc     |
  .form.fields.amount = $amount        |
  .form.fields.payee = $payee          |
  .form.fields.due = $due              |
  .form.fields.priority = $priori      |
  .form.fields.recur = $recur          |
  .form.fields.source = $source        |
  .form.fields.until = $until          |
  .form.fields.tags = $tags            |
  .form.fields.annotations[0].description = $note |
  .form.status = "COMPLETE"
  '

trap handle_interrupt SIGINT

main() {
  initialize # CRITICAL
  initialize_form_metadata $OUTPUT_FILE
  collect_user_input $OUTPUT_FILE
  echo $OUTPUT_FILE
}

# OK
initialize() {
  # this variable will be needed in subshells
  export TMPDIR
  # create temporary directories
  >&2 mkdir -pv "$TMPDIR/new-transactions"
  # create temporary output file
  OUTPUT_FILE=$(mktemp $TMPDIR/new-transactions/form.XXX.json)
  echo '{}' > $OUTPUT_FILE # CRITICAL STEP
}

# OK
initialize_form_metadata() {
  _jq $1 "$JQ_QUERY_META"\
    --arg succ "false" \
    --arg err  "" \
    --arg name "New transaction" \
    --arg stat "INCOMPLETE"
}

# OK
# collect user input and saves to JSON file according to Taskwarrior's JSON model
collect_user_input() {
  desc=$(_get_desc)
  payee=$(_get_payee)
  amount=$(_get_amount)
  due=$(_get_due)
  if is_recurring; then
    recur=$(_get_recur)
    source=$(_get_source)
    until=$(_get_until)
  fi
  if additionnal_info_requested; then
    priori=$(_get_priority)
    if tags_requested; then tags=$(_get_tags | jq -R 'split(",")'); fi
    note=$(_get_note)
  fi

  # post-form correction
  if _empty "$tags"; then tags='[]'; fi

  _jq "$1" "$JQ_QUERY_INSERT" \
  --arg desc     "$desc"   \
  --arg amount   "$amount" \
  --arg payee    "$payee"  \
  --arg due      "$due"    \
  --arg priori   "$priori" \
  --arg recur    "$recur"  \
  --arg source   "$source" \
  --arg until    "$until"  \
  --argjson tags "$tags"   \
  --arg note     "$note"   \
  --arg status   "COMPLETE"
}

is_recurring()   {
  if [[ -z "$RECURRING_FLAG" ]]; then 
    if gum confirm "Is this a recurring transaction?"
      then RECURRING_FLAG=1
      else RECURRING_FLAG=0
    fi
  fi
  if [[ "$RECURRING_FLAG" == "1" ]]
    then return 0 # affirmative
    else return 1 # negative
  fi
}

additionnal_info_requested() { gum confirm "Add additional info?" ; }
tags_requested()    { gum confirm "Add tags?" ; }
is_chrono_computable() { task calc "now + $@" &>/dev/null ; }
expression_is_valid()  { task calc "$@" &>/dev/null ; }

# if relative time is provided, then time arithmetic can be done, otherwise, accept input as is
chrono_calc() {
  if is_chrono_computable "$@"
    then echo "$(task calc "now + $@")"
    else echo "$(task calc "$@")"
  fi
}

evaluate() {
  if expression_is_valid "$@"
    then echo "$(task calc "$@")"
    else echo "$*"
  fi
}

# FIXME: BAD PRACTICE: REPEATING CODE - ISSUE #27

# type: string
_get_desc() {
  export GUM_INPUT_HEADER=""
  export GUM_INPUT_PROMPT="Description (required): "

  input=$(gum input --no-show-help --prompt.bold)

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: number
_get_amount() {
  export GUM_INPUT_HEADER="What's the amount which must be paid?"
  export GUM_INPUT_PROMPT="$"
  export GUM_INPUT_PLACEHOLDER="You may perform arithmetic here ... 1+2*3^4/5"

  input=$( evaluate "$(gum input --no-show-help --prompt.bold)")

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: string
_get_payee() {
  export GUM_INPUT_HEADER="To whom must you pay this amount?"
  export GUM_INPUT_PROMPT="To "
  export GUM_INPUT_PLACEHOLDER=""

  input=$(gum input --no-show-help --prompt.bold)

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: date
_get_due() {
  export GUM_INPUT_HEADER="By when must this amount be paid?"
  export GUM_INPUT_PROMPT="Deadline: "
  export GUM_INPUT_PLACEHOLDER="ex: tomorrow, 3 days, 1 week, 21st, etc."

  input="$(gum input --no-show-help --placeholder.italic --prompt.bold)"
  input="$(chrono_calc "$input")" # datetimes

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: duration
_get_recur() {
  export GUM_INPUT_HEADER="How often must this bill be paid?"
  export GUM_INPUT_PROMPT="Recurs every "
  export GUM_INPUT_PLACEHOLDER="ex: 1 month, 2 weeks, 7 days... see \`task help\`"

  input="$( evaluate "$(gum input --no-show-help --placeholder.italic --prompt.bold)")"

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: string
_get_source() {
  export GUM_INPUT_HEADER="From which account is the money withdrawed from? (Leave blank if unknown)"
  export GUM_INPUT_PROMPT="From "
  export GUM_INPUT_PLACEHOLDER="dj, rbc, td..."

  input=$(gum input --no-show-help --placeholder.italic --prompt.bold)

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: datetime
_get_until() {
  export GUM_INPUT_HEADER="Is there an end date to this agreement? (Leave blank if none)"
  export GUM_INPUT_PROMPT="Ends on "
  export GUM_INPUT_PLACEHOLDER="date"

  input="$(gum input --no-show-help --placeholder.italic --prompt.bold)"
  input="$(chrono_calc "$input" 2>/dev/null )"

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

# type: enum
_get_priority() {
  export GUM_CHOOSE_HEADER="How important is this transaction?"
  export GUM_INPUT_PROMPT="Priority: "
  export GUM_CHOOSE_SELECTED="$PRIORITY_DEFAULT"
  export GUM_CHOOSE_LABEL_DELIMITER=":"

  input=$(gum choose --limit=1 $PRIORITY_LIST)

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_tags() {

  export GUM_INPUT_HEADER=""
  export GUM_CHOOSE_PROMPT="Tags: "
  export GUM_CHOOSE_LABEL_DELIMITER=":"
  export GUM_CHOOSE_OUTPUT_DELIMITER=","
   local input=""

  if is_recurring; then
    GUM_CHOOSE_SELECTED="bill"
    input+="$RECURRING_TAG,"
  fi

  input+="$(gum choose --no-limit --selected=$GUM_CHOOSE_SELECTED $TAGS_LIST)"

  >&2 echo -e "\e[32m?\e[0m" "$GUM_CHOOSE_PROMPT""$input"
  echo "$input"
}

_get_note() {
  export GUM_INPUT_HEADER=""
  export GUM_INPUT_PROMPT="Annotation: "
  export GUM_INPUT_PLACEHOLDER="Any comment? Leave empty if none."

  input=$(gum input --no-show-help --prompt.bold --placeholder.italic)

  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

handle_interrupt() {
  >&2 echo -e "\n\033[1;31mInput canceled\033[0m"
  _jq "$OUTPUT_FILE" "$JQ_QUERY_META"\
    --arg succ "false" \
    --arg err  "INTERRUPTED BY USER" \
    --arg name "New transaction" \
    --arg stat "INCOMPLETE"
  >&2 jq . "$OUTPUT_FILE"
  exit 69
}

main
