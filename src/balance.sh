#!/bin/bash

# Query or update balance

# TESTS: FAIL

# FIXME:

# TODO:
# [ ] 

ROOT=$( dirname "$(dirname "$(readlink -f "$0")")" )

source "$ROOT/src/load-config.sh"

ARGS="$@"
CONFIGFILE="$ROOT/config.yml"
SUCCESS=0
BALANCES_FILE="$COINDATA/data/balances.yml"

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

query_balances() {
  validate_file "$BALANCES_FILE"

  # Get all balances as a list, sum them with bc
  local total_balance
  total_balance=$(yq -r '.[].balance' "$BALANCES_FILE" | paste -sd+ | bc)

  # Generate table with total
  (
    echo "Account Balance Updated"
    yq -r '.[] | [.name, .balance, .updated] | join(" ")' "$BALANCES_FILE"
    printf "\e[31mTotal\e[0m %s \n" "$total_balance"
  ) | column -t
}

edit_accounts_file() {
  $EDITOR "$BALANCES_FILE"
}

update_balance() {
  # Ensure correct arguments
  if [ $# -lt 3 ]; then
    echo "Error: Usage: balance.sh set <account> <amount>"
    exit 1
  fi

  local account="$2"
  local amount="$3"
  local tmp=$(mktemp)

  # Validate numerical amount
  if ! [[ "$amount" =~ ^[0-9]+$ ]]; then
    echo "Error: Amount must be a positive integer"
    exit 1
  fi

  # Verify account exists
  if ! yq -e ".[] | select(.name == \"$account\")" "$BALANCES_FILE" > /dev/null; then
    echo "Error: Account '$account' not found"
    exit 1
  fi

  # Update balance and timestamp
  current_time=$(date -u +"%Y-%m-%dT%H%M%SZ")
  yq ".[] |= if (.name == \"$account\") then (.balance = $amount | .updated = \"$current_time\") else . end" "$BALANCES_FILE" > "$tmp" && mv "$tmp" "$BALANCES_FILE"

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
    if ! yq -e ".[] | select(.name == \"$account\")" "$BALANCES_FILE" > /dev/null; then
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
  ' "$BALANCES_FILE"

  echo "Success: Moved $amount from $source to $dest at $current_time"
}

display_help() {
  echo "
  coin balance ...

  help
  query
  set [account name] [balance]
  edit
  mv [amount] [from account] [to account]"
}

main $@
