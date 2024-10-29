#!/bin/bash

# Config Chain
CHAIN="evmos" # Default is evmos
CHAINID="$CHAIN"_9000-1 # # Default is evmos_9000-1
MONIKER="$CHAIN"
DENOM="aevmos" # Default is aevmos

# Config paths
BUILD_DIR=$(pwd)/build
INIT_DIR=$BUILD_DIR/evmosd
GENTXS_DIR=$BUILD_DIR/gentxs
CONF_DIR=$INIT_DIR/config
GENESIS=$CONF_DIR/genesis.json
TEMP_GENESIS=$CONF_DIR/tmp_genesis.json
CONFIG_APP=$CONF_DIR/app.toml
CONFIG_CLIENT=$CONF_DIR/client.toml
CONFIG=$CONF_DIR/config.toml

# Create necessary directory for orchestrator node
rm -rf "$BUILD_DIR"
mkdir -p "$INIT_DIR"

echo "Init $CHAIN with moniker=$MONIKER and chain-id=$CHAINID"
evmosd init "$MONIKER" --chain-id "$CHAINID" --home "$INIT_DIR"

echo "Prepare genesis..."
echo "- Set gas limit 100M in genesis"
jq '.consensus_params["block"]["max_gas"]="100000000"' "$GENESIS" > "$TEMP_GENESIS" && mv "$TEMP_GENESIS" "$GENESIS"

echo "- Set $DENOM as denom"
sed -i.bak "s/aevmos/$DENOM/g" $GENESIS
sed -i.bak "s/aphoton/$DENOM/g" $GENESIS
sed -i.bak "s/stake/$DENOM/g" $GENESIS

# Change proposal periods to 1 day
sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "24h0m0s"/g' "$GENESIS"
sed -i.bak 's/"voting_period": "172800s"/"voting_period": "24h0m0s"/g' "$GENESIS"
sed -i.bak 's/"expedited_voting_period": "86400s"/"expedited_voting_period": "1h0m0s"/g' "$GENESIS"
# Change proposal required quorum to 15%, so with the orchestrator vote the proposals pass
sed -i.bak 's/"quorum": "0.334000000000000000"/"quorum": "0.150000000000000000"/g' "$GENESIS"

# Update config
sed -i.bak 's/prometheus = false/prometheus = true/g' $CONFIG
sed -i.bak 's/timeout_commit = "5s"/timeout_commit = "1s"/g' "$CONFIG"
# Change max_subscription to for bots workers
sed -i.bak 's/max_subscriptions_per_client = 5/max_subscriptions_per_client = 500/g' "$CONFIG"
# Make sure localhost is always 0.0.0.0 to make it work on docker network
sed -i.bak 's/pprof_laddr = "localhost:6060"/pprof_laddr = "0.0.0.0:6060"/g' $CONFIG
sed -i.bak 's/127.0.0.1/0.0.0.0/g' $CONFIG
rm -rf "$CONFIG.bak"

sed -i.bak 's/enable-indexer = false/enable-indexer = true/g' $CONFIG_APP
sed -i.bak '/# Enable defines if the API server should be enabled/{n;s/enable = false/enable = true/;}' $CONFIG_APP
sed -i.bak 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' $CONFIG_APP
# Set custom pruning settings
sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$CONFIG_APP"
sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$CONFIG_APP"
sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$CONFIG_APP"
sed -i.bak 's/127.0.0.1/0.0.0.0/g' $CONFIG_APP
sed -i.bak 's/localhost/0.0.0.0/g' $CONFIG_APP
rm -rf "$CONFIG_APP.bak"

sed -i.bak 's/localhost/0.0.0.0/g' $CONFIG_CLIENT
rm -rf "$CONFIG_CLIENT.bak"


# Create a folder to store genesis transaction
mkdir -p $GENTXS_DIR

# Define the array of Node's IP addresses
IPs=("192.167.10.2" "192.167.10.3" "192.167.10.4" "192.167.10.5")
NODE_COUNT=${#IPs[@]}
echo "- Create $NODE_COUNT nodes data"
for i in "${!IPs[@]}"; do
    NODE_KEY="node${i}"
    NODE_IP="${IPs[$i]}"
    NODE_DIR="$BUILD_DIR/$NODE_KEY"
    echo " + Creating $NODE_KEY at: $NODE_DIR"
    mkdir -p $NODE_DIR/config/
    evmosd keys add $NODE_KEY --home $NODE_DIR --chain-id "$CHAINID" --keyring-backend test --output json > $NODE_DIR/key_seed.json

    echo " + Allocate genesis account: $KEY_ADDRESS"
    cp $GENESIS $NODE_DIR/config/
    KEY_ADDRESS=$(evmosd keys show $NODE_KEY -a --home $NODE_DIR --keyring-backend test)
    evmosd add-genesis-account "$KEY_ADDRESS" 100000000000000000000000000000000$DENOM --home $NODE_DIR --keyring-backend test
    
    echo " + Sign genesis transaction for account: $KEY_ADDRESS"
    evmosd gentx $NODE_KEY 100000000000000000000$DENOM --keyring-backend test --home $NODE_DIR --chain-id $CHAINID --ip $NODE_IP

    # Commit latest account state to the main genesis file
    cp $NODE_DIR/config/genesis.json $GENESIS
    
    # Push genesis transaction to one place
    cp $NODE_DIR/config/gentx/*.json $GENTXS_DIR/$NODE_KEY.json
done

echo "- Collect genesis tx"
evmosd collect-gentxs --gentx-dir $GENTXS_DIR --home $INIT_DIR

echo "- Sync latest genesis and config files to all nodes"
for (( i=0 ; i<$NODE_COUNT ; i++ ));do
    NODE_KEY="node$i"
    NODE_DIR="$BUILD_DIR/$NODE_KEY"
    cp $GENESIS $CONFIG_APP $CONFIG_CLIENT $CONFIG $NODE_DIR/config/
done

echo "- Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
evmosd validate-genesis --home $INIT_DIR

