# Energy Trading Network - Example Scenarios

## Scenario 1: Morning Surplus Energy from Solar Factory

**Situation**: Factory01 (Solar Plant) generates 800 kWh of surplus energy in the morning.

### Steps:

1. **Record surplus energy generation**
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory01",
    "amount": 800
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Minted 800 kWh of energy tokens for Factory01",
  "data": {
    "factoryId": "Factory01",
    "amount": 800
  }
}
```

2. **Check updated balance**
```bash
curl http://localhost:3000/api/factory/Factory01/balance
```

**Response:**
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory01",
    "balance": 1800
  }
}
```

---

## Scenario 2: Night Energy Deficit - Factory Needs Power

**Situation**: Factory04 (Heavy Industry) needs 300 kWh during night shift but has insufficient energy.

### Steps:

1. **Check current balance**
```bash
curl http://localhost:3000/api/factory/Factory04/balance
```

**Response:**
```json
{
  "success": true,
  "data": {
    "factoryId": "Factory04",
    "balance": 300
  }
}
```

2. **Create trade request with Factory01**
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_NIGHT_001",
    "sellerId": "Factory01",
    "buyerId": "Factory04",
    "amount": 300,
    "pricePerUnit": 0.10
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Trade TRADE_NIGHT_001 created successfully",
  "data": {
    "tradeId": "TRADE_NIGHT_001",
    "sellerId": "Factory01",
    "buyerId": "Factory04",
    "amount": 300,
    "pricePerUnit": 0.10,
    "totalPrice": 30
  }
}
```

3. **Execute the trade**
```bash
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "TRADE_NIGHT_001"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Trade TRADE_NIGHT_001 executed successfully",
  "data": {
    "tradeId": "TRADE_NIGHT_001"
  }
}
```

4. **Verify balances after trade**
```bash
# Factory01 (Seller)
curl http://localhost:3000/api/factory/Factory01/balance
# Response: { "balance": 1500 } (1800 - 300)

# Factory04 (Buyer)
curl http://localhost:3000/api/factory/Factory04/balance
# Response: { "balance": 600 } (300 + 300)
```

---

## Scenario 3: Wind Farm Generates During Storm

**Situation**: Factory02 (Wind Power) generates massive surplus during a storm.

### Steps:

1. **Record wind energy generation**
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory02",
    "amount": 1500
  }'
```

2. **Offer energy to multiple factories**

Create Trade 1 with Factory03:
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "STORM_TRADE_001",
    "sellerId": "Factory02",
    "buyerId": "Factory03",
    "amount": 400,
    "pricePerUnit": 0.07
  }'
```

Create Trade 2 with Factory05:
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "STORM_TRADE_002",
    "sellerId": "Factory02",
    "buyerId": "Factory05",
    "amount": 600,
    "pricePerUnit": 0.07
  }'
```

3. **Execute both trades**
```bash
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId": "STORM_TRADE_001"}'

curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId": "STORM_TRADE_002"}'
```

---

## Scenario 4: New Factory Joins the Network

**Situation**: Factory20 (New Solar Installation) joins the industrial zone.

### Steps:

1. **Register the new factory**
```bash
curl -X POST http://localhost:3000/api/factory/register \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory20",
    "name": "Green Tech Solar Facility",
    "initialBalance": 1000,
    "energyType": "solar"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Factory Factory20 registered successfully",
  "data": {
    "factoryId": "Factory20",
    "name": "Green Tech Solar Facility",
    "initialBalance": 1000,
    "energyType": "solar"
  }
}
```

2. **First energy generation**
```bash
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{
    "factoryId": "Factory20",
    "amount": 500
  }'
```

3. **First trade with existing factory**
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "WELCOME_TRADE_001",
    "sellerId": "Factory20",
    "buyerId": "Factory04",
    "amount": 200,
    "pricePerUnit": 0.09
  }'
```

---

## Scenario 5: Footstep Power Generation in Peak Hours

**Situation**: Factory03 generates energy from employee footsteps during peak working hours.

### Steps:

1. **Record footstep energy (gradual accumulation)**
```bash
# Morning (8 AM)
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId": "Factory03", "amount": 50}'

# Midday (12 PM)
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId": "Factory03", "amount": 80}'

# Evening (5 PM)
curl -X POST http://localhost:3000/api/energy/mint \
  -H "Content-Type: application/json" \
  -d '{"factoryId": "Factory03", "amount": 70}'
```

2. **Total accumulated energy**
```bash
curl http://localhost:3000/api/factory/Factory03/balance
# Response: Original 500 + 50 + 80 + 70 = 700 kWh
```

---

## Scenario 6: Audit and Compliance Check

**Situation**: Management wants to audit Factory01's energy trading history.

### Steps:

1. **Get complete transaction history**
```bash
curl http://localhost:3000/api/factory/Factory01/history
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "txId": "abc123...",
      "value": {
        "id": "Factory01",
        "name": "Solar Manufacturing Plant",
        "energyBalance": 1000,
        "energyType": "solar"
      },
      "timestamp": "2025-11-08T08:00:00Z",
      "isDelete": false
    },
    {
      "txId": "def456...",
      "value": {
        "id": "Factory01",
        "energyBalance": 1800,
        "energyType": "solar"
      },
      "timestamp": "2025-11-08T09:30:00Z",
      "isDelete": false
    }
    // ... more history records
  ]
}
```

2. **Get current factory details**
```bash
curl http://localhost:3000/api/factory/Factory01
```

3. **List all active trades**
```bash
curl http://localhost:3000/api/trade/TRADE_NIGHT_001
curl http://localhost:3000/api/trade/STORM_TRADE_001
```

---

## Scenario 7: Weekly Energy Trading Summary

**Situation**: End of week - review all factories' status.

### Steps:

1. **Get all factories**
```bash
curl http://localhost:3000/api/factories
```

**Response:**
```json
{
  "success": true,
  "count": 20,
  "data": [
    {
      "id": "Factory01",
      "name": "Solar Manufacturing Plant",
      "energyBalance": 1500,
      "energyType": "solar"
    },
    {
      "id": "Factory02",
      "name": "Wind Power Assembly",
      "energyBalance": 1300,
      "energyType": "wind"
    },
    // ... all factories
  ]
}
```

2. **Calculate total energy in network**
```bash
# Sum all balances from the response
# Total Network Energy: Sum of all energyBalance values
```

3. **Identify top producers and consumers**
- Highest balance = Top producer with surplus
- Lowest balance = Highest consumer needing energy

---

## Scenario 8: Emergency Energy Transfer

**Situation**: Factory05 has a production emergency and needs immediate energy.

### Steps:

1. **Direct emergency transfer from Factory01**
```bash
curl -X POST http://localhost:3000/api/energy/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "fromFactoryId": "Factory01",
    "toFactoryId": "Factory05",
    "amount": 250
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Transferred 250 kWh from Factory01 to Factory05",
  "data": {
    "fromFactoryId": "Factory01",
    "toFactoryId": "Factory05",
    "amount": 250
  }
}
```

**Note**: Direct transfer is immediate (no pending trade state), useful for emergencies or pre-arranged agreements.

---

## Scenario 9: Price Comparison Shopping

**Situation**: Factory04 wants to compare energy prices from different sources.

### Steps:

1. **Create multiple pending trades with different sellers**

Option A - Solar energy:
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "COMPARE_A",
    "sellerId": "Factory01",
    "buyerId": "Factory04",
    "amount": 300,
    "pricePerUnit": 0.10
  }'
# Total: 30 tokens
```

Option B - Wind energy:
```bash
curl -X POST http://localhost:3000/api/trade/create \
  -H "Content-Type: application/json" \
  -d '{
    "tradeId": "COMPARE_B",
    "sellerId": "Factory02",
    "buyerId": "Factory04",
    "amount": 300,
    "pricePerUnit": 0.08
  }'
# Total: 24 tokens (better deal!)
```

2. **Execute the better trade**
```bash
curl -X POST http://localhost:3000/api/trade/execute \
  -H "Content-Type: application/json" \
  -d '{"tradeId": "COMPARE_B"}'
```

---

## Scenario 10: Monthly Reporting Dashboard

**Situation**: Generate monthly statistics for the industrial zone.

### PowerShell Script for Windows:

```powershell
# Get all factories
$factories = Invoke-RestMethod -Uri "http://localhost:3000/api/factories" -Method Get

# Calculate statistics
$totalEnergy = 0
$solarCount = 0
$windCount = 0
$footstepCount = 0

foreach ($factory in $factories.data) {
    $totalEnergy += $factory.energyBalance
    
    switch ($factory.energyType) {
        "solar" { $solarCount++ }
        "wind" { $windCount++ }
        "footstep" { $footstepCount++ }
    }
}

Write-Host "========================================"
Write-Host "   Monthly Energy Trading Report"
Write-Host "========================================"
Write-Host "Total Factories: $($factories.count)"
Write-Host "Total Energy in Network: $totalEnergy kWh"
Write-Host ""
Write-Host "Energy Sources:"
Write-Host "  - Solar: $solarCount factories"
Write-Host "  - Wind: $windCount factories"
Write-Host "  - Footstep: $footstepCount factories"
Write-Host "========================================"
```

---

## Best Practices

1. **Always check balance before trading**
2. **Use descriptive trade IDs** (e.g., "TRADE_2025_11_08_001")
3. **Record energy generation regularly**
4. **Monitor transaction history for auditing**
5. **Use direct transfer for emergencies only**
6. **Create pending trades for normal operations**
7. **Document energy prices for transparency**
8. **Regular balance reconciliation**

---

## Common Trade Patterns

### Pattern 1: Scheduled Daily Trade
- Create trades at fixed times
- Execute automatically
- Predictable pricing

### Pattern 2: Spot Market Trading
- Create trades on-demand
- Variable pricing based on supply
- Quick execution

### Pattern 3: Long-term Agreements
- Series of scheduled trades
- Fixed pricing
- Guaranteed supply

### Pattern 4: Emergency Supply
- Direct transfers
- Premium pricing
- Immediate execution
