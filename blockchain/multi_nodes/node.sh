#!/bin/bash
DATA_DIR="/home/evmos"

evmosd start --pruning=nothing --rpc.unsafe \
        --json-rpc.enable true --api.enable \
        --keyring-backend test --home $DATA_DIR