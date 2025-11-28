# ⚠️ DEPRECATED - Mobile Backend Has Been Merged

**IMPORTANT:** This Docker setup is **DEPRECATED**. The mobile app backend has been merged with the blockchain application.

## New Architecture

The mobile backend functionality has been unified with the blockchain application located at:

```
energy-trading-network/application/app.js
```

### Database Change

- **OLD:** MySQL (docker container)
- **NEW:** CouchDB via Hyperledger Fabric (couchdb0 and couchdb1)

All factory data, user authentication, offers, and trades are now stored on the blockchain ledger, which uses CouchDB as its state database.

## How to Run the Unified Application

### 1. Start the Blockchain Network

```bash
cd energy-trading-network/network
./startNetwork.sh
```

This starts the Hyperledger Fabric network including:
- Orderer
- Peer nodes
- CouchDB instances (couchdb0 at port 5984, couchdb1 at port 7984)

### 2. Deploy the Chaincode

```bash
./deployChaincode.sh
```

### 3. Start the Unified Application

```bash
cd ../application
npm install
npm start
```

The unified application runs on port 3000 (configurable via PORT environment variable).

## API Endpoints

The unified application supports all endpoints from both the original blockchain app and the mobile backend:

### Authentication (Mobile App)
- **POST** `/login` - Login with email and password
- **POST** `/signup` - Register new factory with authentication

### Factories (Mobile App Format)
- **GET** `/factories` - List all factories
- **GET** `/factory/:id` - Get factory by ID
- **PUT** `/factory/:id/energy` - Update factory energy data

### Factories (Blockchain Format)
- **POST** `/api/factory/register` - Register factory
- **GET** `/api/factory/:factoryId` - Get factory details
- **GET** `/api/factories` - List all factories

### Offers (Mobile App)
- **GET** `/offers` - List all active offers
- **POST** `/offers` - Create new offer
- **PUT** `/offers/:id` - Update offer status

### Trades (Mobile App Format)
- **GET** `/trades` - List all trades
- **POST** `/trades` - Create new trade
- **POST** `/trades/:id/execute` - Execute trade

### Trades (Blockchain Format)
- **POST** `/api/trade/create` - Create trade
- **POST** `/api/trade/execute` - Execute trade
- **GET** `/api/trade/:tradeId` - Get trade details

### Energy Tokens
- **POST** `/api/energy/mint` - Mint energy tokens
- **POST** `/api/energy/transfer` - Transfer energy

### Utility
- **GET** `/api/health` - Health check
- **GET** `/test` - Simple test endpoint
- **POST** `/seed` - Seed database with sample data

## Access CouchDB Admin

- CouchDB Org1: http://localhost:5984/_utils/ (admin/adminpw)
- CouchDB Org2: http://localhost:7984/_utils/ (admin/adminpw)

## Why This Change?

1. **Single Source of Truth:** All data is now on the blockchain
2. **No MySQL Required:** Eliminates the need for a separate database
3. **Decentralized:** Data is stored in CouchDB across multiple peers
4. **Immutable History:** Blockchain provides full transaction history
5. **Simplified Deployment:** One application instead of two
