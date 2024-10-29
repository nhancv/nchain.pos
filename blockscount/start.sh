#!/bin/bash
#https://docs.blockscout.com/setup/deployment/frontend-migration/all-in-one-container
# This script can run on macOS only

BLOCKSCOUT_RPC="http://host.docker.internal:8545"
BLOCKSCOUT_CHAINID="9000"
BLOCKSCOUT_URL="localhost"
BLOCKSCOUT_PROTOCOL="http"
BLOCKSCOUT_PROTOCOL_WS="ws"

# Set the repository URL and directory
REPO_URL="https://github.com/nhancv/blockscout.git"
REPO_DIR=".blockscout_all"  # The directory name where the repo will be cloned
# Check if the directory exists
if [ ! -d "$REPO_DIR" ]; then
  echo "Blockscout does not exist. Cloning the repository..."
  git clone "$REPO_URL" $REPO_DIR
  cd "$REPO_DIR" || exit
else
  echo "Blockscout exists. Navigating to the repo and resetting changes..."
  ./stop.sh
  cd "$REPO_DIR" || exit
#  rm -rf docker-compose
  git reset --hard


fi

# Working directory
cd docker-compose

# Update common envs: https://github.com/nhancv/blockscout/blob/master/docker-compose/envs/common-blockscout.env
COMMON_CONFIG="envs/common-blockscout.env"
sed -i '' "s|ETHEREUM_JSONRPC_VARIANT=geth|ETHEREUM_JSONRPC_VARIANT=besu|g" $COMMON_CONFIG
sed -i '' "s|http://host.docker.internal:8545/|${BLOCKSCOUT_RPC}|g" $COMMON_CONFIG
sed -i '' "s|# INDEXER_DISABLE_BLOCK_REWARD_FETCHER=|INDEXER_DISABLE_BLOCK_REWARD_FETCHER=true|g" $COMMON_CONFIG

# Stats
STATS_CONFIG="envs/common-stats.env"
printf '\nSTATS__IGNORE_BLOCKSCOUT_API_ABSENCE=true' >> $STATS_CONFIG
#printf "\nSTATS__BLOCKSCOUT_API_URL=${BLOCKSCOUT_PROTOCOL}://${BLOCKSCOUT_URL}" >> $STATS_CONFIG

# User ops
USEROPS_CONFIG="envs/common-user-ops-indexer.env"
sed -i '' "s|USER_OPS_INDEXER__INDEXER__REALTIME__ENABLED=true|USER_OPS_INDEXER__INDEXER__REALTIME__ENABLED=false|g" $USEROPS_CONFIG
sed -i '' "s|USER_OPS_INDEXER__INDEXER__RPC_URL=\"\"|USER_OPS_INDEXER__INDEXER__RPC_URL=\"${BLOCKSCOUT_RPC}\"|g" $USEROPS_CONFIG
sed -i '' "s|USER_OPS_INDEXER__INDEXER__ENTRYPOINTS__V06=true|USER_OPS_INDEXER__INDEXER__ENTRYPOINTS__V06=false|g" $USEROPS_CONFIG
sed -i '' "s|USER_OPS_INDEXER__INDEXER__ENTRYPOINTS__V07=true|USER_OPS_INDEXER__INDEXER__ENTRYPOINTS__V07=false|g" $USEROPS_CONFIG

# Disable ads
FRONTEND_CONFIG="envs/common-frontend.env"
sed -i '' "s|NEXT_PUBLIC_NETWORK_ID=5|NEXT_PUBLIC_NETWORK_ID=${BLOCKSCOUT_CHAINID}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_API_HOST=localhost|NEXT_PUBLIC_API_HOST=${BLOCKSCOUT_URL}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_API_PROTOCOL=http|NEXT_PUBLIC_API_PROTOCOL=${BLOCKSCOUT_PROTOCOL}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_APP_HOST=localhost|NEXT_PUBLIC_APP_HOST=${BLOCKSCOUT_URL}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_APP_PROTOCOL=http|NEXT_PUBLIC_APP_PROTOCOL=${BLOCKSCOUT_PROTOCOL}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_API_WEBSOCKET_PROTOCOL=ws|NEXT_PUBLIC_API_WEBSOCKET_PROTOCOL=${BLOCKSCOUT_PROTOCOL_WS}|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_STATS_API_HOST=http://localhost:8080|NEXT_PUBLIC_STATS_API_HOST=${BLOCKSCOUT_PROTOCOL}://${BLOCKSCOUT_URL}:8080|g" $FRONTEND_CONFIG
sed -i '' "s|NEXT_PUBLIC_VISUALIZE_API_HOST=http://localhost:8081|NEXT_PUBLIC_VISUALIZE_API_HOST=${BLOCKSCOUT_PROTOCOL}://${BLOCKSCOUT_URL}:8081|g" $FRONTEND_CONFIG
printf '\nNEXT_PUBLIC_AD_BANNER_PROVIDER=none' >> $FRONTEND_CONFIG
printf '\nNEXT_PUBLIC_AD_TEXT_PROVIDER=none' >> $FRONTEND_CONFIG

# Update environment variables in the docker-compose.yml file
APP_CONFIG="docker-compose.yml"
sed -i '' "s|http://host.docker.internal:8545/|${BLOCKSCOUT_RPC}|g" $APP_CONFIG
sed -i '' "s|ETHEREUM_JSONRPC_TRACE_URL: ${BLOCKSCOUT_RPC}|INDEXER_DISABLE_INTERNAL_TRANSACTIONS_FETCHER: 'true'|g" $APP_CONFIG
sed -i '' "s|ETHEREUM_JSONRPC_WS_URL: ws://host.docker.internal:8545/|INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER: 'true'|g" $APP_CONFIG
sed -i '' "s|CHAIN_ID: '1337'|CHAIN_ID: '${BLOCKSCOUT_CHAINID}'|g" $APP_CONFIG

# Update proxy config
PROXY_CONFIG="proxy/default.conf.template"
sed -i '' "s|add_header 'Access-Control-Allow-Origin' 'http://localhost' always;|add_header 'Access-Control-Allow-Origin' '${BLOCKSCOUT_PROTOCOL}://${BLOCKSCOUT_URL}' always;|g" $PROXY_CONFIG


# Start blockscout
docker-compose -f $APP_CONFIG up -d

echo "Blockscout is running at ${BLOCKSCOUT_PROTOCOL}://${BLOCKSCOUT_URL}"