# Evmos Blockchain Multi Nodes

The blockchain running on Evmos, using 4 nodes, Prometheus for metrics, Grafana for visualization. 

A `Bot` process to create mock transactions.

## Docs

- Home: https://docs.evmos.org
- Configuration: 
    - Evmos: https://docs.evmos.org/validate/setup-and-configuration/configuration
    - Tendermint Core: https://docs.tendermint.com/v0.34/tendermint-core/configuration.html
- Fee market configuration: https://docs.evmos.org/protocol/modules/feemarket
- Evmos unit/denomination:
  ```
  1 EVMOS = 10^18 atto evmos = 10^18 aevmos
  1 ETH = 10^18 wei
  ```

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

The main chain must be launched first.

```
docker-compose -f docker-compose_external.yml up -d
```

### Stake token to external node

```
docker exec -it {EXTERNAL_NODE} bash "/root/.evmosd/node_stake.sh"
```

### UnStake token to external node

Default "unstake_time"/"unbonding_time" is "1814400s" (21 days). The tokens will be available in your wallet after unbonding period.

```
docker exec -it {EXTERNAL_NODE} bash "/root/.evmosd/node_unstake.sh"
```