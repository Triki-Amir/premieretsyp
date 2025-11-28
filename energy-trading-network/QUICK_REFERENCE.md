# Energy Trading Network - Quick Reference

## 🚀 Quick Commands

### Start Network
```bash
cd network
./startNetwork.sh
```

### Deploy Chaincode
```bash
cd network
./deployChaincode.sh
```

### Stop Network
```bash
cd network
./stopNetwork.sh
```

### Start API Server
```bash
cd application
npm install          # First time only
node enrollAdmin.js  # First time only
npm start
```

## 📋 Sample Factories (Pre-loaded)

| Factory ID | Name | Initial Balance | Energy Type |
|------------|------|-----------------|-------------|
| Factory01 | Solar Manufacturing Plant | 1000 kWh | Solar |
| Factory02 | Wind Power Assembly | 800 kWh | Wind |
| Factory03 | Tech Production Facility | 500 kWh | Footstep |
| Factory04 | Heavy Industry Corp | 300 kWh | Solar |
| Factory05 | Electronics Assembly | 600 kWh | Wind |

## 🔗 API Examples (curl)

### Register Factory
```bash
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{"factoryId":"Factory20","name":"New Solar Plant","initialBalance":750,"energyType":"solar"}'
```

### Mint Tokens
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId":"Factory01","amount":200}'
```

### Transfer Energy
```bash
curl -X POST http://localhost:3000/api/energy/transfer \
  -H "Content-Type: application/json" \
  -d '{"fromFactoryId":"Factory01","toFactoryId":"Factory02","amount":100}'
```

### Create Trade
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{"tradeId":"T001","sellerId":"Factory01","buyerId":"Factory03","amount":150,"pricePerUnit":0.05}'
```

### Execute Trade
```bash
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId":"T001"}'
```

### Query Factory
```bash
curl http://localhost:3000/api/factory/Factory01
```

### Query Balance
```bash
curl http://localhost:3000/api/factory/Factory01/balance
```

### List All Factories
```bash
curl http://localhost:3000/api/factories
```

## 🌐 Useful URLs

- **API Server**: http://localhost:3000
- **API Health**: http://localhost:3000/api/health
- **CouchDB UI**: http://localhost:5984/_utils/ (admin/adminpw)

## 📊 Energy Types

- **solar**: Solar panels
- **wind**: Wind turbines
- **footstep**: Footstep power generation

## 💡 Common Workflows

### Workflow 1: Factory Generates and Sells Energy
```bash
# 1. Factory generates surplus
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId":"Factory01","amount":500}'

# 2. Create trade
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{"tradeId":"T002","sellerId":"Factory01","buyerId":"Factory04","amount":200,"pricePerUnit":0.08}'

# 3. Execute trade
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId":"T002"}'
```

### Workflow 2: Check Trading Activity
```bash
# Check seller's new balance
curl http://localhost:3000/api/factory/Factory01/balance

# Check buyer's new balance
curl http://localhost:3000/api/factory/Factory04/balance

# View trade details
curl http://localhost:3000/api/trade/T002
```

## 🔧 Troubleshooting Quick Fixes

### Network won't start
```bash
cd network
./stopNetwork.sh
docker system prune -f
./startNetwork.sh
```

### API not working
```bash
cd application
rm -rf wallet node_modules
npm install
node enrollAdmin.js
npm start
```

### View logs
```bash
docker logs peer0.org1.example.com -f
docker logs orderer.example.com -f
```
