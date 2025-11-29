/**
 * Energy Trading Application
 * Unified application for factories to trade energy
 * Provides REST API endpoints for energy trading operations and mobile app authentication
 * 
 * DATABASE ARCHITECTURE:
 * - PostgreSQL: Primary data store for all factory and trading data
 *   (credentials, profiles, trading data, energy balances, trades, offers)
 * - Blockchain: Optional/simulated for backward compatibility
 *   (All blockchain operations are faked and stored in PostgreSQL)
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Try to load fabric-network, but make it optional
let Gateway, Wallets;
try {
    const fabricNetwork = require('fabric-network');
    Gateway = fabricNetwork.Gateway;
    Wallets = fabricNetwork.Wallets;
} catch (e) {
    // fabric-network module not installed - running in PostgreSQL-only mode
    console.log('⚠️  fabric-network not available, running in PostgreSQL-only mode');
}

// Default initial values for new factories
const DEFAULT_ENERGY_BALANCE = 1000;
const DEFAULT_CURRENCY_BALANCE = 500;
const DEFAULT_ENERGY_TYPE = 'solar';

// Simple in-memory rate limiter for authentication endpoints
const rateLimitStore = new Map();
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const MAX_LOGIN_ATTEMPTS = 5; // Max attempts per window
const MAX_SIGNUP_ATTEMPTS = 3; // Max signup attempts per window
const RATE_LIMIT_CLEANUP_THRESHOLD = 10000; // Cleanup when exceeding this many entries

/**
 * Rate limiter middleware for authentication endpoints
 * @param {number} maxAttempts - Maximum attempts allowed in the window
 * @returns {Function} Express middleware function
 */
function rateLimiter(maxAttempts) {
    return (req, res, next) => {
        const clientIp = req.ip || req.headers['x-forwarded-for'] || 'unknown';
        const key = `${req.path}:${clientIp}`;
        const now = Date.now();
        
        // Get or create rate limit entry
        let entry = rateLimitStore.get(key);
        if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
            entry = { count: 0, windowStart: now };
        }
        
        entry.count++;
        rateLimitStore.set(key, entry);
        
        // Clean up old entries periodically when threshold exceeded
        if (rateLimitStore.size > RATE_LIMIT_CLEANUP_THRESHOLD) {
            for (const [k, v] of rateLimitStore) {
                if (now - v.windowStart > RATE_LIMIT_WINDOW_MS) {
                    rateLimitStore.delete(k);
                }
            }
        }
        
        if (entry.count > maxAttempts) {
            const retryAfter = Math.ceil((entry.windowStart + RATE_LIMIT_WINDOW_MS - now) / 1000);
            res.setHeader('Retry-After', retryAfter);
            return res.status(429).json({ 
                error: 'Too many attempts. Please try again later.',
                retryAfter: retryAfter
            });
        }
        
        next();
    };
}

// Rate limiter instances for authentication
const loginRateLimiter = rateLimiter(MAX_LOGIN_ATTEMPTS);
const signupRateLimiter = rateLimiter(MAX_SIGNUP_ATTEMPTS);

// PostgreSQL connection pool - PRIMARY data store
const pgPool = new Pool({
    host: process.env.PG_HOST || 'localhost',
    port: parseInt(process.env.PG_PORT) || 5432,
    user: process.env.PG_USER || 'energy_admin',
    password: process.env.PG_PASSWORD || 'energy_secure_password',
    database: process.env.PG_DATABASE || 'energy_credentials',
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// PostgreSQL connection status - initialized as a promise for proper synchronization
let pgConnected = false;
let pgConnectionPromise = pgPool.connect()
    .then(client => {
        console.log('✅ PostgreSQL connected successfully');
        pgConnected = true;
        client.release();
        return true;
    })
    .catch(err => {
        console.log('⚠️  PostgreSQL not available');
        console.log('   To enable PostgreSQL: npm run db:start');
        pgConnected = false;
        return false;
    });

// Cache for PostgreSQL connection status
let pgStatusCache = { status: null, timestamp: 0 };
const PG_STATUS_CACHE_TTL = 30000; // 30 seconds cache

/**
 * Check if PostgreSQL is available (with caching and proper synchronization)
 * @returns {Promise<boolean>}
 */
async function isPgConnected() {
    // Wait for initial connection check to complete
    await pgConnectionPromise;
    
    const now = Date.now();
    
    // Return cached status if still valid
    if (pgStatusCache.status !== null && now - pgStatusCache.timestamp < PG_STATUS_CACHE_TTL) {
        return pgStatusCache.status;
    }
    
    // If already connected, verify connection is still alive
    if (pgConnected) {
        try {
            const client = await pgPool.connect();
            client.release();
            pgStatusCache = { status: true, timestamp: now };
            return true;
        } catch (err) {
            pgConnected = false;
            pgStatusCache = { status: false, timestamp: now };
            return false;
        }
    }
    
    pgStatusCache = { status: false, timestamp: now };
    return false;
}

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
const USE_BLOCKCHAIN = process.env.USE_BLOCKCHAIN === 'true'; // Default: false (use PostgreSQL only)

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
    return 'Factory_' + Date.now() + '_' + crypto.randomBytes(4).toString('hex');
}

/**
 * Generate a unique offer ID
 */
function generateOfferId() {
    return 'Offer_' + Date.now() + '_' + crypto.randomBytes(4).toString('hex');
}

/**
 * Generate a unique trade ID
 */
function generateTradeId() {
    return 'Trade_' + Date.now() + '_' + crypto.randomBytes(4).toString('hex');
}

/**
 * Generate a simulated blockchain transaction hash for backward compatibility
 * Note: These are not real blockchain transactions, just identifiers for audit/debugging
 */
function generateFakeBlockchainHash() {
    return '0x' + crypto.randomBytes(32).toString('hex');
}

/**
 * Get network connection and contract (only if blockchain is enabled)
 * @param {string} factoryId - Factory identifier for wallet lookup
 * @returns {Object} Contract instance or null if blockchain disabled
 */
async function getContract(factoryId = 'admin') {
    // If blockchain is disabled or fabric-network not available, return null
    if (!USE_BLOCKCHAIN || !Gateway || !Wallets) {
        return null;
    }
    
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
        console.log('Blockchain not available, using PostgreSQL only');
        return null;
    }
}

// ==================== HEALTH CHECK ====================

// Health check endpoint
app.get('/api/health', async (req, res) => {
    const pgStatus = await isPgConnected();
    res.json({ 
        status: 'OK', 
        message: 'Energy Trading API is running',
        mode: USE_BLOCKCHAIN ? 'hybrid' : 'postgresql-only',
        databases: {
            postgresql: {
                status: pgStatus ? 'connected' : 'not available',
                purpose: 'Primary data store (credentials, profiles, trading data, trades, offers)'
            },
            blockchain: {
                status: USE_BLOCKCHAIN ? 'enabled' : 'simulated',
                type: USE_BLOCKCHAIN ? 'CouchDB via Hyperledger Fabric' : 'Simulated (PostgreSQL backend)',
                purpose: 'Trading data (blockchain operations are simulated in PostgreSQL)'
            }
        },
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

        const pgAvailable = await isPgConnected();
        
        // Store trading data in PostgreSQL
        if (pgAvailable) {
            // Check if factory exists
            const existCheck = await pgPool.query(
                'SELECT factory_id FROM factory_trading_data WHERE factory_id = $1',
                [factoryId]
            );
            
            if (existCheck.rows.length > 0) {
                // Update existing trading data
                await pgPool.query(`
                    UPDATE factory_trading_data SET
                        energy_balance = $2,
                        currency_balance = $3,
                        daily_consumption = $4,
                        available_energy = $5,
                        energy_type = $6,
                        updated_at = NOW()
                    WHERE factory_id = $1
                `, [factoryId, initBalNum, currencyBalNum, dailyConsNum, availableNum, energyType]);
            } else {
                // First ensure factory exists in credentials
                const credCheck = await pgPool.query(
                    'SELECT factory_id FROM factories_credentials WHERE factory_id = $1',
                    [factoryId]
                );
                
                if (credCheck.rows.length === 0) {
                    return res.status(400).json({ error: 'Factory credentials not found. Please signup first.' });
                }
                
                // Insert new trading data
                await pgPool.query(`
                    INSERT INTO factory_trading_data 
                    (factory_id, energy_balance, currency_balance, daily_consumption, available_energy, energy_type)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `, [factoryId, initBalNum, currencyBalNum, dailyConsNum, availableNum, energyType]);
            }
        }

        // Optionally replicate to blockchain if enabled
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
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
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

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
            },
            blockchainTxHash: generateFakeBlockchainHash()
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            // Update energy balance in PostgreSQL
            await pgPool.query(`
                UPDATE factory_trading_data 
                SET energy_balance = energy_balance + $2,
                    available_energy = available_energy + $2,
                    updated_at = NOW()
                WHERE factory_id = $1
            `, [factoryId, amount]);
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('MintEnergyTokens', factoryId, amount.toString());
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

        res.json({ 
            success: true, 
            message: `Minted ${amount} kWh of energy tokens for ${factoryId}`,
            data: { factoryId, amount },
            blockchainTxHash: generateFakeBlockchainHash()
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const pgClient = await pgPool.connect();
            try {
                await pgClient.query('BEGIN');
                
                // Check if sender has enough energy
                const senderResult = await pgClient.query(
                    'SELECT energy_balance FROM factory_trading_data WHERE factory_id = $1',
                    [fromFactoryId]
                );
                
                if (senderResult.rows.length === 0) {
                    throw new Error('Sender factory not found');
                }
                
                const senderBalance = parseFloat(senderResult.rows[0].energy_balance);
                if (senderBalance < amount) {
                    throw new Error('Insufficient energy balance');
                }
                
                // Deduct from sender
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance - $2,
                        available_energy = available_energy - $2,
                        updated_at = NOW()
                    WHERE factory_id = $1
                `, [fromFactoryId, amount]);
                
                // Add to receiver
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance + $2,
                        available_energy = available_energy + $2,
                        updated_at = NOW()
                    WHERE factory_id = $1
                `, [toFactoryId, amount]);
                
                await pgClient.query('COMMIT');
            } catch (e) {
                await pgClient.query('ROLLBACK');
                throw e;
            } finally {
                pgClient.release();
            }
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('TransferEnergy', fromFactoryId, toFactoryId, amount.toString());
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

        res.json({ 
            success: true, 
            message: `Transferred ${amount} kWh from ${fromFactoryId} to ${toFactoryId}`,
            data: { fromFactoryId, toFactoryId, amount },
            blockchainTxHash: generateFakeBlockchainHash()
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
        let { tradeId, sellerId, buyerId, amount, pricePerUnit } = req.body;

        // Validate input
        if (!sellerId || !buyerId || !amount || !pricePerUnit) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Generate trade ID if not provided
        if (!tradeId) {
            tradeId = generateTradeId();
        }

        const totalPrice = parseFloat(amount) * parseFloat(pricePerUnit);
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            // Insert trade into PostgreSQL
            await pgPool.query(`
                INSERT INTO trades (trade_id, seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, total_price, status, blockchain_tx_hash)
                VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7)
            `, [tradeId, sellerId, buyerId, amount, pricePerUnit, totalPrice, generateFakeBlockchainHash()]);
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('CreateEnergyTrade', tradeId, sellerId, buyerId, 
                    amount.toString(), pricePerUnit.toString());
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

        res.json({ 
            success: true, 
            message: `Trade ${tradeId} created successfully`,
            data: { tradeId, sellerId, buyerId, amount, pricePerUnit, totalPrice },
            blockchainTxHash: generateFakeBlockchainHash()
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const pgClient = await pgPool.connect();
            try {
                await pgClient.query('BEGIN');
                
                // Get trade details
                const tradeResult = await pgClient.query(
                    'SELECT * FROM trades WHERE trade_id = $1 AND status = $2',
                    [tradeId, 'pending']
                );
                
                if (tradeResult.rows.length === 0) {
                    throw new Error('Trade not found or already executed');
                }
                
                const trade = tradeResult.rows[0];
                const amount = parseFloat(trade.energy_amount);
                const totalPrice = parseFloat(trade.total_price);
                
                // Check seller has enough energy
                const sellerResult = await pgClient.query(
                    'SELECT energy_balance FROM factory_trading_data WHERE factory_id = $1',
                    [trade.seller_factory_id]
                );
                
                if (sellerResult.rows.length === 0 || parseFloat(sellerResult.rows[0].energy_balance) < amount) {
                    throw new Error('Seller has insufficient energy balance');
                }
                
                // Check buyer has enough currency
                const buyerResult = await pgClient.query(
                    'SELECT currency_balance FROM factory_trading_data WHERE factory_id = $1',
                    [trade.buyer_factory_id]
                );
                
                if (buyerResult.rows.length === 0 || parseFloat(buyerResult.rows[0].currency_balance) < totalPrice) {
                    throw new Error('Buyer has insufficient currency balance');
                }
                
                // Transfer energy from seller to buyer
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance - $2, available_energy = available_energy - $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.seller_factory_id, amount]);
                
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance + $2, available_energy = available_energy + $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.buyer_factory_id, amount]);
                
                // Transfer currency from buyer to seller
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET currency_balance = currency_balance - $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.buyer_factory_id, totalPrice]);
                
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET currency_balance = currency_balance + $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.seller_factory_id, totalPrice]);
                
                // Update trade status to completed
                await pgClient.query(`
                    UPDATE trades 
                    SET status = 'completed', completed_at = NOW(), updated_at = NOW()
                    WHERE trade_id = $1
                `, [tradeId]);
                
                await pgClient.query('COMMIT');
            } catch (e) {
                await pgClient.query('ROLLBACK');
                throw e;
            } finally {
                pgClient.release();
            }
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('ExecuteTrade', tradeId);
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

        res.json({ 
            success: true, 
            message: `Trade ${tradeId} executed successfully`,
            data: { tradeId },
            blockchainTxHash: generateFakeBlockchainHash()
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            // Get factory data from PostgreSQL
            const result = await pgPool.query(`
                SELECT fc.factory_id, fc.email, fc.fiscal_matricule,
                       fp.factory_name, fp.localisation, fp.contact_info, fp.energy_capacity,
                       ftd.energy_balance, ftd.currency_balance, ftd.daily_consumption, 
                       ftd.available_energy, ftd.current_generation, ftd.current_consumption, ftd.energy_type,
                       fc.created_at
                FROM factories_credentials fc
                LEFT JOIN factory_profiles fp ON fc.factory_id = fp.factory_id
                LEFT JOIN factory_trading_data ftd ON fc.factory_id = ftd.factory_id
                WHERE fc.factory_id = $1
            `, [factoryId]);
            
            if (result.rows.length > 0) {
                const row = result.rows[0];
                const factory = {
                    id: row.factory_id,
                    name: row.factory_name,
                    email: row.email,
                    localisation: row.localisation,
                    fiscalMatricule: row.fiscal_matricule,
                    energyCapacity: row.energy_capacity,
                    contactInfo: row.contact_info,
                    energyBalance: parseFloat(row.energy_balance) || 0,
                    currencyBalance: parseFloat(row.currency_balance) || 0,
                    dailyConsumption: parseFloat(row.daily_consumption) || 0,
                    availableEnergy: parseFloat(row.available_energy) || 0,
                    currentGeneration: parseFloat(row.current_generation) || 0,
                    currentConsumption: parseFloat(row.current_consumption) || 0,
                    energyType: row.energy_type,
                    createdAt: row.created_at
                };
                return res.json({ success: true, data: factory });
            }
        }

        // Fallback to blockchain if enabled
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetFactory', factoryId);
            const factory = parseResult(result, null);
            await gateway.disconnect();

            if (factory !== null) {
                return res.json({ success: true, data: factory });
            }
        }
        
        res.status(404).json({ error: 'Factory not found' });
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(
                'SELECT energy_balance FROM factory_trading_data WHERE factory_id = $1',
                [factoryId]
            );
            
            if (result.rows.length > 0) {
                const balance = parseFloat(result.rows[0].energy_balance);
                return res.json({ success: true, data: { factoryId, balance } });
            }
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetEnergyBalance', factoryId);
            const s = result ? result.toString() : '';
            await gateway.disconnect();
            
            if (s && s.trim().length > 0) {
                const balance = parseFloat(s);
                return res.json({ success: true, data: { factoryId, balance } });
            }
        }
        
        res.status(404).json({ error: 'Balance not found' });
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(
                'SELECT available_energy FROM factory_trading_data WHERE factory_id = $1',
                [factoryId]
            );
            
            if (result.rows.length > 0) {
                const availableEnergy = parseFloat(result.rows[0].available_energy);
                return res.json({ success: true, data: { factoryId, availableEnergy } });
            }
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetAvailableEnergy', factoryId);
            const s = result ? result.toString() : '';
            await gateway.disconnect();
            
            if (s && s.trim().length > 0) {
                const availableEnergy = parseFloat(s);
                return res.json({ success: true, data: { factoryId, availableEnergy } });
            }
        }
        
        res.status(404).json({ error: 'Available energy not found' });
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(
                'SELECT available_energy, daily_consumption FROM factory_trading_data WHERE factory_id = $1',
                [factoryId]
            );
            
            if (result.rows.length > 0) {
                const availableEnergy = parseFloat(result.rows[0].available_energy) || 0;
                const dailyConsumption = parseFloat(result.rows[0].daily_consumption) || 0;
                const difference = availableEnergy - dailyConsumption;
                
                const status = {
                    factoryId,
                    availableEnergy,
                    dailyConsumption,
                    difference,
                    status: difference > 0 ? 'surplus' : (difference < 0 ? 'deficit' : 'balanced')
                };
                return res.json({ success: true, data: status });
            }
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetEnergyStatus', factoryId);
            const status = parseResult(result, null);
            await gateway.disconnect();

            if (status !== null) {
                return res.json({ success: true, data: status });
            }
        }
        
        res.status(404).json({ error: 'Energy status not found' });
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            await pgPool.query(`
                UPDATE factory_trading_data 
                SET available_energy = $2, updated_at = NOW()
                WHERE factory_id = $1
            `, [factoryId, availableEnergy]);
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('UpdateAvailableEnergy', factoryId, availableEnergy.toString());
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            await pgPool.query(`
                UPDATE factory_trading_data 
                SET daily_consumption = $2, updated_at = NOW()
                WHERE factory_id = $1
            `, [factoryId, dailyConsumption]);
        }

        // Optionally replicate to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            try {
                const { contract, gateway } = blockchainResult;
                await contract.submitTransaction('UpdateDailyConsumption', factoryId, dailyConsumption.toString());
                await gateway.disconnect();
            } catch (e) {
                console.log('Blockchain replication skipped:', e.message);
            }
        }

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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(`
                SELECT fc.factory_id, fc.email, fc.fiscal_matricule,
                       fp.factory_name, fp.localisation, fp.contact_info, fp.energy_capacity,
                       ftd.energy_balance, ftd.currency_balance, ftd.daily_consumption, 
                       ftd.available_energy, ftd.current_generation, ftd.current_consumption, ftd.energy_type,
                       fc.created_at
                FROM factories_credentials fc
                LEFT JOIN factory_profiles fp ON fc.factory_id = fp.factory_id
                LEFT JOIN factory_trading_data ftd ON fc.factory_id = ftd.factory_id
                WHERE fc.is_active = true
                ORDER BY fc.created_at DESC
            `);
            
            const factories = result.rows.map(row => ({
                id: row.factory_id,
                name: row.factory_name,
                email: row.email,
                localisation: row.localisation,
                fiscalMatricule: row.fiscal_matricule,
                energyCapacity: row.energy_capacity,
                contactInfo: row.contact_info,
                energyBalance: parseFloat(row.energy_balance) || 0,
                currencyBalance: parseFloat(row.currency_balance) || 0,
                dailyConsumption: parseFloat(row.daily_consumption) || 0,
                availableEnergy: parseFloat(row.available_energy) || 0,
                currentGeneration: parseFloat(row.current_generation) || 0,
                currentConsumption: parseFloat(row.current_consumption) || 0,
                energyType: row.energy_type,
                createdAt: row.created_at
            }));
            
            return res.json({ 
                success: true, 
                count: factories.length,
                data: factories 
            });
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetAllFactories');
            const factories = parseResult(result, []);
            await gateway.disconnect();

            return res.json({ 
                success: true, 
                count: Array.isArray(factories) ? factories.length : 0,
                data: factories 
            });
        }
        
        res.json({ success: true, count: 0, data: [] });
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(
                'SELECT * FROM trades WHERE trade_id = $1',
                [tradeId]
            );
            
            if (result.rows.length > 0) {
                const row = result.rows[0];
                const trade = {
                    tradeId: row.trade_id,
                    sellerId: row.seller_factory_id,
                    buyerId: row.buyer_factory_id,
                    amount: parseFloat(row.energy_amount),
                    pricePerUnit: parseFloat(row.price_per_kwh),
                    totalPrice: parseFloat(row.total_price),
                    status: row.status,
                    timestamp: row.created_at,
                    completedAt: row.completed_at,
                    blockchainTxHash: row.blockchain_tx_hash
                };
                return res.json({ success: true, data: trade });
            }
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetTrade', tradeId);
            const trade = parseResult(result, null);
            await gateway.disconnect();

            if (trade !== null) {
                return res.json({ success: true, data: trade });
            }
        }
        
        res.status(404).json({ error: 'Trade not found' });
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
        
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            // Get trades where factory is either buyer or seller
            const result = await pgPool.query(`
                SELECT t.*, 
                       seller_fp.factory_name as seller_name,
                       buyer_fp.factory_name as buyer_name
                FROM trades t
                LEFT JOIN factory_profiles seller_fp ON t.seller_factory_id = seller_fp.factory_id
                LEFT JOIN factory_profiles buyer_fp ON t.buyer_factory_id = buyer_fp.factory_id
                WHERE t.seller_factory_id = $1 OR t.buyer_factory_id = $1
                ORDER BY t.created_at DESC
                LIMIT 100
            `, [factoryId]);
            
            const history = result.rows.map(row => ({
                tradeId: row.trade_id,
                type: row.seller_factory_id === factoryId ? 'sell' : 'buy',
                counterparty: row.seller_factory_id === factoryId ? row.buyer_name : row.seller_name,
                amount: parseFloat(row.energy_amount),
                pricePerUnit: parseFloat(row.price_per_kwh),
                totalPrice: parseFloat(row.total_price),
                status: row.status,
                timestamp: row.created_at
            }));
            
            return res.json({ success: true, data: history });
        }

        // Fallback to blockchain
        const blockchainResult = await getContract();
        if (blockchainResult) {
            const { contract, gateway } = blockchainResult;
            const result = await contract.evaluateTransaction('GetFactoryHistory', factoryId);
            const history = parseResult(result, []);
            await gateway.disconnect();

            return res.json({ success: true, data: history });
        }
        
        res.json({ success: true, data: [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==================== MOBILE APP AUTHENTICATION ENDPOINTS ====================

// Simple test endpoint (for mobile app compatibility)
app.get('/test', async (req, res) => {
    console.log('Test endpoint hit!');
    const pgStatus = await isPgConnected();
    res.json({ 
        message: 'Backend is working!',
        mode: USE_BLOCKCHAIN ? 'hybrid' : 'postgresql-only',
        databases: {
            postgresql: pgStatus ? 'connected' : 'not available',
            blockchain: USE_BLOCKCHAIN ? 'CouchDB via Hyperledger Fabric' : 'Simulated (PostgreSQL backend)'
        }
    });
});

/**
 * Login Endpoint - Authenticate factory user
 * Uses PostgreSQL for credentials and trading data
 * Rate limited to prevent brute-force attacks
 * POST /login
 * Body: { email, password }
 */
app.post('/login', loginRateLimiter, async (req, res) => {
    console.log('Received login request with email:', req.body.email);
    try {
        const { email, password } = req.body;
        const clientIp = req.ip || req.headers['x-forwarded-for'] || 'unknown';
        const userAgent = req.headers['user-agent'] || 'unknown';

        // Basic validation
        if (!email || !password) {
            console.log('Login failed: Email or password missing.');
            return res.status(400).send({ error: 'Email and password are required.' });
        }

        // Try PostgreSQL for credentials
        const pgAvailable = await isPgConnected();
        if (pgAvailable) {
            try {
                // SQL query for fetching credentials with profile and trading data
                const credentialQuery = `
                    SELECT 
                        fc.factory_id, 
                        fc.password_hash, 
                        fc.email, 
                        fp.factory_name, 
                        fp.localisation, 
                        fc.fiscal_matricule, 
                        fp.energy_capacity, 
                        fp.contact_info,
                        ftd.energy_balance,
                        ftd.currency_balance,
                        ftd.current_generation,
                        ftd.current_consumption,
                        ftd.energy_type
                    FROM factories_credentials fc 
                    LEFT JOIN factory_profiles fp ON fc.factory_id = fp.factory_id 
                    LEFT JOIN factory_trading_data ftd ON fc.factory_id = ftd.factory_id
                    WHERE fc.email = $1 AND fc.is_active = true
                `;
                const credResult = await pgPool.query(credentialQuery, [email]);
                
                if (credResult.rows.length > 0) {
                    const cred = credResult.rows[0];
                    const factoryId = cred.factory_id;
                    const passwordHash = cred.password_hash;
                    
                    // Verify password
                    const isPasswordValid = await bcrypt.compare(password, passwordHash);
                    if (!isPasswordValid) {
                        // Log failed login attempt
                        await pgPool.query(
                            'INSERT INTO login_history (factory_id, ip_address, user_agent, success) VALUES ($1, $2, $3, false)',
                            [factoryId, clientIp, userAgent]
                        );
                        console.log('Login failed: Invalid password.');
                        return res.status(401).send({ error: 'Invalid email or password.' });
                    }

                    // Log successful login
                    await pgPool.query(
                        'INSERT INTO login_history (factory_id, ip_address, user_agent, success) VALUES ($1, $2, $3, true)',
                        [factoryId, clientIp, userAgent]
                    );
                    await pgPool.query(
                        'UPDATE factories_credentials SET last_login = NOW() WHERE factory_id = $1',
                        [factoryId]
                    );

                    console.log('Login successful for:', email, '(PostgreSQL)');
                    return res.status(200).send({ 
                        message: 'Login successful!',
                        factory: {
                            id: factoryId,
                            factory_name: cred.factory_name,
                            email: cred.email,
                            localisation: cred.localisation,
                            fiscal_matricule: cred.fiscal_matricule,
                            energy_capacity: cred.energy_capacity,
                            contact_info: cred.contact_info,
                            energy_source: cred.energy_type || '',
                            energy_balance: parseFloat(cred.energy_balance) || 0,
                            current_generation: parseFloat(cred.current_generation) || 0,
                            current_consumption: parseFloat(cred.current_consumption) || 0,
                            currency_balance: parseFloat(cred.currency_balance) || 0
                        }
                    });
                } else {
                    console.log('Login failed: Email not found.');
                    return res.status(401).send({ error: 'Invalid email or password.' });
                }
            } catch (pgErr) {
                console.log('PostgreSQL query failed:', pgErr.message);
                return res.status(500).send({ error: 'Database error during login.' });
            }
        } else {
            // PostgreSQL not available
            console.log('Login failed: PostgreSQL not connected');
            return res.status(503).send({ error: 'Database not available. Please try again later.' });
        }

    } catch (error) {
        console.error('Error during login:', error);
        res.status(500).send({ error: 'Failed to login due to a server error.' });
    }
});

/**
 * Sign-Up Endpoint - Register new factory with authentication
 * Stores all data in PostgreSQL
 * Rate limited to prevent abuse
 * POST /signup
 * Body: { factory_name, localisation, fiscal_matricule, energy_capacity, contact_info, energy_source, email, password }
 */
app.post('/signup', signupRateLimiter, async (req, res) => {
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

        const pgAvailable = await isPgConnected();
        if (!pgAvailable) {
            return res.status(503).send({ error: 'Database not available. Please try again later.' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Generate unique factory ID
        const factoryId = generateFactoryId();

        const pgClient = await pgPool.connect();
        try {
            await pgClient.query('BEGIN');

            // Check if email or fiscal matricule already exists
            const existCheckQuery = `
                SELECT email, fiscal_matricule 
                FROM factories_credentials 
                WHERE email = $1 OR fiscal_matricule = $2
            `;
            const existCheck = await pgClient.query(existCheckQuery, [email, fiscal_matricule]);
            
            if (existCheck.rows.length > 0) {
                await pgClient.query('ROLLBACK');
                return res.status(409).send({ error: 'Email or Fiscal Matricule already exists.' });
            }

            // Insert credentials
            await pgClient.query(`
                INSERT INTO factories_credentials 
                (factory_id, email, password_hash, fiscal_matricule) 
                VALUES ($1, $2, $3, $4)
            `, [factoryId, email, hashedPassword, fiscal_matricule]);

            // Insert profile
            await pgClient.query(`
                INSERT INTO factory_profiles 
                (factory_id, factory_name, localisation, contact_info, energy_capacity) 
                VALUES ($1, $2, $3, $4, $5)
            `, [factoryId, factory_name, localisation || '', contact_info || '', energy_capacity || 0]);

            // Insert trading data with initial values
            await pgClient.query(`
                INSERT INTO factory_trading_data 
                (factory_id, energy_balance, currency_balance, daily_consumption, available_energy, current_generation, current_consumption, energy_type) 
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            `, [factoryId, DEFAULT_ENERGY_BALANCE, DEFAULT_CURRENCY_BALANCE, 0, 0, 0, 0, energy_source || DEFAULT_ENERGY_TYPE]);

            await pgClient.query('COMMIT');
            console.log('Factory registered in PostgreSQL:', email);
            
            res.status(201).send({ 
                message: 'Factory registered successfully!',
                factoryId: factoryId,
                blockchainTxHash: generateFakeBlockchainHash()
            });
        } catch (pgErr) {
            await pgClient.query('ROLLBACK');
            if (pgErr.code === '23505') { // Unique violation
                return res.status(409).send({ error: 'Email or Fiscal Matricule already exists.' });
            }
            throw pgErr;
        } finally {
            pgClient.release();
        }

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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(`
                SELECT fc.factory_id, fc.email, fc.fiscal_matricule,
                       fp.factory_name, fp.localisation, fp.contact_info, fp.energy_capacity,
                       ftd.energy_balance, ftd.currency_balance, ftd.daily_consumption, 
                       ftd.available_energy, ftd.current_generation, ftd.current_consumption, ftd.energy_type,
                       fc.created_at
                FROM factories_credentials fc
                LEFT JOIN factory_profiles fp ON fc.factory_id = fp.factory_id
                LEFT JOIN factory_trading_data ftd ON fc.factory_id = ftd.factory_id
                WHERE fc.is_active = true
                ORDER BY fc.created_at DESC
            `);
            
            const transformedFactories = result.rows.map(row => ({
                id: row.factory_id,
                factory_name: row.factory_name,
                localisation: row.localisation,
                fiscal_matricule: row.fiscal_matricule,
                energy_capacity: row.energy_capacity,
                contact_info: row.contact_info,
                energy_source: row.energy_type,
                email: row.email,
                energy_balance: parseFloat(row.energy_balance) || 0,
                current_generation: parseFloat(row.current_generation) || 0,
                current_consumption: parseFloat(row.current_consumption) || 0,
                created_at: row.created_at
            }));
            
            return res.status(200).json({ 
                success: true,
                data: transformedFactories 
            });
        }
        
        res.status(200).json({ success: true, data: [] });
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(`
                SELECT fc.factory_id, fc.email, fc.fiscal_matricule,
                       fp.factory_name, fp.localisation, fp.contact_info, fp.energy_capacity,
                       ftd.energy_balance, ftd.currency_balance, ftd.daily_consumption, 
                       ftd.available_energy, ftd.current_generation, ftd.current_consumption, ftd.energy_type,
                       fc.created_at
                FROM factories_credentials fc
                LEFT JOIN factory_profiles fp ON fc.factory_id = fp.factory_id
                LEFT JOIN factory_trading_data ftd ON fc.factory_id = ftd.factory_id
                WHERE fc.factory_id = $1
            `, [id]);
            
            if (result.rows.length > 0) {
                const row = result.rows[0];
                return res.status(200).json({ 
                    success: true,
                    data: {
                        id: row.factory_id,
                        factory_name: row.factory_name,
                        localisation: row.localisation,
                        fiscal_matricule: row.fiscal_matricule,
                        energy_capacity: row.energy_capacity,
                        contact_info: row.contact_info,
                        energy_source: row.energy_type,
                        email: row.email,
                        energy_balance: parseFloat(row.energy_balance) || 0,
                        current_generation: parseFloat(row.current_generation) || 0,
                        current_consumption: parseFloat(row.current_consumption) || 0,
                        created_at: row.created_at
                    }
                });
            }
        }
        
        res.status(404).json({ error: 'Factory not found.' });
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            await pgPool.query(`
                UPDATE factory_trading_data 
                SET energy_balance = $2, 
                    current_generation = $3, 
                    current_consumption = $4,
                    updated_at = NOW()
                WHERE factory_id = $1
            `, [id, energy_balance || 0, current_generation || 0, current_consumption || 0]);
        }
        
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const result = await pgPool.query(`
                SELECT o.*, fp.factory_name, ftd.energy_type, fp.localisation
                FROM offers o
                LEFT JOIN factory_profiles fp ON o.factory_id = fp.factory_id
                LEFT JOIN factory_trading_data ftd ON o.factory_id = ftd.factory_id
                WHERE o.status = 'active'
                ORDER BY o.created_at DESC
            `);
            
            const transformedOffers = result.rows.map(row => ({
                id: row.offer_id,
                factory_id: row.factory_id,
                offer_type: row.offer_type,
                energy_amount: parseFloat(row.energy_amount),
                price_per_kwh: parseFloat(row.price_per_kwh),
                status: row.status,
                created_at: row.created_at,
                updated_at: row.updated_at,
                factory_name: row.factory_name,
                energy_source: row.energy_type,
                localisation: row.localisation
            }));
            
            return res.status(200).json({ 
                success: true,
                data: transformedOffers 
            });
        }
        
        res.status(200).json({ success: true, data: [] });
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const offerId = generateOfferId();
            
            await pgPool.query(`
                INSERT INTO offers (offer_id, factory_id, offer_type, energy_amount, price_per_kwh, status)
                VALUES ($1, $2, $3, $4, $5, 'active')
            `, [offerId, factory_id, offer_type, energy_amount, price_per_kwh]);
            
            return res.status(201).json({ 
                success: true,
                message: 'Offer created successfully.',
                offerId: offerId,
                blockchainTxHash: generateFakeBlockchainHash()
            });
        }
        
        res.status(503).json({ error: 'Database not available.' });
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            await pgPool.query(`
                UPDATE offers SET status = $2, updated_at = NOW() WHERE offer_id = $1
            `, [id, status]);
        }
        
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            let query = `
                SELECT t.*, 
                       seller_fp.factory_name as seller_name,
                       buyer_fp.factory_name as buyer_name
                FROM trades t
                LEFT JOIN factory_profiles seller_fp ON t.seller_factory_id = seller_fp.factory_id
                LEFT JOIN factory_profiles buyer_fp ON t.buyer_factory_id = buyer_fp.factory_id
            `;
            
            const params = [];
            if (factory_id) {
                query += ' WHERE t.seller_factory_id = $1 OR t.buyer_factory_id = $1';
                params.push(factory_id);
            }
            query += ' ORDER BY t.created_at DESC';
            
            const result = await pgPool.query(query, params);
            
            const transformedTrades = result.rows.map(row => ({
                id: row.trade_id,
                seller_factory_id: row.seller_factory_id,
                buyer_factory_id: row.buyer_factory_id,
                energy_amount: parseFloat(row.energy_amount),
                price_per_kwh: parseFloat(row.price_per_kwh),
                total_price: parseFloat(row.total_price),
                status: row.status,
                created_at: row.created_at,
                completed_at: row.completed_at,
                seller_name: row.seller_name,
                buyer_name: row.buyer_name
            }));
            
            return res.status(200).json({ 
                success: true,
                data: transformedTrades 
            });
        }
        
        res.status(200).json({ success: true, data: [] });
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

        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const tradeId = generateTradeId();
            const totalPrice = parseFloat(energy_amount) * parseFloat(price_per_kwh);
            
            await pgPool.query(`
                INSERT INTO trades (trade_id, seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, total_price, status, blockchain_tx_hash)
                VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7)
            `, [tradeId, seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, totalPrice, generateFakeBlockchainHash()]);
            
            return res.status(201).json({ 
                success: true,
                message: 'Trade created successfully.',
                tradeId: tradeId,
                blockchainTxHash: generateFakeBlockchainHash()
            });
        }
        
        res.status(503).json({ error: 'Database not available.' });
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
        const pgAvailable = await isPgConnected();
        
        if (pgAvailable) {
            const pgClient = await pgPool.connect();
            try {
                await pgClient.query('BEGIN');
                
                // Get trade details
                const tradeResult = await pgClient.query(
                    'SELECT * FROM trades WHERE trade_id = $1 AND status = $2',
                    [id, 'pending']
                );
                
                if (tradeResult.rows.length === 0) {
                    await pgClient.query('ROLLBACK');
                    return res.status(404).json({ error: 'Trade not found or already executed' });
                }
                
                const trade = tradeResult.rows[0];
                const amount = parseFloat(trade.energy_amount);
                const totalPrice = parseFloat(trade.total_price);
                
                // Transfer energy from seller to buyer
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance - $2, available_energy = available_energy - $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.seller_factory_id, amount]);
                
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET energy_balance = energy_balance + $2, available_energy = available_energy + $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.buyer_factory_id, amount]);
                
                // Transfer currency from buyer to seller
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET currency_balance = currency_balance - $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.buyer_factory_id, totalPrice]);
                
                await pgClient.query(`
                    UPDATE factory_trading_data 
                    SET currency_balance = currency_balance + $2, updated_at = NOW()
                    WHERE factory_id = $1
                `, [trade.seller_factory_id, totalPrice]);
                
                // Update trade status to completed
                await pgClient.query(`
                    UPDATE trades 
                    SET status = 'completed', completed_at = NOW(), updated_at = NOW()
                    WHERE trade_id = $1
                `, [id]);
                
                await pgClient.query('COMMIT');
            } catch (e) {
                await pgClient.query('ROLLBACK');
                throw e;
            } finally {
                pgClient.release();
            }
        }
        
        res.status(200).json({ 
            success: true,
            message: 'Trade executed successfully.',
            blockchainTxHash: generateFakeBlockchainHash()
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
 * Creates sample factories with authentication credentials for testing
 */
app.post('/seed', async (req, res) => {
    console.log('Seeding database with sample data (PostgreSQL)...');
    
    try {
        const pgAvailable = await isPgConnected();
        
        if (!pgAvailable) {
            return res.status(503).json({ error: 'Database not available for seeding.' });
        }

        // Create sample factories with authentication for login testing
        const sampleFactories = [
            {
                factory_name: 'Demo Solar Factory',
                email: 'demo@solar.com',
                password: 'Demo1234',
                fiscal_matricule: 'FM-DEMO-SOLAR',
                localisation: 'Tunis Industrial Zone',
                energy_capacity: 5000,
                contact_info: '+216-555-0001',
                energy_source: 'solar'
            },
            {
                factory_name: 'Demo Wind Factory',
                email: 'demo@wind.com',
                password: 'Demo1234',
                fiscal_matricule: 'FM-DEMO-WIND',
                localisation: 'Sfax Industrial Zone',
                energy_capacity: 4000,
                contact_info: '+216-555-0002',
                energy_source: 'wind'
            },
            {
                factory_name: 'Demo Hydro Factory',
                email: 'demo@hydro.com',
                password: 'Demo1234',
                fiscal_matricule: 'FM-DEMO-HYDRO',
                localisation: 'Sousse Industrial Zone',
                energy_capacity: 6000,
                contact_info: '+216-555-0003',
                energy_source: 'hydro'
            }
        ];

        const createdFactories = [];

        for (const factory of sampleFactories) {
            const pgClient = await pgPool.connect();
            try {
                // Check if email already exists
                const existCheck = await pgClient.query(
                    'SELECT factory_id FROM factories_credentials WHERE email = $1',
                    [factory.email]
                );
                
                if (existCheck.rows.length > 0) {
                    console.log(`Factory with email ${factory.email} already exists, skipping.`);
                    createdFactories.push({
                        factoryId: existCheck.rows[0].factory_id,
                        email: factory.email,
                        password: factory.password
                    });
                    continue;
                }

                await pgClient.query('BEGIN');

                // Hash password
                const salt = await bcrypt.genSalt(10);
                const hashedPassword = await bcrypt.hash(factory.password, salt);

                // Generate unique factory ID
                const factoryId = 'Factory_' + Date.now() + '_' + Math.random().toString(36).substring(2, 9);

                // Insert credentials
                await pgClient.query(`
                    INSERT INTO factories_credentials 
                    (factory_id, email, password_hash, fiscal_matricule) 
                    VALUES ($1, $2, $3, $4)
                `, [factoryId, factory.email, hashedPassword, factory.fiscal_matricule]);

                // Insert profile
                await pgClient.query(`
                    INSERT INTO factory_profiles 
                    (factory_id, factory_name, localisation, contact_info, energy_capacity) 
                    VALUES ($1, $2, $3, $4, $5)
                `, [factoryId, factory.factory_name, factory.localisation, factory.contact_info, factory.energy_capacity]);

                // Insert trading data with initial values
                await pgClient.query(`
                    INSERT INTO factory_trading_data 
                    (factory_id, energy_balance, currency_balance, daily_consumption, available_energy, current_generation, current_consumption, energy_type) 
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, [factoryId, DEFAULT_ENERGY_BALANCE, DEFAULT_CURRENCY_BALANCE, 100, 800, 200, 150, factory.energy_source]);

                await pgClient.query('COMMIT');

                createdFactories.push({
                    factoryId,
                    email: factory.email,
                    password: factory.password // Return plain password for testing
                });

                console.log(`Created sample factory: ${factory.factory_name} (${factory.email})`);
            } catch (err) {
                await pgClient.query('ROLLBACK');
                console.log(`Note for factory ${factory.factory_name}:`, err.message);
            } finally {
                pgClient.release();
            }
        }

        res.status(200).json({ 
            success: true,
            message: 'Database seeded successfully!',
            note: 'Sample factories created with authentication for testing.',
            testCredentials: createdFactories
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
    console.log('   (PostgreSQL Backend Mode)');
    console.log('========================================');
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Also accessible at http://127.0.0.1:${PORT}`);
    console.log('');
    console.log('Mode:', USE_BLOCKCHAIN ? 'Hybrid (PostgreSQL + Blockchain)' : 'PostgreSQL Only');
    console.log('');
    console.log('Databases:');
    console.log(`  PostgreSQL: ${pgConnected ? '✅ Connected' : '⚠️  Not available'}`);
    console.log('    - All factory data (credentials, profiles, trading data)');
    console.log('    - Trades and offers');
    console.log('    - Login history & password resets');
    console.log('');
    console.log('  Blockchain:', USE_BLOCKCHAIN ? 'Enabled (optional replication)' : 'Simulated (fake transaction hashes)');
    console.log('');
    console.log('To start PostgreSQL: npm run db:start');
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
    console.log('  FACTORIES (API format):');
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
    console.log('  TRADES (API format):');
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
