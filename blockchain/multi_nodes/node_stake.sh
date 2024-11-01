#!/bin/bash
# Run this cript once the node is fully synced
evmosd status

# Config Chain
CHAIN="evmos" # Default is evmos
CHAINID="$CHAIN"_9000-1 # # Default is evmos_9000-1
DENOM="aevmos" # Default is aevmos = wei. Don't need to change

# Validator wallet mnemonic
#   evmosd debug addr $OPERATOR_ADDRESS
# evmos1rnuqkc857kpzr2hlmwew2y7qau0cp9y5e3gng4
# evmosvaloper1rnuqkc857kpzr2hlmwew2y7qau0cp9y55l8rfg
# 0x1cF80B60F4F58221AaFFDBb2e513C0Ef1F809494
# 0x1c384b3fb9a1cff8caee1e2d078bb9bc28a542dcc7ac779a445dc68b3dc2fe1f
MNEMONIC="stumble tilt business detect father ticket major inner awake jeans name vibrant tribe pause crunch sad wine muscle hidden pumpkin inject segment rocket silver"
# Stake amount: 10 tokens
STAKE_AMOUNT="10000000000000000000$DENOM"

# Config paths
NODE_KEY="extnode0"
NODE_IP="192.167.10.20"
NODE_DIR="/root/.evmosd"

# Build script
# Clean up old data
rm -rf "$NODE_DIR/keyring-test" "$NODE_DIR/key_seed.json"
# Import wallet to keyring
echo "Import wallet to keyring"
echo $MNEMONIC | evmosd keys add $NODE_KEY --home $NODE_DIR --chain-id $CHAINID --keyring-backend test --chain-id $CHAINID --recover --output json > $NODE_DIR/key_seed.json

# Create validator config: main config is at staking block in genesis.json file. Default "unstake_time"/"unbonding_time": "1814400s" (21 days)
VALIDATOR_CONFIG=$NODE_DIR/validator.json
cat << EOF > "$VALIDATOR_CONFIG"
{
    "pubkey": $(evmosd tendermint show-validator),
    "amount": "$STAKE_AMOUNT",
    "moniker": "$NODE_KEY",
    "identity": "$NODE_KEY",
    "website": "",
    "security": "",
    "details": "",
    "commission-rate": "0.1",
    "commission-max-rate": "0.2",
    "commission-max-change-rate": "0.01",
    "min-self-delegation": "1"
}
EOF

# Create validator staking transaction
echo "Create validator staking transaction"
TX_OUTPUT=$(evmosd tx staking create-validator $VALIDATOR_CONFIG --from $NODE_KEY --chain-id $CHAINID --ip $NODE_IP --keyring-backend test --gas 300000 --gas-prices 7000aevmos --yes --output json)
TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash')
echo "Transaction hash: $TX_HASH"
evmosd query wait-tx "$TX_HASH" --chain-id $CHAINID > /dev/null 2>&1
TX_STATUS=$(echo "$TX_OUTPUT" | jq -r 'if .raw_log == "" then "OK" else .raw_log end')
echo "Transaction status: $TX_STATUS"

# Check if TX_STATUS is "OK"
if [ "$TX_STATUS" == "OK" ]; then
  sleep 3
  OPERATOR_ADDRESS=$(evmosd keys show $NODE_KEY --keyring-backend test --bech val -a)
  ALL_VALIDATORS=$(evmosd query staking validators --output json)
  echo "Total validators: $(echo "$ALL_VALIDATORS" | jq '.validators | length')"
  VALIDATOR_INFO=$(echo "$ALL_VALIDATORS" | jq -r --arg addr "$OPERATOR_ADDRESS" '.validators[] | select(.operator_address == $addr)')
  # Check if the result is empty
  if [ -z "$VALIDATOR_INFO" ]; then
    echo "Stake failed."
  else
    echo "Stake success. Validator info: $VALIDATOR_INFO"
  fi
else
  echo "Error detected. Exit"
  exit 1
fi

# Check balance
evmosd query bank balances "$(evmosd keys show $NODE_KEY --keyring-backend test -a)"

# Execute
# docker exec -it extnode0 bash "/root/.evmosd/node_stake.sh"
