#!/bin/bash
# Run this cript once the node is fully synced

# Config Chain
DENOM="aevmos" # Default is aevmos = wei. Don't need to change
# Stake amount: 10 tokens
UNSTAKE_AMOUNT="10000000000000000000$DENOM"

# Config paths
NODE_KEY="extnode0"
OPERATOR_ADDRESS=$(evmosd keys show $NODE_KEY --keyring-backend test --bech val -a)
# Main staking config is at staking block in genesis.json file. Default "unstake_time"/"unbonding_time": "1814400s" (21 days)
# The tokens will be available in your wallet after unbonding period.
echo "Un-staking transaction"
evmosd tx staking unbond $OPERATOR_ADDRESS $UNSTAKE_AMOUNT --from $NODE_KEY --keyring-backend test --gas 300000 --gas-prices 7aevmos --yes

# Verify Validator Status
echo "Validator status:"
evmosd query staking validator "$OPERATOR_ADDRESS"

# To get the list of validators
echo "List of validators:"
evmosd query staking validators

# Execute
# docker exec -it extnode0 bash "/root/.evmosd/node_unstake.sh"
