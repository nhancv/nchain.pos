# Evmos Blockchain Single Node

The blockchain running on Evmos, using 1 node, Prometheus for metrics, Grafana for visualization. A `Bot` process to create mock transactions.

A `Bot` process to create mock transactions.

This chain is running with version evmosd CLI `20.0.0` at https://github.com/evmos/evmos/releases/tag/v20.0.0

## Docs

https://docs.evmos.org

## Run chain

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

### Dev tools

- Mnemonic Code Converter: https://iancoleman.io/bip39/