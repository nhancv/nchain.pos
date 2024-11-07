#!/bin/bash

# Config Chain
CHAIN="evmos" # Default is evmos
CHAINID="$CHAIN"_9000-1 # # Default is evmos_9000-1

# Config paths
BUILD_DIR=$(pwd)/build
INIT_DIR=$BUILD_DIR/evmosd
CONF_DIR=$INIT_DIR/config
GENESIS=$CONF_DIR/genesis.json
CONFIG_APP=$CONF_DIR/app.toml
CONFIG_CLIENT=$CONF_DIR/client.toml
CONFIG=$CONF_DIR/config.toml

NODE_KEY="extnode0"
echo "Create external node data: $NODE_KEY"
NODE_DIR="$BUILD_DIR/$NODE_KEY"
echo " + Creating $NODE_KEY at: $NODE_DIR"

# Clean up old data
rm -rf $NODE_DIR
mkdir -p $NODE_DIR/config/

echo "Init $CHAIN with moniker=$NODE_KEY and chain-id=$CHAINID"
#├── config
#│   ├── app.toml
#│   ├── client.toml
#│   ├── config.toml
#│   ├── genesis.json
#│   ├── node_key.json
#│   └── priv_validator_key.json
#├── data
#│   └── priv_validator_state.json
evmosd init $NODE_KEY --chain-id $CHAINID --home $NODE_DIR > /dev/null 2>&1

echo "Sync with latest chain config and genesis files"
cp $GENESIS $CONFIG_APP $CONFIG_CLIENT $CONFIG $NODE_DIR/config/
