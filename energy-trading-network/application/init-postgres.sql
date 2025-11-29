-- PostgreSQL initialization script for Energy Trading Database
-- This database stores ALL factory, trading, and authentication data
-- Blockchain (CouchDB) is optional - PostgreSQL is the primary data store

-- Create factories_credentials table for authentication
CREATE TABLE IF NOT EXISTS factories_credentials (
    id SERIAL PRIMARY KEY,
    factory_id VARCHAR(100) UNIQUE NOT NULL,  -- Links to blockchain factory ID
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    fiscal_matricule VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create factory_profiles table for non-essential info
CREATE TABLE IF NOT EXISTS factory_profiles (
    id SERIAL PRIMARY KEY,
    factory_id VARCHAR(100) UNIQUE NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    factory_name VARCHAR(255) NOT NULL,
    localisation VARCHAR(255),
    contact_info VARCHAR(255),
    energy_capacity INTEGER DEFAULT 0,
    description TEXT,
    logo_url VARCHAR(500),
    website VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create login_history table for security tracking
CREATE TABLE IF NOT EXISTS login_history (
    id SERIAL PRIMARY KEY,
    factory_id VARCHAR(100) NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    login_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN DEFAULT TRUE
);

-- Create password_reset_tokens table
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id SERIAL PRIMARY KEY,
    factory_id VARCHAR(100) NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_credentials_email ON factories_credentials(email);
CREATE INDEX IF NOT EXISTS idx_credentials_factory_id ON factories_credentials(factory_id);
CREATE INDEX IF NOT EXISTS idx_profiles_factory_id ON factory_profiles(factory_id);
CREATE INDEX IF NOT EXISTS idx_login_history_factory_id ON login_history(factory_id);
CREATE INDEX IF NOT EXISTS idx_login_history_time ON login_history(login_time);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
DROP TRIGGER IF EXISTS update_factories_credentials_updated_at ON factories_credentials;
CREATE TRIGGER update_factories_credentials_updated_at
    BEFORE UPDATE ON factories_credentials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_factory_profiles_updated_at ON factory_profiles;
CREATE TRIGGER update_factory_profiles_updated_at
    BEFORE UPDATE ON factory_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create factory_trading_data table for energy/trading data (replaces blockchain data)
CREATE TABLE IF NOT EXISTS factory_trading_data (
    id SERIAL PRIMARY KEY,
    factory_id VARCHAR(100) UNIQUE NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    energy_balance DECIMAL(15,2) DEFAULT 0,
    currency_balance DECIMAL(15,2) DEFAULT 0,
    daily_consumption DECIMAL(15,2) DEFAULT 0,
    available_energy DECIMAL(15,2) DEFAULT 0,
    current_generation DECIMAL(15,2) DEFAULT 0,
    current_consumption DECIMAL(15,2) DEFAULT 0,
    energy_type VARCHAR(50),  -- solar, wind, hydro, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create trades table for energy trades between factories
CREATE TABLE IF NOT EXISTS trades (
    id SERIAL PRIMARY KEY,
    trade_id VARCHAR(100) UNIQUE NOT NULL,
    seller_factory_id VARCHAR(100) NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    buyer_factory_id VARCHAR(100) NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    energy_amount DECIMAL(15,2) NOT NULL,
    price_per_kwh DECIMAL(10,4) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',  -- pending, active, completed, cancelled
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    blockchain_tx_hash VARCHAR(255),  -- Simulated blockchain hash for backward compatibility (not a real blockchain reference)
    CONSTRAINT valid_status CHECK (status IN ('pending', 'active', 'completed', 'cancelled'))
);

-- Create offers table for energy buy/sell offers
CREATE TABLE IF NOT EXISTS offers (
    id SERIAL PRIMARY KEY,
    offer_id VARCHAR(100) UNIQUE NOT NULL,
    factory_id VARCHAR(100) NOT NULL REFERENCES factories_credentials(factory_id) ON DELETE CASCADE,
    offer_type VARCHAR(10) NOT NULL,  -- 'buy' or 'sell'
    energy_amount DECIMAL(15,2) NOT NULL,
    price_per_kwh DECIMAL(10,4) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',  -- active, completed, cancelled, expired
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_offer_type CHECK (offer_type IN ('buy', 'sell')),
    CONSTRAINT valid_offer_status CHECK (status IN ('active', 'completed', 'cancelled', 'expired'))
);

-- Create indexes for trading tables
CREATE INDEX IF NOT EXISTS idx_trading_data_factory_id ON factory_trading_data(factory_id);
CREATE INDEX IF NOT EXISTS idx_trades_seller ON trades(seller_factory_id);
CREATE INDEX IF NOT EXISTS idx_trades_buyer ON trades(buyer_factory_id);
CREATE INDEX IF NOT EXISTS idx_trades_status ON trades(status);
CREATE INDEX IF NOT EXISTS idx_trades_created ON trades(created_at);
CREATE INDEX IF NOT EXISTS idx_offers_factory_id ON offers(factory_id);
CREATE INDEX IF NOT EXISTS idx_offers_type ON offers(offer_type);
CREATE INDEX IF NOT EXISTS idx_offers_status ON offers(status);

-- Triggers for trading tables
DROP TRIGGER IF EXISTS update_factory_trading_data_updated_at ON factory_trading_data;
CREATE TRIGGER update_factory_trading_data_updated_at
    BEFORE UPDATE ON factory_trading_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_trades_updated_at ON trades;
CREATE TRIGGER update_trades_updated_at
    BEFORE UPDATE ON trades
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_offers_updated_at ON offers;
CREATE TRIGGER update_offers_updated_at
    BEFORE UPDATE ON offers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant specific permissions (principle of least privilege)
-- Only grant the necessary operations for the application
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO energy_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO energy_admin;
