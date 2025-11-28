/**
 * Energy Trading Application
 * Unified application for factories to interact with the blockchain
 * Provides REST API endpoints for energy token operations and mobile app authentication
 * 
 * This application uses CouchDB (via Hyperledger Fabric) as the only database.
 * No MySQL is required - all data is stored on the blockchain ledger (couchdb0 and couchdb1).
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Initialize Express application
const app = express();

// CORS configuration - must be before other middleware
app.use((req, res, next) => {
    console.log(`Incoming request: ${req.method} ${req.url} from ${req.headers.origin || 'unknown origin'}`);
    
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        console.log('Handling OPTIONS preflight request');
        return res.sendStatus(200);
    }
    next();
});

app.use(express.json());

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
 * Generate a unique factory ID
 */
function generateFactoryId() {
    return 'Factory_' + Date.now() + '_' + Math.random().toString(36).substring(2, 9);
}

/**
 * Generate a unique offer ID
 */
function generateOfferId() {
    return 'Offer_' + Date.now() + '_' + Math.random().toString(36).substring(2, 9);
}

/**
 * Generate a unique trade ID
 */
function generateTradeId() {
    return 'Trade_' + Date.now() + '_' + Math.random().toString(36).substring(2, 9);
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

// ==================== HEALTH CHECK ====================

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Energy Trading API is running (CouchDB only - no MySQL)',
        database: 'CouchDB via Hyperledger Fabric (couchdb0, couchdb1)',
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

// ==================== MOBILE APP AUTHENTICATION ENDPOINTS ====================

// Simple test endpoint (for mobile app compatibility)
app.get('/test', (req, res) => {
    console.log('Test endpoint hit!');
    res.json({ message: 'Backend is working! (CouchDB only - no MySQL)' });
});

/**
 * Login Endpoint - Authenticate factory user
 * POST /login
 * Body: { email, password }
 */
app.post('/login', async (req, res) => {
    console.log('Received login request with email:', req.body.email);
    try {
        const { email, password } = req.body;

        // Basic validation
        if (!email || !password) {
            console.log('Login failed: Email or password missing.');
            return res.status(400).send({ error: 'Email and password are required.' });
        }

        // Connect to network
        const { contract, gateway } = await getContract();

        // Get factory by email from CouchDB via chaincode
        let factory;
        try {
            const result = await contract.evaluateTransaction('GetFactoryByEmail', email);
            factory = parseResult(result, null);
        } catch (err) {
            await gateway.disconnect();
            console.log('Login failed: Email not found.');
            return res.status(401).send({ error: 'Invalid email or password.' });
        }

        await gateway.disconnect();

        if (!factory) {
            console.log('Login failed: Email not found.');
            return res.status(401).send({ error: 'Invalid email or password.' });
        }

        // Compare password with hashed password
        const isPasswordValid = await bcrypt.compare(password, factory.passwordHash || '');

        if (!isPasswordValid) {
            console.log('Login failed: Invalid password.');
            return res.status(401).send({ error: 'Invalid email or password.' });
        }

        console.log('Login successful for:', email);
        res.status(200).send({ 
            message: 'Login successful!',
            factory: {
                id: factory.id,
                factory_name: factory.name,
                email: factory.email,
                localisation: factory.localisation,
                fiscal_matricule: factory.fiscalMatricule,
                energy_capacity: factory.energyCapacity,
                contact_info: factory.contactInfo,
                energy_source: factory.energyType,
                energy_balance: factory.energyBalance || 0,
                current_generation: factory.currentGeneration || 0,
                current_consumption: factory.currentConsumption || 0
            }
        });

    } catch (error) {
        console.error('Error during login:', error);
        res.status(500).send({ error: 'Failed to login due to a server error.' });
    }
});

/**
 * Sign-Up Endpoint - Register new factory with authentication
 * POST /signup
 * Body: { factory_name, localisation, fiscal_matricule, energy_capacity, contact_info, energy_source, email, password }
 */
app.post('/signup', async (req, res) => {
    console.log('Received signup request with body:', req.body);
    try {
        const {
            factory_name,
            localisation,
            fiscal_matricule,
            energy_capacity,
            contact_info,
            energy_source,
            email,
            password
        } = req.body;

        // Basic validation
        if (!email || !password || !factory_name || !fiscal_matricule) {
            console.log('Signup failed: Required fields missing.');
            return res.status(400).send({ error: 'Required fields are missing.' });
        }

        // Password validation: minimum 8 characters, at least one letter and one number
        if (password.length < 8) {
            console.log('Signup failed: Password too short.');
            return res.status(400).send({ error: 'Password must be at least 8 characters long.' });
        }
        if (!/(?=.*[a-zA-Z])(?=.*[0-9])/.test(password)) {
            console.log('Signup failed: Password must contain letters and numbers.');
            return res.status(400).send({ error: 'Password must contain at least one letter and one number.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Generate unique factory ID
        const factoryId = generateFactoryId();

        // Connect to network
        const { contract, gateway } = await getContract();

        // Register factory with authentication via chaincode (stored in CouchDB)
        try {
            await contract.submitTransaction(
                'RegisterFactoryWithAuth',
                factoryId,
                factory_name,
                email,
                hashedPassword,
                localisation || '',
                fiscal_matricule,
                (energy_capacity || 0).toString(),
                contact_info || '',
                energy_source || '',
                '0', // initialBalance
                '0'  // currencyBalance
            );
        } catch (err) {
            await gateway.disconnect();
            if (err.message.includes('already registered') || err.message.includes('already exists')) {
                return res.status(409).send({ error: 'Email or Fiscal Matricule already exists.' });
            }
            throw err;
        }

        await gateway.disconnect();

        console.log('Factory registered successfully:', email);
        res.status(201).send({ 
            message: 'Factory registered successfully!',
            factoryId: factoryId
        });

    } catch (error) {
        console.error('Error during signup:', error);
        res.status(500).send({ error: 'Failed to register factory due to a server error.' });
    }
});

// ==================== MOBILE APP FACTORIES ENDPOINTS ====================

/**
 * Get all factories (mobile app format)
 * GET /factories
 */
app.get('/factories', async (req, res) => {
    console.log('Fetching all factories');
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Query all factories from CouchDB via chaincode
        const result = await contract.evaluateTransaction('GetAllFactories');
        const factories = parseResult(result, []);

        await gateway.disconnect();

        // Transform to mobile app format
        const transformedFactories = factories.map(f => ({
            id: f.id,
            factory_name: f.name,
            localisation: f.localisation,
            fiscal_matricule: f.fiscalMatricule,
            energy_capacity: f.energyCapacity,
            contact_info: f.contactInfo,
            energy_source: f.energyType,
            email: f.email,
            energy_balance: f.energyBalance,
            current_generation: f.currentGeneration,
            current_consumption: f.currentConsumption,
            created_at: f.createdAt
        }));
        
        res.status(200).json({ 
            success: true,
            data: transformedFactories 
        });
    } catch (error) {
        console.error('Error fetching factories:', error);
        res.status(500).json({ error: 'Failed to fetch factories.' });
    }
});

/**
 * Get a single factory by ID (mobile app format)
 * GET /factory/:id
 */
app.get('/factory/:id', async (req, res) => {
    const { id } = req.params;
    console.log('Fetching factory with ID:', id);
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Query factory from CouchDB via chaincode
        let factory;
        try {
            const result = await contract.evaluateTransaction('GetFactory', id);
            factory = parseResult(result, null);
        } catch (err) {
            await gateway.disconnect();
            return res.status(404).json({ error: 'Factory not found.' });
        }

        await gateway.disconnect();

        if (!factory) {
            return res.status(404).json({ error: 'Factory not found.' });
        }

        // Transform to mobile app format
        res.status(200).json({ 
            success: true,
            data: {
                id: factory.id,
                factory_name: factory.name,
                localisation: factory.localisation,
                fiscal_matricule: factory.fiscalMatricule,
                energy_capacity: factory.energyCapacity,
                contact_info: factory.contactInfo,
                energy_source: factory.energyType,
                email: factory.email,
                energy_balance: factory.energyBalance,
                current_generation: factory.currentGeneration,
                current_consumption: factory.currentConsumption,
                created_at: factory.createdAt
            }
        });
    } catch (error) {
        console.error('Error fetching factory:', error);
        res.status(500).json({ error: 'Failed to fetch factory.' });
    }
});

/**
 * Update factory energy data (mobile app format)
 * PUT /factory/:id/energy
 * Body: { energy_balance, current_generation, current_consumption }
 */
app.put('/factory/:id/energy', async (req, res) => {
    const { id } = req.params;
    const { energy_balance, current_generation, current_consumption } = req.body;
    
    console.log('Updating energy data for factory:', id);
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Update factory energy via chaincode (stored in CouchDB)
        await contract.submitTransaction(
            'UpdateFactoryEnergy',
            id,
            (energy_balance || 0).toString(),
            (current_generation || 0).toString(),
            (current_consumption || 0).toString()
        );

        await gateway.disconnect();
        
        res.status(200).json({ 
            success: true,
            message: 'Factory energy data updated successfully.' 
        });
    } catch (error) {
        console.error('Error updating factory energy:', error);
        res.status(500).json({ error: 'Failed to update factory energy data.' });
    }
});

// ==================== MOBILE APP OFFERS ENDPOINTS ====================

/**
 * Get all offers (mobile app format)
 * GET /offers
 */
app.get('/offers', async (req, res) => {
    console.log('Fetching all offers');
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Query all offers from CouchDB via chaincode
        const offersResult = await contract.evaluateTransaction('GetAllOffers');
        const offers = parseResult(offersResult, []);

        // Get all factories to join data
        const factoriesResult = await contract.evaluateTransaction('GetAllFactories');
        const factories = parseResult(factoriesResult, []);
        const factoryMap = {};
        factories.forEach(f => { factoryMap[f.id] = f; });

        await gateway.disconnect();

        // Transform to mobile app format with factory details
        const transformedOffers = offers.map(o => {
            const factory = factoryMap[o.factoryId] || {};
            return {
                id: o.id,
                factory_id: o.factoryId,
                offer_type: o.offerType,
                energy_amount: o.energyAmount,
                price_per_kwh: o.pricePerKwh,
                status: o.status,
                created_at: o.createdAt,
                updated_at: o.updatedAt,
                factory_name: factory.name,
                energy_source: factory.energyType,
                localisation: factory.localisation
            };
        });
        
        res.status(200).json({ 
            success: true,
            data: transformedOffers 
        });
    } catch (error) {
        console.error('Error fetching offers:', error);
        res.status(500).json({ error: 'Failed to fetch offers.' });
    }
});

/**
 * Create a new offer (mobile app format)
 * POST /offers
 * Body: { factory_id, offer_type, energy_amount, price_per_kwh }
 */
app.post('/offers', async (req, res) => {
    console.log('Creating new offer:', req.body);
    try {
        const { factory_id, offer_type, energy_amount, price_per_kwh } = req.body;

        if (!factory_id || !offer_type || !energy_amount || !price_per_kwh) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        // Generate unique offer ID
        const offerId = generateOfferId();

        // Connect to network
        const { contract, gateway } = await getContract();

        // Create offer via chaincode (stored in CouchDB)
        await contract.submitTransaction(
            'CreateOffer',
            offerId,
            factory_id,
            offer_type,
            energy_amount.toString(),
            price_per_kwh.toString()
        );

        await gateway.disconnect();
        
        res.status(201).json({ 
            success: true,
            message: 'Offer created successfully.',
            offerId: offerId
        });
    } catch (error) {
        console.error('Error creating offer:', error);
        res.status(500).json({ error: 'Failed to create offer.' });
    }
});

/**
 * Update offer status (mobile app format)
 * PUT /offers/:id
 * Body: { status }
 */
app.put('/offers/:id', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    
    console.log('Updating offer status:', id, status);
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Update offer status via chaincode (stored in CouchDB)
        await contract.submitTransaction('UpdateOfferStatus', id, status);

        await gateway.disconnect();
        
        res.status(200).json({ 
            success: true,
            message: 'Offer updated successfully.' 
        });
    } catch (error) {
        console.error('Error updating offer:', error);
        res.status(500).json({ error: 'Failed to update offer.' });
    }
});

// ==================== MOBILE APP TRADES ENDPOINTS ====================

/**
 * Get all trades (mobile app format)
 * GET /trades
 */
app.get('/trades', async (req, res) => {
    const { factory_id } = req.query;
    console.log('Fetching trades, factory_id:', factory_id);
    
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Query all trades from CouchDB via chaincode
        const tradesResult = await contract.evaluateTransaction('GetAllTrades');
        let trades = parseResult(tradesResult, []);

        // Get all factories to join data
        const factoriesResult = await contract.evaluateTransaction('GetAllFactories');
        const factories = parseResult(factoriesResult, []);
        const factoryMap = {};
        factories.forEach(f => { factoryMap[f.id] = f; });

        await gateway.disconnect();

        // Filter by factory_id if provided
        if (factory_id) {
            trades = trades.filter(t => t.sellerId === factory_id || t.buyerId === factory_id);
        }

        // Transform to mobile app format with factory names
        const transformedTrades = trades.map(t => {
            const seller = factoryMap[t.sellerId] || {};
            const buyer = factoryMap[t.buyerId] || {};
            return {
                id: t.tradeId,
                seller_factory_id: t.sellerId,
                buyer_factory_id: t.buyerId,
                energy_amount: t.amount,
                price_per_kwh: t.pricePerUnit,
                total_price: t.totalPrice,
                status: t.status,
                created_at: t.timestamp,
                completed_at: t.status === 'completed' ? t.timestamp : null,
                seller_name: seller.name,
                buyer_name: buyer.name
            };
        });
        
        res.status(200).json({ 
            success: true,
            data: transformedTrades 
        });
    } catch (error) {
        console.error('Error fetching trades:', error);
        res.status(500).json({ error: 'Failed to fetch trades.' });
    }
});

/**
 * Create a new trade (mobile app format)
 * POST /trades
 * Body: { seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh }
 */
app.post('/trades', async (req, res) => {
    console.log('Creating new trade:', req.body);
    try {
        const { seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh } = req.body;

        if (!seller_factory_id || !buyer_factory_id || !energy_amount || !price_per_kwh) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        // Generate unique trade ID
        const tradeId = generateTradeId();

        // Connect to network
        const { contract, gateway } = await getContract();

        // Create trade via chaincode (stored in CouchDB)
        await contract.submitTransaction(
            'CreateEnergyTrade',
            tradeId,
            seller_factory_id,
            buyer_factory_id,
            energy_amount.toString(),
            price_per_kwh.toString()
        );

        await gateway.disconnect();
        
        res.status(201).json({ 
            success: true,
            message: 'Trade created successfully.',
            tradeId: tradeId 
        });
    } catch (error) {
        console.error('Error creating trade:', error);
        res.status(500).json({ error: 'Failed to create trade.' });
    }
});

/**
 * Execute/complete a trade (mobile app format)
 * POST /trades/:id/execute
 */
app.post('/trades/:id/execute', async (req, res) => {
    const { id } = req.params;
    console.log('Executing trade:', id);
    
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Execute trade via chaincode (updates CouchDB)
        await contract.submitTransaction('ExecuteTrade', id);

        await gateway.disconnect();
        
        res.status(200).json({ 
            success: true,
            message: 'Trade executed successfully.' 
        });
    } catch (error) {
        console.error('Error executing trade:', error);
        res.status(500).json({ error: 'Failed to execute trade.' });
    }
});

// ==================== SEED ENDPOINT ====================

/**
 * Seed the database with sample data (for testing)
 * POST /seed
 */
app.post('/seed', async (req, res) => {
    console.log('Seeding database with sample data (CouchDB via blockchain)...');
    
    try {
        // Connect to network
        const { contract, gateway } = await getContract();

        // Initialize ledger with sample factories via chaincode
        await contract.submitTransaction('InitLedger');

        await gateway.disconnect();

        res.status(200).json({ 
            success: true,
            message: 'Database seeded successfully via blockchain (CouchDB)!'
        });

    } catch (error) {
        console.error('Error seeding database:', error);
        res.status(500).json({ error: 'Failed to seed database.' });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server (capture server to handle errors)
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('========================================');
    console.log('   Energy Trading Network API');
    console.log('   (Unified Mobile + Blockchain)');
    console.log('========================================');
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Also accessible at http://127.0.0.1:${PORT}`);
    console.log('');
    console.log('Database: CouchDB via Hyperledger Fabric');
    console.log('         (couchdb0 and couchdb1 only - no MySQL)');
    console.log('');
    console.log('Available endpoints:');
    console.log('');
    console.log('  HEALTH:');
    console.log('  GET  /api/health');
    console.log('  GET  /test');
    console.log('');
    console.log('  AUTHENTICATION (Mobile App):');
    console.log('  POST /login');
    console.log('  POST /signup');
    console.log('');
    console.log('  FACTORIES (Mobile App format):');
    console.log('  GET  /factories');
    console.log('  GET  /factory/:id');
    console.log('  PUT  /factory/:id/energy');
    console.log('');
    console.log('  FACTORIES (Blockchain format):');
    console.log('  POST /api/factory/register');
    console.log('  GET  /api/factory/:factoryId');
    console.log('  GET  /api/factory/:factoryId/balance');
    console.log('  GET  /api/factory/:factoryId/available-energy');
    console.log('  GET  /api/factory/:factoryId/energy-status');
    console.log('  PUT  /api/factory/:factoryId/available-energy');
    console.log('  PUT  /api/factory/:factoryId/daily-consumption');
    console.log('  GET  /api/factories');
    console.log('  GET  /api/factory/:factoryId/history');
    console.log('');
    console.log('  ENERGY TOKENS:');
    console.log('  POST /api/energy/mint');
    console.log('  POST /api/energy/transfer');
    console.log('');
    console.log('  OFFERS (Mobile App):');
    console.log('  GET  /offers');
    console.log('  POST /offers');
    console.log('  PUT  /offers/:id');
    console.log('');
    console.log('  TRADES (Mobile App format):');
    console.log('  GET  /trades');
    console.log('  POST /trades');
    console.log('  POST /trades/:id/execute');
    console.log('');
    console.log('  TRADES (Blockchain format):');
    console.log('  POST /api/trade/create');
    console.log('  POST /api/trade/execute');
    console.log('  GET  /api/trade/:tradeId');
    console.log('');
    console.log('  SEED:');
    console.log('  POST /seed');
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
