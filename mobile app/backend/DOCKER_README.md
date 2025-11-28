# Docker Setup for Energy Trading Backend

This backend application has been containerized with Docker and uses MySQL as the database. Everything runs in containers for easy deployment and development.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose installed (included with Docker Desktop)

## Quick Start

### 1. Configure Environment Variables

Copy the example environment file and customize if needed:

```bash
cp .env.example .env
```

Edit `.env` to set your own passwords (optional but recommended for production):

```env
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=energy_trading
MYSQL_USER=energy_user
MYSQL_PASSWORD=your_secure_password
```

### 2. Start the Application

Run the following command in the backend directory:

```bash
docker-compose up -d
```

This will:
- Pull the MySQL 8.0 image
- Build the Node.js backend image
- Start both containers
- Automatically create the database and tables from `energy_trading_schema.sql`

### 3. Verify Everything is Running

Check the status of containers:

```bash
docker-compose ps
```

You should see both `energy-trading-mysql` and `energy-trading-backend` running.

### 4. Test the API

The backend will be available at `http://localhost:5000`

Test endpoint:
```bash
curl http://localhost:5000/test
```

## Available Commands

### Start the containers
```bash
docker-compose up -d
```

### Stop the containers
```bash
docker-compose down
```

### Stop and remove all data (including database)
```bash
docker-compose down -v
```

### View logs
```bash
# All logs
docker-compose logs

# Backend logs only
docker-compose logs backend

# MySQL logs only
docker-compose logs mysql

# Follow logs in real-time
docker-compose logs -f
```

### Restart containers
```bash
docker-compose restart
```

### Rebuild the backend image (after code changes)
```bash
docker-compose up -d --build
```

## API Endpoints

### Test Endpoint
- **GET** `/test`
- Returns: `{"message": "Backend is working!"}`

### Sign Up
- **POST** `/signup`
- Body:
  ```json
  {
    "factory_name": "Factory Name",
    "localisation": "Location",
    "fiscal_matricule": "123456789",
    "energy_capacity": 1000,
    "contact_info": "contact@factory.com",
    "energy_source": "solar",
    "email": "factory@example.com",
    "password": "SecurePass123"
  }
  ```

### Login
- **POST** `/login`
- Body:
  ```json
  {
    "email": "factory@example.com",
    "password": "SecurePass123"
  }
  ```

## Architecture

### Services

1. **MySQL Container** (`mysql`)
   - Image: `mysql:8.0`
   - Port: `3306`
   - Database is automatically initialized with schema on first run
   - Data is persisted in a Docker volume

2. **Backend Container** (`backend`)
   - Built from local Dockerfile
   - Port: `5000`
   - Connects to MySQL using the service name `mysql` as hostname
   - Waits for MySQL to be healthy before starting

### Network

Both containers are connected via a custom Docker network (`energy-network`), allowing them to communicate using service names.

### Data Persistence

MySQL data is stored in a Docker volume named `mysql_data`, which persists even if containers are stopped or removed (unless you use `docker-compose down -v`).

## Troubleshooting

### Backend can't connect to database

Wait a few seconds for MySQL to fully initialize, then restart the backend:
```bash
docker-compose restart backend
```

### Check if MySQL is ready
```bash
docker-compose exec mysql mysqladmin ping -h localhost -u root -p
```

### Access MySQL directly
```bash
docker-compose exec mysql mysql -u energy_user -p energy_trading
```
(Password: `energy_password` by default)

### Reset everything
```bash
docker-compose down -v
docker-compose up -d
```

## Development

To make changes to the backend code:

1. Edit the files locally
2. Rebuild and restart: `docker-compose up -d --build`
3. Check logs: `docker-compose logs -f backend`

## Production Deployment

For production:

1. Change all default passwords in `.env`
2. Use proper secrets management
3. Configure proper CORS settings
4. Add HTTPS/SSL termination
5. Use Docker secrets or environment variable injection from your hosting platform
6. Consider using a managed MySQL service instead of a container

## Notes

- The MySQL container automatically runs the `energy_trading_schema.sql` script on first startup
- If you need to reset the database, use `docker-compose down -v` to remove volumes
- The backend uses environment variables for all configuration, making it easy to deploy anywhere
