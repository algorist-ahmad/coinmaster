#!/bin/bash

# Query or update balance

# TESTS: FAIL

ROOT=$( dirname "$( dirname "$(dirname "$(readlink -f "$0")")" )" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
SUCCESS=0
ACCOUNTS_DATA="$COINDATA/accounts"
BALANCE_FILE="$ACCOUNTS_DATA/balance.json"

# SYNTAX:
# for query: balance.sh [-q|]
# for update accounts: balance.sh -edit
# for update amounts: balance.sh -u <account_name> <amount>
main() {
  # load_config
  case "$1" in
    help | --help)     display_help ;;
    query | -q | '')   query_balances ;;
    edit | -e )        edit_accounts_file ;;
    update | set | -u) update_balance "$@" ;;
    move | mv )        move_amount "$@" ;;
  esac
}

display_help() {
  echo "
  coin account

  help
  query
  edit
  set [account name] [balance]
  mv [amount] [from account] [to account]"
}

# shitty code by Deepseek, FIXME
query_balances() {
  set -euo pipefail

  validate_file "$BALANCE_FILE"

  # Color and formatting definitions
  COLOR_RED="\033[31m"
  COLOR_GREEN="\033[32m"
  COLOR_YELLOW="\033[33m"
  COLOR_RESET="\033[0m"
  BOLD="\033[1m"

  # Color code balance values
  colorize_balance() {
    local balance="$1"
    if (( $(echo "$balance < 0" | bc -l) )); then
      printf "%b%'12.2f%b" "$COLOR_RED" "$balance" "$COLOR_RESET"
    elif (( $(echo "$balance == 0" | bc -l) )); then
      printf "%b%'12.2f%b" "$COLOR_RESET" "$balance" "$COLOR_RESET"
    else
      printf "%b%'12.2f%b" "$COLOR_GREEN" "$balance" "$COLOR_RESET"
    fi
  }

  # Calculate colored relative time
  get_colored_relative_time() {
    local timestamp="$1"
    local current_time=$(date +%s)
    local updated_time=$(date -d "$timestamp" +%s 2>/dev/null || echo 0)
    local diff=$((current_time - updated_time))
    local seconds_per_day=86400

    if (( diff < seconds_per_day )); then
      color="$COLOR_GREEN"
      if (( diff < 60 )); then
        time_str=$(printf "%2ds ago" "$diff")
      elif (( diff < 3600 )); then
        time_str=$(printf "%2dm ago" "$((diff / 60))")
      else
        time_str=$(printf "%2dh ago" "$((diff / 3600))")
      fi
    elif (( diff < 3 * seconds_per_day )); then
      color="$COLOR_YELLOW"
      time_str=$(printf "%2dd ago" "$((diff / seconds_per_day))")
    else
      color="$COLOR_RED"
      time_str=$(printf "%2dd ago" "$((diff / seconds_per_day))")
    fi

    printf "%b%-8s%b" "$color" "$time_str" "$COLOR_RESET"
  }

  # Generate the formatted table
  generate_formatted_table() {
    # Header (swapped columns)
    printf "%b%-12s %12s %-8s %-19s%b\n" \
      "$BOLD" "Account" "Balance" "Relative" "Updated" "$COLOR_RESET"

    # Data rows with swapped columns
    yq -r '.[] | [.name, .balance, .updated] | join(" ")' "$BALANCE_FILE" | \
      while read -r name balance updated; do
        printf "%-12s %b %b %-19s\n" \
          "$name" \
          "$(colorize_balance "$balance")" \
          "$(get_colored_relative_time "$updated")" \
          "$(date -d "$updated" "+%Y-%m-%d %H:%M:%S")"
      done
  }

  # Calculate and display total
  display_total() {
    local total_balance=$(yq -r '.[].balance' "$BALANCE_FILE" | paste -sd+ - | bc)
    printf "\n%b%-12s %b%'12.2f%b\n" \
      "$BOLD" "TOTAL" \
      "$COLOR_RESET" "$total_balance" \
      "$COLOR_RESET"
  }

  # Display the table
  generate_formatted_table | column -t -s $'\t'
  display_total
}

edit_accounts_file() {
  $EDITOR "$BALANCE_FILE"
}

update_balance() {

  # set -x

  # Ensure correct arguments
  if [ $# -lt 3 ]; then
    echo "Error: Usage: balance.sh set <account> <amount>"
    exit 1
  fi

  local account="$2"
  local amount="$3"
  local tmp_file=$(mktemp)

  # Validate numerical amount
  if ! [[ "$amount" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Amount must be a numeric value"
    exit 1
  fi

  # Verify account exists
  if ! yq -e ".[] | select(.name == \"$account\")" "$BALANCE_FILE" > /dev/null; then
    echo "Error: Account '$account' not found"
    exit 1
  fi

  # Update balance and timestamp
  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  yq eval ".[] |= select(.name == \"$account\") |= ( .balance = $amount | .updated = \"$current_time\" )" "$BALANCE_FILE" > "$tmp_file" && mv "$tmp_file" "$BALANCE_FILE"

  echo "Success: Updated $account balance to $amount at $current_time"
}

# syntax: coin bal mv 200 [from] rbc [to] dj
move_amount() {
  if [ $# -lt 4 ]; then
    echo "Error: Usage: balance.sh mv <amount> <source> <destination>"
    exit 1
  fi

  local amount="$2"
  local source="$3"
  local dest="$4"

  # Validate numerical amount
  if ! [[ "$amount" =~ ^[0-9]+$ ]]; then
    echo "Error: Amount must be a positive integer"
    exit 1
  fi

  # Prevent self-transfer
  if [[ "$source" == "$dest" ]]; then
    echo "Error: Cannot transfer between identical accounts"
    exit 1
  fi

  # Verify accounts exist
  for account in "$source" "$dest"; do
    if ! yq -e ".[] | select(.name == \"$account\")" "$BALANCE_FILE" > /dev/null; then
      echo "Error: Account '$account' not found"
      exit 1
    fi
  done

  # Atomic update with single yq command
  current_time=$(date -u +"%Y-%m-%dT%H%M%SZ")
  yq eval -i '
    ([.] | .[] | select(.name == "'"$source"'") | .balance) as $src |
    ([.] | .[] | select(.name == "'"$dest"'") | .balance) as $dst |
    if $src < '"$amount"' then
      error("Insufficient funds")
    else
      .[] |= (
        if .name == "'"$source"'" then
          (.balance |= . - '"$amount"' | .updated = "'"$current_time"'")
        elif .name == "'"$dest"'" then
          (.balance |= . + '"$amount"' | .updated = "'"$current_time"'")
        else
          .
        end
      )
    end
  ' "$BALANCE_FILE"

  echo "Success: Moved $amount from $source to $dest at $current_time"
}

validate_file() {
  :
}

main $@
