#!/bin/bash
# Run this cript once the node is fully synced

# Config Chain
CHAIN="evmos" # Default is evmos
CHAINID="$CHAIN"_9000-1 # # Default is evmos_9000-1
DENOM="aevmos" # Default is aevmos = wei. Don't need to change

# Validator wallet mnemonic
# 0x1cF80B60F4F58221AaFFDBb2e513C0Ef1F809494
# 0x1c384b3fb9a1cff8caee1e2d078bb9bc28a542dcc7ac779a445dc68b3dc2fe1f
MNEMONIC="stumble tilt business detect father ticket major inner awake jeans name vibrant tribe pause crunch sad wine muscle hidden pumpkin inject segment rocket silver"
# Stake amount: 10 tokens
STAKE_AMOUNT="10000000000000000000$DENOM"

# Config paths
NODE_KEY="extnode0"
NODE_IP="192.167.10.20"
NODE_DIR="/root/.evmosd"
echo "Create external node data: $NODE_KEY"

# Build script
# Clean up old data
rm -rf "$NODE_DIR/keyring-test" "$NODE_DIR/key_seed.json"
# Import wallet to keyring
echo "Import wallet to keyring"
echo $MNEMONIC | evmosd keys add $NODE_KEY --home $NODE_DIR --chain-id $CHAINID --keyring-backend test --recover --output json > $NODE_DIR/key_seed.json

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
evmosd tx staking create-validator $VALIDATOR_CONFIG --from $NODE_KEY --chain-id $CHAINID --ip $NODE_IP --keyring-backend test --gas 300000 --gas-prices 7aevmos --yes

# Verify Validator Status
echo "Validator status:"
OPERATOR_ADDRESS=$(evmosd keys show $NODE_KEY --keyring-backend test --bech val -a)
evmosd query staking validator "$OPERATOR_ADDRESS"

# To get hex address of the validator
echo "Hex address of the validator:"
evmosd debug addr $OPERATOR_ADDRESS
#NODE_ADDRESS=$(evmosd keys show $NODE_KEY -a --keyring-backend test)
#evmosd debug addr $NODE_ADDRESS

# To get the list of validators
echo "List of validators:"
evmosd query staking validators

# To get your Node ID use
evmosd tendermint show-node-id

# Execute
# docker exec -it extnode0 bash "/root/.evmosd/node_stake.sh"
