# Evmos Blockchain Multi Nodes

The blockchain running on Evmos, using 4 nodes, Prometheus for metrics, Grafana for visualization. 

A `Bot` process to create mock transactions.

## Docs

- Home: https://docs.evmos.org
- Evmos unit/denomination:
  ```
  1 EVMOS = 10^18 atto evmos = 10^18 aevmos
  1 ETH = 10^18 wei
  ```
- Links:
  + https://docs.evmos.org/protocol/modules
  + https://docs.tendermint.com/v0.34/tendermint-core/configuration.html
  + https://hub.cosmos.network/main/resources/genesis

## Install evmosd CLI:

This chain runs with version `20.0.0` at https://github.com/evmos/evmos/releases/tag/v20.0.0

## Run chain

- Setup genesis config files:

```
./genesis.sh
```

- Start:

```
docker-compose up -d
```

- Stop:

```
docker-compose down
```

### Access the Services:
- Prometheus (Metrics): http://localhost:9090
- Grafana (Dashboard): http://localhost:8000 (admin/admin)

### Metamask Configuration:
- Network Name: `Evmos Local`
- RPC URL: `http://localhost:8545`
- Chain ID: `9000`
- Symbol: `tEVMOS`
- Block Explorer URL: `http://localhost`

**NOTE**: You should import validator key to Metamask and transfer some coins to `0x1cF80B60F4F58221AaFFDBb2e513C0Ef1F809494` for `tx-bot1` to work.

### Dev tools

- Mnemonic Code Converter: https://iancoleman.io/bip39/

## Add more nodes

### Setup external node

- REQUIRED: The main chain must be launched first.

- Setup genesis config files:

```
./genesis_external.sh
```

- Start external node:

```
docker-compose -f docker-compose_external.yml up -d
```

- Stop external node:

```
docker-compose -f docker-compose_external.yml down
```

### Check external wallet balance

```
curl -X POST -H "Content-Type: application/json" \
--data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x1cF80B60F4F58221AaFFDBb2e513C0Ef1F809494", "latest"],"id":9000}' \
http://localhost:8545

=> It's empty now
{"jsonrpc":"2.0","id":9000,"result":"0x0"}
```

### Transfer coins from node0 to external node for staking

```
docker exec -it node0 bash "/root/.evmosd/node_transfer.sh"
```

### Stake token to a new external node

Create new validator initialized with a self-delegation transaction to it. Stake 10 Coins.
- To be a new validator in the list, use new staking, not ReStake 
- You cannot run a new staking again to an existing validator. Use ReStake instead.
- To withdraw the staked tokens, use UnStake. The validator is still in the list with status `BOND_STATUS_UNBONDING` and tokens is `0`. Wait for the unbonding period to get the tokens back automatically, and the validators will be updated accordingly.
- To stake more tokens, use ReStake.
- The unbonding period is 21 days by default. You can change it in the genesis file. But if the period is too short, the validator may be slashed. I tested with `1s`, after unstake the whole network was down and can't recover.

```
docker exec -it extnode0 bash "/root/.evmosd/node_stake.sh"
```

### UnStake token from external node

UnStake 1 Coins. Default "unstake_time"/"unbonding_time" is "1814400s" (21 days). The tokens will be available in your wallet after unbonding period.

```
docker exec -it extnode0 bash "/root/.evmosd/node_unstake.sh"
```

- Get balance of the external wallet with evmosd CLI:

```
docker exec -it extnode0 bash -c "evmosd query bank balances evmos1rnuqkc857kpzr2hlmwew2y7qau0cp9y5e3gng4"
```

### ReStake token to external node

ReStake 1 Coins.

```
docker exec -it extnode0 bash "/root/.evmosd/node_restake.sh"
```

### Check validators status

```
docker exec -it node0 bash -c "evmosd query staking validators"
```