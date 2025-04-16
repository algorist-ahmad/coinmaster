#!/bin/bash

# This script makes no database transactions, it simply collects and validates user input
# and saves to a YAML file.

# STATUS: REVIEWING - ISSUE 12
# TESTS:  FAIL

ROOT=$( dirname "$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")")")")
ARGS="$@"
TMPDIR='/tmp/coinmaster'
OUTPUT_FILE=''
TASKDATA='/tmp'
TASKRC="$COINRC"
TAGS_LIST="auto:+auto bill:+bill wishlist:+wish next:+next grocery:+grocery supplies:+supplies"
PRIORITY_LIST="trivial:T low:L normal:N elevated:E high:H critical:C"
PRIORITY_DEFAULT='normal'
RECURRING_FLAG=""
RECURRING_TAG="+bill"
GUM_INPUT_PROMPT_FOREGROUND="38"
ctrlc_count=0

trap handle_interrupt SIGINT

main() {
  initialize_form_metadata
  form=$(collect_user_input)
  # if data has been collected without error, set success as true and output filename
  # if something happened, like SIGINT for example, set success as false and set error to a useful error message, then output file name
  echo $form
}

initialize_form_metadata() {
  OUTPUT_FILE=$(mktemp $TMPDIR/form.XXX.yml)
  yq -i '
    .success = false |
    .error = ""      |
    .form.name = "New transaction" |
    .form.desc = "" |
    .form.status = "INCOMPLETE"'\
  $OUTPUT_FILE
}

# collect user input and return YAML form filename
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
    priority=$(_get_priority)
    if tags_requested; then tags=$(_get_tags); fi
    note=$(_get_note)
  fi

  yq -i "
    .form.fields.desc = \"$desc\"         |
    .form.fields.amount = \"$amount\"     |
    .form.fields.payee = \"$payee\"       |
    .form.fields.due = \"$due\"           |
    .form.fields.priority = \"$priority\" |
    .form.fields.recur = \"$recur\"       |
    .form.fields.source = \"$source\"     |
    .form.fields.until = \"$until\"       |
    .form.fields.tags = \"$tags\"         |
    .form.fields.note = \"$note\"         |
    .form.status = \"COMPLETE\"           "\
  $OUTPUT_FILE # DO NOT FORGET TO ADD TAG +bill for RECURRING=1

  echo $OUTPUT_FILE
}

construct_query() {
  while [[ $# -gt 0 ]]; do
    >&2 echo $1 $2
    shift
  done
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

  input=$(task calc "$(gum input --no-show-help --placeholder.italic --prompt.bold)")
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

_get_recur() {
  export GUM_INPUT_HEADER="How often must this bill be paid?"
  export GUM_INPUT_PROMPT="Recurs every "
  export GUM_INPUT_PLACEHOLDER="ex: 1 month, 2 weeks, 7 days... see \`task help\`"

  input=$(task calc "$(gum input --no-show-help --placeholder.italic --prompt.bold)")
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
  export GUM_INPUT_PROMPT="Ends on "
  export GUM_INPUT_PLACEHOLDER="date"

  input=$(task calc "$(gum input --no-show-help --placeholder.italic --prompt.bold)")
  >&2 echo -e "\e[32m?\e[0m" "$GUM_INPUT_PROMPT""$input"
  echo "$input"
}

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
  export GUM_CHOOSE_OUTPUT_DELIMITER=" "
   local input=""

  if is_recurring; then
    GUM_CHOOSE_SELECTED="bill"
    input+="$RECURRING_TAG "
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
  yq -i '.error = "INTERRUPTED BY USER"' $OUTPUT_FILE
  >&2 echo -e "\n\033[1;31mInput canceled\033[0m"
}

main
