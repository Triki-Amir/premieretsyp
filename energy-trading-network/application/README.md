# Energy Trading Network - Application

Unified application for factories to trade energy on the blockchain with secure authentication.

## Architecture

This application uses a **dual-database architecture**:

### PostgreSQL - Credentials & Non-Essential Data
- Login credentials (email, password hash, fiscal matricule)
- Factory profiles (name, location, contact info, logo)
- Login history and security audit logs
- Password reset tokens

### CouchDB (via Hyperledger Fabric Blockchain) - Trading Data
- Energy balances and currency (TEC - Tunisian Energy Coin)
- Trading offers and transactions
- Immutable transaction history
- Factory trading records

## Quick Start

### 1. Start PostgreSQL Database
```bash
npm run db:start
```

### 2. Start Blockchain Network
```bash
cd ../network
./startNetwork.sh
./deployChaincode.sh
```

### 3. Install Dependencies and Start Application
```bash
npm install
npm start
```

The application will be available at `http://localhost:3000`

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Server Configuration
PORT=3000

# PostgreSQL Configuration
PG_HOST=localhost
PG_PORT=5432
PG_USER=energy_admin
PG_PASSWORD=energy_secure_password
PG_DATABASE=energy_credentials
```

## API Endpoints

### Authentication
- `POST /signup` - Register new factory
- `POST /login` - Authenticate factory user

### Factories
- `GET /factories` - Get all factories
- `GET /factory/:id` - Get factory by ID
- `PUT /factory/:id/energy` - Update factory energy data
- `POST /api/factory/register` - Register factory (blockchain format)

### Trading
- `GET /offers` - Get all active offers
- `POST /offers` - Create new offer
- `PUT /offers/:id` - Update offer status
- `GET /trades` - Get all trades
- `POST /trades` - Create new trade
- `POST /trades/:id/execute` - Execute trade

### Energy Operations
- `POST /api/energy/mint` - Mint energy tokens
- `POST /api/energy/transfer` - Transfer energy between factories

### Health Check
- `GET /api/health` - Check system status
- `GET /test` - Simple connectivity test

## Database Management

### Start PostgreSQL
```bash
npm run db:start
```

### Stop PostgreSQL
```bash
npm run db:stop
```

### View PostgreSQL Logs
```bash
docker logs energy_trading_postgres
```

## Security Features

- Password hashing with bcrypt (10 salt rounds)
- Login history tracking with IP and user agent
- Separate storage for credentials and trading data
- Immutable blockchain ledger for trading transactions

## Fallback Mode

If PostgreSQL is not available, the application falls back to storing credentials on the blockchain. This ensures the application remains functional even without PostgreSQL.

## Development

```bash
npm run dev  # Start with nodemon for auto-reload
```

## Enrolling Admin

Before registering factories, enroll the admin user:

```bash
npm run enroll
```
