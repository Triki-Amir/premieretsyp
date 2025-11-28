# NILM Backend API - Deployment Guide

This guide covers deploying the NILM Backend API to production environments.

## 📋 Deployment Checklist

- [ ] Review configuration settings
- [ ] Set up model serving infrastructure
- [ ] Configure environment variables
- [ ] Enable HTTPS/SSL
- [ ] Set up logging and monitoring
- [ ] Configure CORS for your frontend domain
- [ ] Set up health check monitoring
- [ ] Test all endpoints in production
- [ ] Set up database or persistent storage (optional)
- [ ] Document API endpoints for your team

## 🏗️ Deployment Options

### Option 1: Local Machine / Server (Recommended for Starting)

**Requirements:**
- Windows/macOS/Linux
- Node.js 16+
- Python 3.9+
- 4GB RAM minimum
- GPU optional (but recommended for faster inference)

**Steps:**

1. **Prepare the server:**
```bash
# Clone/copy the backend_api folder
cd /path/to/backend_api

# Install dependencies
npm install
cd python_service
pip install -r requirements.txt
cd ..
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with production settings
```

3. **Start services with PM2** (recommended for auto-restart):
```bash
# Install PM2 globally
npm install -g pm2

# Start Flask service
pm2 start "cd python_service && python model_service.py" --name nilm-flask --interpreter bash

# Start Express service
pm2 start npm --name nilm-api -- start

# Monitor
pm2 monitor

# Save startup configuration
pm2 startup
pm2 save
```

4. **Configure reverse proxy** (nginx):
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    # API proxy
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeout settings for long inference
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Rate limiting
    location /api/predict {
        limit_req zone=api burst=10 nodelay;
        proxy_pass http://localhost:3000;
    }
}

# Define rate limit zone
limit_req_zone $binary_remote_addr zone=api:10m rate=2r/s;
```

### Option 2: Docker (Recommended for Scaling)

**Create Dockerfile for Express:**

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

# Install Node dependencies
COPY package*.json ./
RUN npm install --production

# Copy source code
COPY src ./src
COPY config ./config
COPY .env ./

EXPOSE 3000

CMD ["npm", "start"]
```

**Create Dockerfile for Python:**

```dockerfile
# python_service/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy model files
COPY ../NILM_SIDED/saved_models ./saved_models

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY model_service.py ./

EXPOSE 5000

CMD ["python", "model_service.py"]
```

**Create docker-compose.yml:**

```yaml
version: '3.8'

services:
  # Python Flask model service
  python-service:
    build:
      context: ./python_service
      dockerfile: Dockerfile
    container_name: nilm-flask
    ports:
      - "5000:5000"
    environment:
      - FLASK_PORT=5000
      - MODEL_NAME=TCN_best.pth
      - FLASK_DEBUG=false
    volumes:
      - ./NILM_SIDED/saved_models:/app/saved_models
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Express API server
  express-api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: nilm-api
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - EXPRESS_PORT=3000
      - FLASK_SERVICE_URL=http://python-service:5000
    depends_on:
      python-service:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Optional: nginx reverse proxy
  nginx:
    image: nginx:alpine
    container_name: nilm-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - express-api
    restart: unless-stopped
```

**Deploy with Docker Compose:**

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Option 3: Cloud Platforms

#### AWS EC2 + ECS

```bash
# Create ECR repository
aws ecr create-repository --repository-name nilm-api

# Tag and push images
docker tag nilm-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/nilm-api:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/nilm-api:latest
```

#### Google Cloud Run

```bash
# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/PROJECT-ID/nilm-api

# Deploy
gcloud run deploy nilm-api \
  --image gcr.io/PROJECT-ID/nilm-api \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --timeout 300
```

#### Heroku

```bash
# Login to Heroku
heroku login

# Create app
heroku create nilm-api

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set FLASK_SERVICE_URL=<python-service-url>

# Deploy
git push heroku main
```

## 🔒 Security Configuration

### 1. Environment Variables (.env)

```env
# Node environment
NODE_ENV=production

# API Configuration
EXPRESS_PORT=3000
CORS_ORIGIN=https://your-frontend-domain.com

# Flask Service
FLASK_PORT=5000
FLASK_SERVICE_URL=http://localhost:5000
FLASK_DEBUG=false

# Model Configuration
MODEL_NAME=TCN_best.pth
MODEL_PATH=./saved_models

# Security
API_KEY_ENABLED=true
API_KEY=your-secret-api-key-here
RATE_LIMIT_WINDOW=900000  # 15 minutes in ms
RATE_LIMIT_MAX=100  # Max requests per window

# Logging
LOG_LEVEL=info
LOG_FILE=./logs/app.log
```

### 2. Add API Key Authentication

Update `src/routes.js`:

```javascript
// Middleware to check API key
function checkApiKey(req, res, next) {
  if (process.env.API_KEY_ENABLED === 'true') {
    const apiKey = req.headers['x-api-key'];
    if (!apiKey || apiKey !== process.env.API_KEY) {
      return res.status(401).json({
        status: 'error',
        error: 'Invalid or missing API key',
      });
    }
  }
  next();
}

// Apply to predict endpoint
router.post('/predict', checkApiKey, async (req, res) => {
  // ... existing code
});
```

### 3. Rate Limiting

```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 900000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  message: 'Too many requests, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/predict', limiter);
```

### 4. HTTPS/SSL

```javascript
import https from 'https';
import fs from 'fs';

const options = {
  key: fs.readFileSync('./certs/private.key'),
  cert: fs.readFileSync('./certs/certificate.crt'),
};

https.createServer(options, app).listen(443);
```

## 📊 Monitoring & Logging

### 1. Set Up Logging

```bash
# Create logs directory
mkdir -p logs

# Tail logs in real-time
tail -f logs/app.log
```

### 2. Monitor with Prometheus + Grafana

Create `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nilm-api'
    static_configs:
      - targets: ['localhost:3000']

  - job_name: 'nilm-flask'
    static_configs:
      - targets: ['localhost:5000']
```

### 3. Set Up Health Checks

```bash
# Create monitoring script
#!/bin/bash
while true; do
  curl -f http://localhost:3000/api/health
  curl -f http://localhost:5000/health
  sleep 60
done
```

## 🚀 Performance Tuning

### 1. Node.js Optimization

```bash
# Run with clustering (multiple processes)
NODE_CLUSTER=true npm start

# Increase memory limit
NODE_OPTIONS="--max-old-space-size=2048" npm start
```

### 2. Python Optimization

```bash
# Use gunicorn for production (instead of Flask dev server)
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 model_service:app
```

### 3. GPU Optimization

Update `python_service/model_service.py`:

```python
# Enable mixed precision
torch.cuda.amp.autocast(enabled=True)

# Use TF32 acceleration
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True
```

## 📈 Scaling Strategies

### Horizontal Scaling (Multiple Instances)

```bash
# Start multiple Flask instances
for i in {5000..5003}; do
  FLASK_PORT=$i python model_service.py &
done

# Use load balancer to distribute requests
```

### Caching Predictions

```javascript
// Add Redis caching
import redis from 'redis';

const redisClient = redis.createClient();

// Cache recent predictions
async function getCachedPrediction(hash) {
  return await redisClient.get(`nilm:${hash}`);
}

async function cachePrediction(hash, result) {
  await redisClient.setEx(`nilm:${hash}`, 3600, JSON.stringify(result));
}
```

## 🔍 Troubleshooting

### Service Won't Start

```bash
# Check if ports are in use
netstat -tlnp | grep :3000
netstat -tlnp | grep :5000

# Kill process using port
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

### High Latency

1. Check GPU usage: `nvidia-smi`
2. Monitor CPU: `top` or `htop`
3. Check network: `ping` between services
4. Review logs for errors

### Memory Leaks

```bash
# Monitor memory usage
pm2 monitor

# Enable node-inspector for debugging
node --inspect src/server.js
```

## 📝 Backup & Recovery

```bash
# Backup model files
tar -czf nilm-backup-$(date +%Y%m%d).tar.gz saved_models/

# Backup configuration
cp .env .env.backup

# Database backup (if using)
mysqldump -u root -p database > backup.sql
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy NILM API

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker images
        run: docker-compose build
      
      - name: Push to registry
        run: |
          docker tag nilm-api:latest myregistry/nilm-api:latest
          docker push myregistry/nilm-api:latest
      
      - name: Deploy to production
        run: |
          ssh user@server 'cd /app && docker-compose pull && docker-compose up -d'
```

## 📞 Support

For deployment issues:
1. Check logs: `docker-compose logs -f`
2. Test health endpoints
3. Verify environment variables
4. Check network connectivity
5. Consult the main README.md

---

**Happy Deploying!** 🚀
