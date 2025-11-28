const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcryptjs');
require('dotenv').config();

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
app.use(cors());

// Create a MySQL connection pool (using promise-based API)
const pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'abderrahmen',
    password: process.env.DB_PASSWORD || 'your_password_here',
    database: process.env.DB_NAME || 'energy_trading',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test the database connection
(async () => {
    try {
        const connection = await pool.getConnection();
        console.log('Successfully connected to the MySQL database.');
        connection.release();
    } catch (err) {
        console.error('Error connecting to MySQL database:', err);
    }
})();

// Initialize additional tables for offers and trades
async function initializeTables() {
    try {
        // Create offers table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS offers (
                id INT NOT NULL AUTO_INCREMENT,
                factory_id INT NOT NULL,
                offer_type ENUM('buy', 'sell') NOT NULL,
                energy_amount DECIMAL(10, 2) NOT NULL,
                price_per_kwh DECIMAL(10, 4) NOT NULL,
                status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (id),
                FOREIGN KEY (factory_id) REFERENCES factories(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
        `);
        console.log('Offers table ready.');

        // Create trades table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS trades (
                id INT NOT NULL AUTO_INCREMENT,
                seller_factory_id INT NOT NULL,
                buyer_factory_id INT NOT NULL,
                energy_amount DECIMAL(10, 2) NOT NULL,
                price_per_kwh DECIMAL(10, 4) NOT NULL,
                total_price DECIMAL(10, 2) NOT NULL,
                status ENUM('pending', 'active', 'completed', 'cancelled') DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                completed_at TIMESTAMP NULL,
                PRIMARY KEY (id),
                FOREIGN KEY (seller_factory_id) REFERENCES factories(id) ON DELETE CASCADE,
                FOREIGN KEY (buyer_factory_id) REFERENCES factories(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
        `);
        console.log('Trades table ready.');

        // Add energy_balance column to factories if it doesn't exist
        try {
            await pool.query(`
                ALTER TABLE factories ADD COLUMN IF NOT EXISTS energy_balance DECIMAL(10, 2) DEFAULT 0
            `);
        } catch (err) {
            // Column might already exist, ignore the error
            if (!err.message.includes('Duplicate column')) {
                console.log('Note: energy_balance column handling:', err.message);
            }
        }

        // Add current_generation column to factories if it doesn't exist
        try {
            await pool.query(`
                ALTER TABLE factories ADD COLUMN IF NOT EXISTS current_generation DECIMAL(10, 2) DEFAULT 0
            `);
        } catch (err) {
            if (!err.message.includes('Duplicate column')) {
                console.log('Note: current_generation column handling:', err.message);
            }
        }

        // Add current_consumption column to factories if it doesn't exist
        try {
            await pool.query(`
                ALTER TABLE factories ADD COLUMN IF NOT EXISTS current_consumption DECIMAL(10, 2) DEFAULT 0
            `);
        } catch (err) {
            if (!err.message.includes('Duplicate column')) {
                console.log('Note: current_consumption column handling:', err.message);
            }
        }

    } catch (err) {
        console.error('Error initializing tables:', err);
    }
}

// Initialize tables on startup
initializeTables();

// Simple test endpoint
app.get('/test', (req, res) => {
    console.log('Test endpoint hit!');
    res.json({ message: 'Backend is working!' });
});

// Login Endpoint
app.post('/login', async (req, res) => {
    console.log('Received login request with email:', req.body.email);
    try {
        const { email, password } = req.body;

        // Basic validation
        if (!email || !password) {
            console.log('Login failed: Email or password missing.');
            return res.status(400).send({ error: 'Email and password are required.' });
        }

        const sql = `SELECT * FROM factories WHERE email = ?`;
        
        const [results] = await pool.query(sql, [email]);

        if (results.length === 0) {
            console.log('Login failed: Email not found.');
            return res.status(401).send({ error: 'Invalid email or password.' });
        }

        const factory = results[0];

        // Compare password with hashed password
        const isPasswordValid = await bcrypt.compare(password, factory.password);

        if (!isPasswordValid) {
            console.log('Login failed: Invalid password.');
            return res.status(401).send({ error: 'Invalid email or password.' });
        }

        console.log('Login successful for:', email);
        res.status(200).send({ 
            message: 'Login successful!',
            factory: {
                id: factory.id,
                factory_name: factory.factory_name,
                email: factory.email,
                localisation: factory.localisation,
                fiscal_matricule: factory.fiscal_matricule,
                energy_capacity: factory.energy_capacity,
                contact_info: factory.contact_info,
                energy_source: factory.energy_source,
                energy_balance: factory.energy_balance || 0,
                current_generation: factory.current_generation || 0,
                current_consumption: factory.current_consumption || 0
            }
        });

    } catch (error) {
        console.error('Error during login:', error);
        res.status(500).send({ error: 'Failed to login due to a server error.' });
    }
});

// Sign-Up Endpoint
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

        const sql = `INSERT INTO factories (factory_name, localisation, fiscal_matricule, energy_capacity, contact_info, energy_source, email, password) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
        const values = [
            factory_name,
            localisation,
            fiscal_matricule,
            energy_capacity,
            contact_info,
            energy_source,
            email,
            hashedPassword
        ];

        await pool.query(sql, values);
        console.log('Factory registered successfully:', email);
        res.status(201).send({ message: 'Factory registered successfully!' });

    } catch (error) {
        console.error('Error during signup:', error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).send({ error: 'Email or Fiscal Matricule already exists.' });
        }
        res.status(500).send({ error: 'Failed to register factory due to a server error.' });
    }
});

// ==================== FACTORIES ENDPOINTS ====================

// Get all factories
app.get('/factories', async (req, res) => {
    console.log('Fetching all factories');
    try {
        const [results] = await pool.query(`
            SELECT id, factory_name, localisation, fiscal_matricule, energy_capacity, 
                   contact_info, energy_source, email, energy_balance, 
                   current_generation, current_consumption, created_at
            FROM factories
        `);
        
        res.status(200).json({ 
            success: true,
            data: results 
        });
    } catch (error) {
        console.error('Error fetching factories:', error);
        res.status(500).json({ error: 'Failed to fetch factories.' });
    }
});

// Get a single factory by ID
app.get('/factory/:id', async (req, res) => {
    const { id } = req.params;
    console.log('Fetching factory with ID:', id);
    try {
        const [results] = await pool.query(`
            SELECT id, factory_name, localisation, fiscal_matricule, energy_capacity, 
                   contact_info, energy_source, email, energy_balance, 
                   current_generation, current_consumption, created_at
            FROM factories WHERE id = ?
        `, [id]);
        
        if (results.length === 0) {
            return res.status(404).json({ error: 'Factory not found.' });
        }
        
        res.status(200).json({ 
            success: true,
            data: results[0] 
        });
    } catch (error) {
        console.error('Error fetching factory:', error);
        res.status(500).json({ error: 'Failed to fetch factory.' });
    }
});

// Update factory energy data
app.put('/factory/:id/energy', async (req, res) => {
    const { id } = req.params;
    const { energy_balance, current_generation, current_consumption } = req.body;
    
    console.log('Updating energy data for factory:', id);
    try {
        await pool.query(`
            UPDATE factories 
            SET energy_balance = ?, current_generation = ?, current_consumption = ?
            WHERE id = ?
        `, [energy_balance, current_generation, current_consumption, id]);
        
        res.status(200).json({ 
            success: true,
            message: 'Factory energy data updated successfully.' 
        });
    } catch (error) {
        console.error('Error updating factory energy:', error);
        res.status(500).json({ error: 'Failed to update factory energy data.' });
    }
});

// ==================== OFFERS ENDPOINTS ====================

// Get all offers
app.get('/offers', async (req, res) => {
    console.log('Fetching all offers');
    try {
        const [results] = await pool.query(`
            SELECT o.*, f.factory_name, f.energy_source, f.localisation
            FROM offers o
            JOIN factories f ON o.factory_id = f.id
            WHERE o.status = 'active'
            ORDER BY o.created_at DESC
        `);
        
        res.status(200).json({ 
            success: true,
            data: results 
        });
    } catch (error) {
        console.error('Error fetching offers:', error);
        res.status(500).json({ error: 'Failed to fetch offers.' });
    }
});

// Create a new offer
app.post('/offers', async (req, res) => {
    console.log('Creating new offer:', req.body);
    try {
        const { factory_id, offer_type, energy_amount, price_per_kwh } = req.body;

        if (!factory_id || !offer_type || !energy_amount || !price_per_kwh) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        const [result] = await pool.query(`
            INSERT INTO offers (factory_id, offer_type, energy_amount, price_per_kwh)
            VALUES (?, ?, ?, ?)
        `, [factory_id, offer_type, energy_amount, price_per_kwh]);
        
        res.status(201).json({ 
            success: true,
            message: 'Offer created successfully.',
            offerId: result.insertId 
        });
    } catch (error) {
        console.error('Error creating offer:', error);
        res.status(500).json({ error: 'Failed to create offer.' });
    }
});

// Update offer status
app.put('/offers/:id', async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    
    console.log('Updating offer status:', id, status);
    try {
        await pool.query(`
            UPDATE offers SET status = ? WHERE id = ?
        `, [status, id]);
        
        res.status(200).json({ 
            success: true,
            message: 'Offer updated successfully.' 
        });
    } catch (error) {
        console.error('Error updating offer:', error);
        res.status(500).json({ error: 'Failed to update offer.' });
    }
});

// ==================== TRADES ENDPOINTS ====================

// Get all trades
app.get('/trades', async (req, res) => {
    const { factory_id } = req.query;
    console.log('Fetching trades, factory_id:', factory_id);
    
    try {
        let sql = `
            SELECT t.*, 
                   sf.factory_name as seller_name, 
                   bf.factory_name as buyer_name
            FROM trades t
            JOIN factories sf ON t.seller_factory_id = sf.id
            JOIN factories bf ON t.buyer_factory_id = bf.id
        `;
        
        const params = [];
        if (factory_id) {
            sql += ' WHERE t.seller_factory_id = ? OR t.buyer_factory_id = ?';
            params.push(factory_id, factory_id);
        }
        
        sql += ' ORDER BY t.created_at DESC';
        
        const [results] = await pool.query(sql, params);
        
        res.status(200).json({ 
            success: true,
            data: results 
        });
    } catch (error) {
        console.error('Error fetching trades:', error);
        res.status(500).json({ error: 'Failed to fetch trades.' });
    }
});

// Create a new trade
app.post('/trades', async (req, res) => {
    console.log('Creating new trade:', req.body);
    try {
        const { seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh } = req.body;

        if (!seller_factory_id || !buyer_factory_id || !energy_amount || !price_per_kwh) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        const total_price = energy_amount * price_per_kwh;

        const [result] = await pool.query(`
            INSERT INTO trades (seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, total_price, status)
            VALUES (?, ?, ?, ?, ?, 'pending')
        `, [seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, total_price]);
        
        res.status(201).json({ 
            success: true,
            message: 'Trade created successfully.',
            tradeId: result.insertId 
        });
    } catch (error) {
        console.error('Error creating trade:', error);
        res.status(500).json({ error: 'Failed to create trade.' });
    }
});

// Execute/complete a trade
app.post('/trades/:id/execute', async (req, res) => {
    const { id } = req.params;
    console.log('Executing trade:', id);
    
    try {
        // Get trade details
        const [trades] = await pool.query('SELECT * FROM trades WHERE id = ?', [id]);
        if (trades.length === 0) {
            return res.status(404).json({ error: 'Trade not found.' });
        }
        
        const trade = trades[0];
        
        // Update factory balances
        // Seller loses energy, gains money (simulated here as energy_balance update)
        await pool.query(`
            UPDATE factories 
            SET energy_balance = energy_balance - ?
            WHERE id = ?
        `, [trade.energy_amount, trade.seller_factory_id]);
        
        // Buyer gains energy
        await pool.query(`
            UPDATE factories 
            SET energy_balance = energy_balance + ?
            WHERE id = ?
        `, [trade.energy_amount, trade.buyer_factory_id]);
        
        // Update trade status
        await pool.query(`
            UPDATE trades 
            SET status = 'completed', completed_at = NOW()
            WHERE id = ?
        `, [id]);
        
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

// Seed the database with sample data
app.post('/seed', async (req, res) => {
    console.log('Seeding database with sample data...');
    
    try {
        // First, check if factories already exist
        const [existingFactories] = await pool.query('SELECT COUNT(*) as count FROM factories');
        
        const sampleFactories = [
            {
                factory_name: 'Solar Power Plant Alpha',
                localisation: 'New York, USA',
                fiscal_matricule: 'FM-001-SOLAR',
                energy_capacity: 500,
                contact_info: '+1-555-0101',
                energy_source: 'Solar',
                email: 'alpha@solarpower.com',
                password: 'password123',
                energy_balance: 150.5,
                current_generation: 245,
                current_consumption: 120
            },
            {
                factory_name: 'Wind Farm Beta',
                localisation: 'Chicago, USA',
                fiscal_matricule: 'FM-002-WIND',
                energy_capacity: 400,
                contact_info: '+1-555-0102',
                energy_source: 'Wind',
                email: 'beta@windfarm.com',
                password: 'password123',
                energy_balance: -30.0,
                current_generation: 180,
                current_consumption: 220
            },
            {
                factory_name: 'Hybrid Energy Plant Gamma',
                localisation: 'Los Angeles, USA',
                fiscal_matricule: 'FM-003-HYBRID',
                energy_capacity: 600,
                contact_info: '+1-555-0103',
                energy_source: 'Solar/Wind',
                email: 'gamma@hybridenergy.com',
                password: 'password123',
                energy_balance: 80.0,
                current_generation: 320,
                current_consumption: 280
            },
            {
                factory_name: 'Green Factory Delta',
                localisation: 'San Francisco, USA',
                fiscal_matricule: 'FM-004-GREEN',
                energy_capacity: 350,
                contact_info: '+1-555-0104',
                energy_source: 'Solar',
                email: 'delta@greenfactory.com',
                password: 'password123',
                energy_balance: 45.0,
                current_generation: 200,
                current_consumption: 155
            },
            {
                factory_name: 'EcoWind Station Epsilon',
                localisation: 'Seattle, USA',
                fiscal_matricule: 'FM-005-ECO',
                energy_capacity: 450,
                contact_info: '+1-555-0105',
                energy_source: 'Wind',
                email: 'epsilon@ecowind.com',
                password: 'password123',
                energy_balance: -15.0,
                current_generation: 190,
                current_consumption: 205
            }
        ];

        const insertedFactoryIds = [];

        for (const factory of sampleFactories) {
            try {
                // Check if this factory already exists
                const [existing] = await pool.query(
                    'SELECT id FROM factories WHERE email = ? OR fiscal_matricule = ?',
                    [factory.email, factory.fiscal_matricule]
                );

                if (existing.length > 0) {
                    // Update existing factory with energy data
                    await pool.query(`
                        UPDATE factories 
                        SET energy_balance = ?, current_generation = ?, current_consumption = ?
                        WHERE id = ?
                    `, [factory.energy_balance, factory.current_generation, factory.current_consumption, existing[0].id]);
                    insertedFactoryIds.push(existing[0].id);
                    console.log(`Updated existing factory: ${factory.factory_name}`);
                } else {
                    // Insert new factory
                    const salt = await bcrypt.genSalt(10);
                    const hashedPassword = await bcrypt.hash(factory.password, salt);
                    
                    const [result] = await pool.query(`
                        INSERT INTO factories (factory_name, localisation, fiscal_matricule, energy_capacity, 
                                              contact_info, energy_source, email, password, 
                                              energy_balance, current_generation, current_consumption)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    `, [
                        factory.factory_name, factory.localisation, factory.fiscal_matricule,
                        factory.energy_capacity, factory.contact_info, factory.energy_source,
                        factory.email, hashedPassword, factory.energy_balance,
                        factory.current_generation, factory.current_consumption
                    ]);
                    insertedFactoryIds.push(result.insertId);
                    console.log(`Inserted new factory: ${factory.factory_name}`);
                }
            } catch (err) {
                console.log(`Note for factory ${factory.factory_name}:`, err.message);
            }
        }

        // Create sample offers if we have factories
        if (insertedFactoryIds.length >= 2) {
            const sampleOffers = [
                { factory_id: insertedFactoryIds[0], offer_type: 'sell', energy_amount: 50, price_per_kwh: 0.10 },
                { factory_id: insertedFactoryIds[1], offer_type: 'buy', energy_amount: 30, price_per_kwh: 0.12 },
                { factory_id: insertedFactoryIds[2] || insertedFactoryIds[0], offer_type: 'sell', energy_amount: 40, price_per_kwh: 0.09 },
                { factory_id: insertedFactoryIds[3] || insertedFactoryIds[1], offer_type: 'sell', energy_amount: 25, price_per_kwh: 0.11 },
                { factory_id: insertedFactoryIds[4] || insertedFactoryIds[0], offer_type: 'buy', energy_amount: 35, price_per_kwh: 0.13 }
            ];

            for (const offer of sampleOffers) {
                try {
                    await pool.query(`
                        INSERT INTO offers (factory_id, offer_type, energy_amount, price_per_kwh)
                        VALUES (?, ?, ?, ?)
                    `, [offer.factory_id, offer.offer_type, offer.energy_amount, offer.price_per_kwh]);
                } catch (err) {
                    // Ignore duplicate errors
                    console.log('Note for offer:', err.message);
                }
            }
            console.log('Sample offers created.');
        }

        // Create sample trades if we have factories
        if (insertedFactoryIds.length >= 2) {
            const sampleTrades = [
                { 
                    seller_factory_id: insertedFactoryIds[0], 
                    buyer_factory_id: insertedFactoryIds[1], 
                    energy_amount: 20, 
                    price_per_kwh: 0.10,
                    status: 'completed'
                },
                { 
                    seller_factory_id: insertedFactoryIds[2] || insertedFactoryIds[0], 
                    buyer_factory_id: insertedFactoryIds[4] || insertedFactoryIds[1], 
                    energy_amount: 15, 
                    price_per_kwh: 0.11,
                    status: 'active'
                }
            ];

            for (const trade of sampleTrades) {
                try {
                    const total_price = trade.energy_amount * trade.price_per_kwh;
                    await pool.query(`
                        INSERT INTO trades (seller_factory_id, buyer_factory_id, energy_amount, price_per_kwh, total_price, status)
                        VALUES (?, ?, ?, ?, ?, ?)
                    `, [trade.seller_factory_id, trade.buyer_factory_id, trade.energy_amount, trade.price_per_kwh, total_price, trade.status]);
                } catch (err) {
                    console.log('Note for trade:', err.message);
                }
            }
            console.log('Sample trades created.');
        }

        res.status(200).json({ 
            success: true,
            message: 'Database seeded successfully!',
            factoriesCreated: insertedFactoryIds.length
        });

    } catch (error) {
        console.error('Error seeding database:', error);
        res.status(500).json({ error: 'Failed to seed database.' });
    }
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Also accessible at http://127.0.0.1:${PORT}`);
});