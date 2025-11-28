# Energy Trading Network - Blockchain for Industrial Zone

A Hyperledger Fabric blockchain network for trading surplus energy between factories in a private industrial zone. Factories can generate energy from solar, wind, or footstep power sources and trade their surplus using energy tokens.

## 🏭 Overview

This blockchain solution enables 20+ factories in an industrial zone to:
- Generate energy tokens when they produce surplus energy
- Trade energy tokens with other factories
- Track energy production and consumption transparently
- Maintain immutable records of all energy transactions

## 📂 Folder Structure

This project requires the following folder structure (already set up):
```
C:\premieretsyp\
├── energy-trading-network\    (Your energy trading project)
│   ├── application\
│   ├── chaincode\
│   └── network\
└── fabric-samples\             (Hyperledger Fabric test network)
    ├── bin\
    ├── config\
    └── test-network\
```

## 🎯 Features

- **Energy Token Management**: Mint tokens when surplus energy is generated
- **Peer-to-Peer Trading**: Direct energy trading between factories
- **Multiple Energy Sources**: Support for solar, wind, and footstep power
- **Transaction History**: Complete audit trail of all energy trades
- **REST API**: Easy integration with factory management systems
- **Real-time Queries**: Instant access to energy balances and trade status

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Docker Desktop** (v20.10 or higher)
   - Download from: https://www.docker.com/products/docker-desktop
   - Must be running before starting the network

2. **Node.js** (v14 or higher) and npm
   - Download from: https://nodejs.org/

3. **Go** (v1.20 or higher) - for chaincode
   - Download from: https://golang.org/dl/

4. **Git Bash** (for Windows users)
   - Included with Git for Windows: https://git-scm.com/download/win

5. **Hyperledger Fabric Samples** (already downloaded in parent directory)

## 🚀 Quick Start

### Step 1: Start the Network

Open Git Bash and navigate to the network directory:

```bash
cd energy-trading-network/network
./startNetwork.sh
```

This will:
- Generate cryptographic materials (certificates/keys)
- Start Docker containers (orderer, peer, CouchDB)
- Create the energy trading channel

### Step 2: Deploy the Smart Contract

```bash
cd energy-trading-network/network
./deployChaincode.sh
```

This will:
- Package the energy token chaincode
- Install chaincode on the peer
- Approve and commit the chaincode definition
- Initialize the ledger with 5 sample factories

### Step 3: Set Up the Application

```bash
cd ../application
npm install
node enrollAdmin.js
```

### Step 4: Start the API Server

```bash
npm start
```

The API server will be available at: http://localhost:3000

## 📡 API Endpoints

### Factory Management

#### Register a New Factory
```bash
POST /api/factory/register
Content-Type: application/json

{
  "factoryId": "Factory06",
  "name": "Green Energy Plant",
  "initialBalance": 500.0,
  "energyType": "solar"
}
```

#### Get Factory Information
```bash
GET /api/factory/Factory01
```

#### Get All Factories
```bash
GET /api/factories
```

#### Get Factory Balance
```bash
GET /api/factory/Factory01/balance
```

#### Get Factory History
```bash
GET /api/factory/Factory01/history
```

### Energy Token Operations

#### Mint Energy Tokens
When a factory generates surplus energy:

```bash
POST /api/energy/mint
Content-Type: application/json

{
  "factoryId": "Factory01",
  "amount": 250.5
}
```

#### Transfer Energy Between Factories
```bash
POST /api/energy/transfer
Content-Type: application/json

{
  "fromFactoryId": "Factory01",
  "toFactoryId": "Factory02",
  "amount": 100.0
}
```

### Energy Trading

#### Create a Trade
```bash
POST /api/trade/create
Content-Type: application/json

{
  "tradeId": "TRADE001",
  "sellerId": "Factory01",
  "buyerId": "Factory02",
  "amount": 150.0,
  "pricePerUnit": 0.05
}
```

#### Execute a Trade
```bash
POST /api/trade/execute
Content-Type: application/json

{
  "tradeId": "TRADE001"
}
```

#### Get Trade Information
```bash
GET /api/trade/TRADE001
```

## 💡 Usage Examples

### Example 1: Factory Generates Surplus Energy

Factory01 (Solar Plant) generates 500 kWh of surplus energy:

```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "amount": 500
  }'
```

### Example 2: Create and Execute a Trade

Factory01 wants to sell 200 kWh to Factory03:

```bash
# Step 1: Create the trade
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE202311001",
    "sellerId": "Factory01",
    "buyerId": "Factory03",
    "amount": 200,
    "pricePerUnit": 0.08
  }'

# Step 2: Execute the trade
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE202311001"
  }'
```

### Example 3: Check Factory Balances

```bash
# Get Factory01 balance
curl http://localhost:3000/api/factory/Factory01/balance

# Response:
# {
#   "success": true,
#   "data": {
#     "factoryId": "Factory01",
#     "balance": 1300
#   }
# }
```

### Example 4: View All Factories

```bash
curl http://localhost:3000/api/factories
```

## 🏗️ Project Structure

```
energy-trading-network/
├── chaincode/                   # Smart contract code
│   ├── energyToken.go          # Main chaincode with all functions
│   └── go.mod                  # Go module dependencies
├── network/                     # Network configuration
│   ├── docker-compose.yml      # Docker services definition
│   ├── startNetwork.sh         # Script to start network
│   ├── stopNetwork.sh          # Script to stop network
│   ├── deployChaincode.sh      # Script to deploy chaincode
│   └── networkSetup.sh         # Channel and peer setup
└── application/                 # Client application
    ├── app.js                  # REST API server
    ├── enrollAdmin.js          # Admin enrollment script
    ├── package.json            # Node.js dependencies
    └── wallet/                 # User identities (auto-generated)
```

## 🔧 Smart Contract Functions

The energy token chaincode provides the following functions:

| Function | Description | Parameters |
|----------|-------------|------------|
| `InitLedger` | Initialize with sample factories | None |
| `RegisterFactory` | Register a new factory | factoryId, name, initialBalance, energyType |
| `MintEnergyTokens` | Generate energy tokens | factoryId, amount |
| `TransferEnergy` | Transfer tokens between factories | fromFactoryId, toFactoryId, amount |
| `CreateEnergyTrade` | Create a trade transaction | tradeId, sellerId, buyerId, amount, pricePerUnit |
| `ExecuteTrade` | Complete a pending trade | tradeId |
| `GetFactory` | Get factory information | factoryId |
| `GetEnergyBalance` | Get factory's token balance | factoryId |
| `GetAllFactories` | List all registered factories | None |
| `GetTrade` | Get trade information | tradeId |
| `GetFactoryHistory` | Get transaction history | factoryId |

## 🛠️ Direct Chaincode Testing

You can also interact with the chaincode directly using the peer CLI:

```bash
# Set environment (run from network directory)
export FABRIC_CFG_PATH=${PWD}/../../fabric-samples/config
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

# Query all factories
peer chaincode query -C energychannel -n energytoken -c '{"Args":["GetAllFactories"]}'

# Get specific factory
peer chaincode query -C energychannel -n energytoken -c '{"Args":["GetFactory","Factory01"]}'

# Mint tokens
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile ${PWD}/../../fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C energychannel -n energytoken --peerAddresses localhost:7051 \
  --tlsRootCertFiles ${PWD}/../../fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  -c '{"function":"MintEnergyTokens","Args":["Factory01","300"]}'
```

## 📊 Monitoring

### View Docker Containers
```bash
docker ps
```

### View Peer Logs
```bash
docker logs peer0.industrial.energyzone.com -f
```

### Access CouchDB UI
Open http://localhost:5984/_utils/ in your browser
- Username: admin
- Password: adminpw

## 🔒 Security Features

- **TLS Encryption**: All network communications are encrypted
- **MSP (Membership Service Provider)**: Identity management for factories
- **Chaincode Endorsement**: Transactions require peer approval
- **Immutable Ledger**: All transactions are permanent and auditable
- **Access Control**: Only registered factories can participate

## 🛑 Stopping the Network

To stop the network and clean up:

```bash
cd network
./stopNetwork.sh
```

This will:
- Stop all Docker containers
- Remove volumes
- Clean up generated files

## 🐛 Troubleshooting

### Docker is not running
**Error**: "Cannot connect to the Docker daemon"
**Solution**: Start Docker Desktop and wait for it to fully initialize

### Port already in use
**Error**: "Port 7051 is already allocated"
**Solution**: 
```bash
./stopNetwork.sh
docker system prune -a
./startNetwork.sh
```

### Chaincode deployment fails
**Error**: "Failed to install chaincode"
**Solution**: 
1. Make sure the network is running: `docker ps`
2. Check Go dependencies: `cd chaincode && go mod tidy`
3. Redeploy: `./deployChaincode.sh`

### Cannot connect to API
**Error**: "ECONNREFUSED localhost:3000"
**Solution**: 
1. Make sure you ran `npm install` in the application directory
2. Enroll admin: `node enrollAdmin.js`
3. Start the server: `npm start`

## 📚 Additional Resources

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Samples](https://github.com/hyperledger/fabric-samples)
- [Fabric SDK for Node.js](https://github.com/hyperledger/fabric-sdk-node)

## 📝 License

Apache-2.0

## 👥 Contributing

This is a demonstration project for an industrial energy trading zone. Feel free to extend it with additional features:
- Add price discovery mechanisms
- Implement automated trading
- Create a web dashboard
- Add support for renewable energy certificates
- Integrate IoT sensors for automatic energy measurement

## 📞 Support

For issues and questions, please refer to the troubleshooting section above.

---

**Built with Hyperledger Fabric for sustainable energy trading** ⚡🌱
