-- PostgreSQL initialization script for Energy Trading Credentials Database
-- This database stores authentication data and non-essential factory information
-- Trading data (energy, ID, currency) remains in CouchDB via Hyperledger Fabric blockchain

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

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO energy_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO energy_admin;
