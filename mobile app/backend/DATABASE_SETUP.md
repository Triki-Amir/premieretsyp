# Database Setup Instructions

## Prerequisites
- MySQL Server installed (version 8.0 or higher)
- MySQL user with database creation privileges

## Setup Steps

### 1. Create the Database
```sql
CREATE DATABASE energy_trading;
```

### 2. Import the Schema
Run the following command in your terminal:
```bash
mysql -u your_username -p energy_trading < energy_trading_schema.sql
```

Or open MySQL Workbench and:
1. Connect to your MySQL server
2. Open the file `energy_trading_schema.sql`
3. Execute the script

### 3. Configure Backend Connection
Edit `server.js` and update the MySQL connection settings:
```javascript
const pool = mysql.createPool({
    host: '127.0.0.1',
    user: 'your_mysql_username',
    password: 'your_mysql_password',
    database: 'energy_trading',
    // ... other settings
});
```

## Database Structure

### Factories Table
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `factory_name` (VARCHAR(255), NOT NULL)
- `localisation` (VARCHAR(255))
- `fiscal_matricule` (VARCHAR(255), UNIQUE, NOT NULL)
- `energy_capacity` (INT)
- `contact_info` (VARCHAR(255))
- `energy_source` (VARCHAR(255))
- `email` (VARCHAR(255), UNIQUE, NOT NULL)
- `password` (VARCHAR(255), NOT NULL, HASHED)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

## Security Notes
- Passwords are hashed using bcrypt
- Never commit your actual database password to version control
- Use environment variables for sensitive configuration in production
