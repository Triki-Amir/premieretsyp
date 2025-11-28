const express = require('express');
const mysql = require('mysql2');
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

// Create a MySQL connection pool
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
pool.getConnection((err, connection) => {
    if (err) {
        console.error('Error connecting to MySQL database:', err);
        return;
    }
    console.log('Successfully connected to the MySQL database.');
    connection.release();
});

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
        
        pool.query(sql, [email], async (err, results) => {
            if (err) {
                console.error('=== DATABASE ERROR ===');
                console.error('Error:', err);
                console.error('=====================');
                return res.status(500).send({ error: 'Database error occurred.' });
            }

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
                    energy_source: factory.energy_source
                }
            });
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

        pool.query(sql, values, (err, result) => {
            if (err) {
                console.error('=== DATABASE ERROR ===');
                console.error('Error Code:', err.code);
                console.error('Error Message:', err.message);
                console.error('SQL:', err.sql);
                console.error('Full Error:', err);
                console.error('=====================');
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(409).send({ error: 'Email or Fiscal Matricule already exists.' });
                }
                return res.status(500).send({ error: 'Failed to register factory due to a database error.' });
            }
            console.log('Factory registered successfully:', email);
            res.status(201).send({ message: 'Factory registered successfully!' });
        });

    } catch (error) {
        console.error('Error during signup:', error);
        res.status(500).send({ error: 'Failed to register factory due to a server error.' });
    }
});


// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Also accessible at http://127.0.0.1:${PORT}`);
});