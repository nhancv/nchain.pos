#!/bin/bash
HOME=/home/evmos
CHAINID=evmos_9000-1
RECIPIENT=evmos1rnuqkc857kpzr2hlmwew2y7qau0cp9y5e3gng4
AMOUNT=100000000000000000000aevmos
SENDER=$(evmosd keys show node0 -a --keyring-backend test --home $HOME)
TX_OUTPUT=$(evmosd tx bank send "$SENDER" "$RECIPIENT" "$AMOUNT" --from "$SENDER" --home $HOME --keyring-backend test --chain-id $CHAINID --gas auto --gas-adjustment 1.5 --gas-prices 7000aevmos --yes --output json)
TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash')
echo "Transaction hash: $TX_HASH"
evmosd query wait-tx "$TX_HASH" --chain-id $CHAINID > /dev/null 2>&1
TX_STATUS=$(echo "$TX_OUTPUT" | jq -r 'if .raw_log == "" then "OK" else .raw_log end')
echo "Transaction status: $TX_STATUS"

# Check balance
evmosd query bank balances "$RECIPIENT" --chain-id $CHAINID

# Execute
# docker exec -it node0 bash "/root/.evmosd/node_transfer.sh"
