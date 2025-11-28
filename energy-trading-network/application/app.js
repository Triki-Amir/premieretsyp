/**
 * Energy Trading Application
 * Main application for factories to interact with the blockchain
 * Provides REST API endpoints for energy token operations
 */

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

// Initialize Express application
const app = express();

app.use(cors());
app.use(bodyParser.json());

// Configuration
const PORT = process.env.PORT || 3000;
const CHANNEL_NAME = 'energychannel';
const CHAINCODE_NAME = 'energytoken';

/**
 * Safely parse chaincode evaluateTransaction results which may be empty
 * @param {Buffer|string} result
 * @param {any} defaultValue
 */
function parseResult(result, defaultValue = null) {
    const s = result ? result.toString() : '';
    if (!s || s.trim().length === 0) return defaultValue;
    try {
        return JSON.parse(s);
    } catch (err) {
        throw new Error(`Invalid JSON returned from chaincode: ${err.message}`);
    }
}

/**
 * Get network connection and contract
 * @param {string} factoryId - Factory identifier for wallet lookup
 * @returns {Object} Contract instance
 */
async function getContract(factoryId = 'admin') {
    try {
        // Load connection profile
const ccpPath = path.resolve(
    __dirname,
    '..', '..',              
    'fabric-samples',
    'test-network',
    'organizations',
    'peerOrganizations',
    'org1.example.com',
    'connection-org1.json'
);

const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create wallet instance
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        // Check if user identity exists in wallet
        const identity = await wallet.get(factoryId);
        if (!identity) {
            throw new Error(`Identity ${factoryId} does not exist in the wallet. Run enrollAdmin.js first.`);
        }

        // Create gateway connection
        const gateway = new Gateway();
        await gateway.connect(ccp, {
            wallet,
            identity: factoryId,
            discovery: { enabled: true, asLocalhost: true }
        });

        // Get network channel
        const network = await gateway.getNetwork(CHANNEL_NAME);
        
        // Get chaincode contract
        const contract = network.getContract(CHAINCODE_NAME);

        return { contract, gateway };
    } catch (error) {
        throw new Error(`Failed to connect to network: ${error.message}`);
    }
}

/**
 * API Routes
 */

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Energy Trading API is running',
        timestamp: new Date().toISOString()
    });
});

/**
 * Register a new factory in the industrial zone
 * POST /api/factory/register
 * Body: { factoryId, name, initialBalance, energyType }
 */
app.post('/api/factory/register', async (req, res) => {
    try {
        const { factoryId, name, initialBalance, energyType, currencyBalance, dailyConsumption, availableEnergy } = req.body;

        // Validate required fields
        if (!factoryId || !name || initialBalance === undefined || !energyType) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Normalize numeric fields
        const initBalNum = Number(initialBalance);
        const currencyBalNum = currencyBalance === undefined ? 0 : Number(currencyBalance);
        const dailyConsNum = dailyConsumption === undefined ? 0 : Number(dailyConsumption);
        const availableNum = availableEnergy === undefined ? initBalNum : Number(availableEnergy);

        if (isNaN(initBalNum) || initBalNum < 0) {
            return res.status(400).json({ error: 'initialBalance must be a non-negative number' });
        }
        if (isNaN(currencyBalNum) || currencyBalNum < 0) {
            return res.status(400).json({ error: 'currencyBalance must be a non-negative number' });
        }
        if (isNaN(dailyConsNum) || dailyConsNum < 0) {
            return res.status(400).json({ error: 'dailyConsumption must be a non-negative number' });
        }
        if (isNaN(availableNum) || availableNum < 0) {
            return res.status(400).json({ error: 'availableEnergy must be a non-negative number' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction (include new fields)
        await contract.submitTransaction(
            'RegisterFactory',
            factoryId,
            name,
            initBalNum.toString(),
            energyType,
            currencyBalNum.toString(),
            dailyConsNum.toString(),
            availableNum.toString()
        );

        // Disconnect
        await gateway.disconnect();

        res.json({
            success: true,
            message: `Factory ${factoryId} registered successfully`,
            data: { 
                factoryId, 
                name, 
                initialBalance: initBalNum, 
                energyType, 
                currencyBalance: currencyBalNum,
                dailyConsumption: dailyConsNum,
                availableEnergy: availableNum
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Mint energy tokens when factory generates surplus energy
 * POST /api/energy/mint
 * Body: { factoryId, amount }
 */
app.post('/api/energy/mint', async (req, res) => {
    try {
        const { factoryId, amount } = req.body;

        // Validate input
        if (!factoryId || !amount || amount <= 0) {
            return res.status(400).json({ error: 'Invalid factoryId or amount' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction to mint tokens
        await contract.submitTransaction('MintEnergyTokens', factoryId, amount.toString());

        await gateway.disconnect();

        res.json({ 
            success: true, 
            message: `Minted ${amount} kWh of energy tokens for ${factoryId}`,
            data: { factoryId, amount }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Transfer energy tokens between factories
 * POST /api/energy/transfer
 * Body: { fromFactoryId, toFactoryId, amount }
 */
app.post('/api/energy/transfer', async (req, res) => {
    try {
        const { fromFactoryId, toFactoryId, amount } = req.body;

        // Validate input
        if (!fromFactoryId || !toFactoryId || !amount || amount <= 0) {
            return res.status(400).json({ error: 'Invalid input parameters' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction
        await contract.submitTransaction('TransferEnergy', fromFactoryId, toFactoryId, 
            amount.toString());

        await gateway.disconnect();

        res.json({ 
            success: true, 
            message: `Transferred ${amount} kWh from ${fromFactoryId} to ${toFactoryId}`,
            data: { fromFactoryId, toFactoryId, amount }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Create an energy trade between factories
 * POST /api/trade/create
 * Body: { tradeId, sellerId, buyerId, amount, pricePerUnit }
 */
app.post('/api/trade/create', async (req, res) => {
    try {
        const { tradeId, sellerId, buyerId, amount, pricePerUnit } = req.body;

        // Validate input
        if (!tradeId || !sellerId || !buyerId || !amount || !pricePerUnit) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction
        await contract.submitTransaction('CreateEnergyTrade', tradeId, sellerId, buyerId, 
            amount.toString(), pricePerUnit.toString());

        await gateway.disconnect();

        const totalPrice = amount * pricePerUnit;
        res.json({ 
            success: true, 
            message: `Trade ${tradeId} created successfully`,
            data: { tradeId, sellerId, buyerId, amount, pricePerUnit, totalPrice }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Execute a pending energy trade
 * POST /api/trade/execute
 * Body: { tradeId }
 */
app.post('/api/trade/execute', async (req, res) => {
    try {
        const { tradeId } = req.body;

        if (!tradeId) {
            return res.status(400).json({ error: 'Trade ID is required' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction
        await contract.submitTransaction('ExecuteTrade', tradeId);

        await gateway.disconnect();

        res.json({ 
            success: true, 
            message: `Trade ${tradeId} executed successfully`,
            data: { tradeId }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get factory information
 * GET /api/factory/:factoryId
 */
app.get('/api/factory/:factoryId', async (req, res) => {
    try {
        const { factoryId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query factory data
        const result = await contract.evaluateTransaction('GetFactory', factoryId);
        const factory = parseResult(result, null);

        await gateway.disconnect();

        if (factory === null) {
            res.status(404).json({ error: 'Factory not found or empty response from chaincode' });
        } else {
            res.json({ success: true, data: factory });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get energy balance of a factory
 * GET /api/factory/:factoryId/balance
 */
app.get('/api/factory/:factoryId/balance', async (req, res) => {
    try {
        const { factoryId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query balance
        const result = await contract.evaluateTransaction('GetEnergyBalance', factoryId);
        const s = result ? result.toString() : '';
        if (!s || s.trim().length === 0) {
            await gateway.disconnect();
            return res.status(404).json({ error: 'Balance not found or empty response from chaincode' });
        }
        const balance = parseFloat(s);

        await gateway.disconnect();

        res.json({ success: true, data: { factoryId, balance } });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get available energy of a factory
 * GET /api/factory/:factoryId/available-energy
 */
app.get('/api/factory/:factoryId/available-energy', async (req, res) => {
    try {
        const { factoryId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query available energy
        const result = await contract.evaluateTransaction('GetAvailableEnergy', factoryId);
        const s = result ? result.toString() : '';
        if (!s || s.trim().length === 0) {
            await gateway.disconnect();
            return res.status(404).json({ error: 'Available energy not found or empty response from chaincode' });
        }
        const availableEnergy = parseFloat(s);

        await gateway.disconnect();

        res.json({ success: true, data: { factoryId, availableEnergy } });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get energy status (surplus/deficit) of a factory
 * GET /api/factory/:factoryId/energy-status
 */
app.get('/api/factory/:factoryId/energy-status', async (req, res) => {
    try {
        const { factoryId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query energy status
        const result = await contract.evaluateTransaction('GetEnergyStatus', factoryId);
        const status = parseResult(result, null);

        await gateway.disconnect();

        if (status === null) {
            res.status(404).json({ error: 'Energy status not found or empty response from chaincode' });
        } else {
            res.json({ success: true, data: status });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Update available energy of a factory
 * PUT /api/factory/:factoryId/available-energy
 * Body: { availableEnergy }
 */
app.put('/api/factory/:factoryId/available-energy', async (req, res) => {
    try {
        const { factoryId } = req.params;
        const { availableEnergy } = req.body;

        if (availableEnergy === undefined || availableEnergy < 0) {
            return res.status(400).json({ error: 'Invalid availableEnergy value' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction
        await contract.submitTransaction('UpdateAvailableEnergy', factoryId, availableEnergy.toString());

        await gateway.disconnect();

        res.json({
            success: true,
            message: `Available energy updated for ${factoryId}`,
            data: { factoryId, availableEnergy }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Update daily consumption of a factory
 * PUT /api/factory/:factoryId/daily-consumption
 * Body: { dailyConsumption }
 */
app.put('/api/factory/:factoryId/daily-consumption', async (req, res) => {
    try {
        const { factoryId } = req.params;
        const { dailyConsumption } = req.body;

        if (dailyConsumption === undefined || dailyConsumption < 0) {
            return res.status(400).json({ error: 'Invalid dailyConsumption value' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Submit transaction
        await contract.submitTransaction('UpdateDailyConsumption', factoryId, dailyConsumption.toString());

        await gateway.disconnect();

        res.json({
            success: true,
            message: `Daily consumption updated for ${factoryId}`,
            data: { factoryId, dailyConsumption }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get all factories in the industrial zone
 * GET /api/factories
 */
app.get('/api/factories', async (req, res) => {
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Query all factories
        const result = await contract.evaluateTransaction('GetAllFactories');
        const factories = parseResult(result, []);

        await gateway.disconnect();

        res.json({ 
            success: true, 
            count: Array.isArray(factories) ? factories.length : 0,
            data: factories 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get trade information
 * GET /api/trade/:tradeId
 */
app.get('/api/trade/:tradeId', async (req, res) => {
    try {
        const { tradeId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query trade data
        const result = await contract.evaluateTransaction('GetTrade', tradeId);
        const trade = parseResult(result, null);

        await gateway.disconnect();

        if (trade === null) {
            res.status(404).json({ error: 'Trade not found or empty response from chaincode' });
        } else {
            res.json({ success: true, data: trade });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get factory transaction history
 * GET /api/factory/:factoryId/history
 */
app.get('/api/factory/:factoryId/history', async (req, res) => {
    try {
        const { factoryId } = req.params;

        // Connect to network
        const { contract, gateway } = await getContract();

        // Query history
        const result = await contract.evaluateTransaction('GetFactoryHistory', factoryId);
        const history = parseResult(result, []);

        await gateway.disconnect();

        res.json({ success: true, data: history });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server (capture server to handle errors)
const server = app.listen(PORT, () => {
    console.log('========================================');
    console.log('   Energy Trading Network API');
    console.log('========================================');
    console.log(`Server running on http://localhost:${PORT}`);
    console.log('');
    console.log('Available endpoints:');
    console.log('  GET  /api/health');
    console.log('  POST /api/factory/register');
    console.log('  POST /api/energy/mint');
    console.log('  POST /api/energy/transfer');
    console.log('  POST /api/trade/create');
    console.log('  POST /api/trade/execute');
    console.log('  GET  /api/factory/:factoryId');
    console.log('  GET  /api/factory/:factoryId/balance');
    console.log('  GET  /api/factory/:factoryId/available-energy');
    console.log('  GET  /api/factory/:factoryId/energy-status');
    console.log('  PUT  /api/factory/:factoryId/available-energy');
    console.log('  PUT  /api/factory/:factoryId/daily-consumption');
    console.log('  GET  /api/factories');
    console.log('  GET  /api/trade/:tradeId');
    console.log('  GET  /api/factory/:factoryId/history');
    console.log('========================================');
});
server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} already in use. Start the app with a different PORT or stop the process using this port.`);
        process.exit(1);
    }
    console.error('Server error:', err);
    process.exit(1);
});
