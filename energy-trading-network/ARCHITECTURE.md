# Energy Trading Network Architecture

## System Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────── ┐
│                     INDUSTRIAL ZONE                                  │
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │Factory 01│  │Factory 02│  │Factory 03│  │Factory 04│  ... 20      │
│  │  Solar   │  │   Wind   │  │ Footstep │  │  Solar   │              │
│  │ 1000 kWh │  │ 800 kWh  │  │ 500 kWh  │  │ 300 kWh  │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │             │             │             │                    │
│       └─────────────┴─────────────┴─────────────┘                    │
│                            │                                         │
└────────────────────────────┼─────────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   REST API      │
                    │  (Port 3000)    │
                    │                 │
                    │  - Register     │
                    │  - Mint         │
                    │  - Transfer     │
                    │  - Trade        │
                    │  - Query        │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
    ┌───────▼──────┐  ┌─────▼──────┐  ┌─────▼──────┐
    │   Fabric     │  │   Peer     │  │  CouchDB   │
    │   Gateway    │  │  Node      │  │  State DB  │
    │              │  │ (Port 7051)│  │(Port 5984) │
    └──────────────┘  └─────┬──────┘  └────────────┘
                            │
                     ┌──────▼──────┐
                     │   Orderer   │
                     │ (Port 7050) │
                     │             │
                     │  Consensus  │
                     └──────┬──────┘
                            │
                     ┌──────▼──────┐
                     │ Blockchain  │
                     │   Ledger    │
                     │             │
                     │  Immutable  │
                     │  Records    │
                     └─────────────┘
```

## Smart Contract Functions Flow

```
┌─────────────────────────────────────────────────────────────┐
│              ENERGY TOKEN SMART CONTRACT                    │
└─────────────────────────────────────────────────────────────┘

1. REGISTRATION FLOW
   Factory → RegisterFactory() → Ledger
   ├─ Create factory record
   ├─ Set initial balance
   └─ Store energy type

2. MINTING FLOW (Generate Energy)
   Factory → MintEnergyTokens() → Ledger
   ├─ Validate factory exists
   ├─ Add tokens to balance
   └─ Update ledger

3. TRANSFER FLOW (Direct Transfer)
   Factory A → TransferEnergy() → Factory B
   ├─ Check sender balance
   ├─ Deduct from sender
   ├─ Add to receiver
   └─ Update both in ledger

4. TRADING FLOW (Formal Trade)
   Step 1: Factory A → CreateEnergyTrade() → Pending Trade
           ├─ Verify seller has energy
           ├─ Verify buyer exists
           └─ Create trade record (status: pending)
   
   Step 2: System → ExecuteTrade() → Completed Trade
           ├─ Transfer energy from seller to buyer
           ├─ Update trade status (status: completed)
           └─ Record on ledger

5. QUERY FLOW (Read Operations)
   User → GetFactory() → Factory Data
        → GetEnergyBalance() → Balance
        → GetAllFactories() → All Factories
        → GetTrade() → Trade Details
        → GetFactoryHistory() → Transaction History
```

## Energy Trading Process

```
┌────────────────────────────────────────────────────────────────┐
│                  TYPICAL TRADE SCENARIO                         │
└────────────────────────────────────────────────────────────────┘

Day 1: Solar Factory generates surplus
┌──────────────────┐
│  Factory01       │  Generates 500 kWh surplus
│  (Solar)         │  ──────────────────────────────►
│                  │        MintEnergyTokens()
│  Balance:        │
│  1000 → 1500 kWh │
└──────────────────┘

Day 2: Factory needs energy
┌──────────────────┐
│  Factory04       │  Needs 200 kWh
│  (Heavy Industry)│  Current: 300 kWh (not enough)
│                  │
└──────────────────┘

Day 3: Create trade agreement
┌──────────────────┐         ┌──────────────────┐
│  Factory01       │         │  Factory04       │
│  (Seller)        │ ───────►│  (Buyer)         │
│                  │  Trade:  │                  │
│  Offers: 200 kWh │  200 kWh │  Needs: 200 kWh  │
│  Price: 0.08/kWh │  @ 0.08  │  Pays: 16 tokens │
│                  │  = 16    │                  │
└──────────────────┘         └──────────────────┘
         │                            │
         └──────────┬─────────────────┘
                    ▼
         CreateEnergyTrade(TRADE001)
                    │
                    ▼
              [Pending Trade]
                    │
                    ▼
            ExecuteTrade(TRADE001)
                    │
         ┌──────────┴─────────┐
         ▼                    ▼
┌──────────────────┐  ┌──────────────────┐
│  Factory01       │  │  Factory04       │
│  Balance:        │  │  Balance:        │
│  1500 → 1300 kWh │  │  300 → 500 kWh   │
└──────────────────┘  └──────────────────┘
         │                    │
         └──────────┬─────────┘
                    ▼
         [Trade Completed & Recorded]
                    │
                    ▼
         [Immutable Blockchain Record]
```

## Data Structure

```
Factory Structure:
{
  "id": "Factory01",
  "name": "Solar Manufacturing Plant",
  "energyBalance": 1000.0,
  "energyType": "solar"
}

Energy Trade Structure:
{
  "tradeId": "TRADE001",
  "sellerId": "Factory01",
  "buyerId": "Factory04",
  "amount": 200.0,
  "pricePerUnit": 0.08,
  "totalPrice": 16.0,
  "timestamp": "2025-11-08T10:30:00Z",
  "status": "completed"
}
```

## Network Components

```
┌────────────────────────────────────────────────┐
│  BLOCKCHAIN NETWORK COMPONENTS                 │
├────────────────────────────────────────────────┤
│                                                 │
│  1. Orderer (Port 7050)                        │
│     └─ Orders transactions                     │
│     └─ Creates blocks                          │
│     └─ Distributes to peers                    │
│                                                 │
│  2. Peer Node (Port 7051)                      │
│     └─ Validates transactions                  │
│     └─ Executes chaincode                      │
│     └─ Maintains ledger copy                   │
│                                                 │
│  3. CouchDB (Port 5984)                        │
│     └─ Stores world state                      │
│     └─ Enables rich queries                    │
│     └─ Indexes data                            │
│                                                 │
│  4. Smart Contract (Chaincode)                 │
│     └─ Business logic                          │
│     └─ Token management                        │
│     └─ Trade execution                         │
│                                                 │
│  5. REST API (Port 3000)                       │
│     └─ User interface                          │
│     └─ HTTP endpoints                          │
│     └─ JSON responses                          │
│                                                 │
└────────────────────────────────────────────────┘
```

## Security & Trust

```
┌─────────────────────────────────────────────────┐
│          BLOCKCHAIN SECURITY FEATURES           │
├─────────────────────────────────────────────────┤
│                                                  │
│  ✓ TLS Encryption                               │
│    └─ All network traffic encrypted            │
│                                                  │
│  ✓ Digital Signatures                           │
│    └─ Every transaction is signed              │
│                                                  │
│  ✓ Membership Service Provider (MSP)            │
│    └─ Only registered factories can trade      │
│                                                  │
│  ✓ Immutable Ledger                             │
│    └─ Transactions cannot be altered           │
│                                                  │
│  ✓ Consensus Mechanism                          │
│    └─ Network agrees on transaction order      │
│                                                  │
│  ✓ Audit Trail                                  │
│    └─ Complete history of all transactions     │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Scalability

The network supports:
- ✓ 20+ factories
- ✓ Multiple peers per organization
- ✓ Thousands of transactions per second
- ✓ Horizontal scaling with more peers
- ✓ Load balancing across peers
- ✓ Sharding for large-scale deployments
