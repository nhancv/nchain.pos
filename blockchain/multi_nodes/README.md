# Evmos Blockchain Multi Nodes

The blockchain running on Evmos, using 4 nodes, Prometheus for metrics, Grafana for visualization. 

A `Bot` process to create mock transactions.

## Docs

https://docs.evmos.org

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
- Evmos Node (Metrics): http://localhost:26660/metrics
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