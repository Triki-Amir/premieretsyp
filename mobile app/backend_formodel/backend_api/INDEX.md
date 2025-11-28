# NILM Backend API - INDEX & START HERE 🚀

Welcome! This is your complete NILM (Non-Intrusive Load Monitoring) backend API. Let's get you started!

## 📖 Where to Start?

### I want to... 👇

#### **Get it running ASAP** ⚡
→ Read: **QUICK_REFERENCE.md** (5 min read)

#### **Set up properly** 🔧
→ Read: **SETUP.md** (15 min setup)

#### **Understand how it works** 🤔
→ Read: **VISUAL_OVERVIEW.md** (10 min read)

#### **Use the API** 💻
→ Read: **README.md** (full documentation)

#### **See code examples** 💡
→ Read: **API_EXAMPLES.md** (copy-paste ready)

#### **Deploy to production** 🚀
→ Read: **DEPLOYMENT.md** (production guide)

#### **Quick decision reference** 📋
→ Read: **QUICK_REFERENCE.md** (cheat sheet)

#### **Project overview** 📊
→ Read: **PROJECT_SUMMARY.md** (architecture)

---

## ⚡ Quick Start (Choose One)

### Option A: Windows Automated Setup (Easiest)
```batch
cd backend_api
setup.bat
```
Then follow the on-screen instructions.

### Option B: macOS/Linux Automated Setup
```bash
cd backend_api
bash setup.sh
```

### Option C: Manual Setup
See **SETUP.md** for step-by-step instructions.

---

## 📚 Documentation Files

| File | Purpose | Read Time | Who Should Read |
|------|---------|-----------|-----------------|
| **QUICK_REFERENCE.md** | 30-second start guide & cheat sheet | 5 min | Everyone |
| **SETUP.md** | Complete installation guide | 15 min | First-time setup |
| **README.md** | Full API documentation | 20 min | API users |
| **VISUAL_OVERVIEW.md** | Architecture & flow diagrams | 10 min | Want to understand system |
| **API_EXAMPLES.md** | Code examples (cURL, Python, JS) | 10 min | Ready to integrate |
| **DEPLOYMENT.md** | Production deployment strategies | 15 min | Going live |
| **PROJECT_SUMMARY.md** | Project overview & features | 10 min | Project managers |
| **INDEX.md** | This file - navigation guide | 5 min | Getting oriented |

---

## 🎯 Common Scenarios

### Scenario 1: I just want to test it locally 🧪

1. Read: **QUICK_REFERENCE.md**
2. Run: `setup.bat` or `bash setup.sh`
3. Follow 30-second start guide
4. Test: `curl http://localhost:3000/api/health`

**Time**: ~15 minutes

### Scenario 2: I want to understand the system first 🔍

1. Read: **VISUAL_OVERVIEW.md** (understand architecture)
2. Read: **SETUP.md** (understand setup process)
3. Run: setup scripts and start services
4. Read: **README.md** (understand API)
5. Try: Examples from **API_EXAMPLES.md**

**Time**: ~45 minutes

### Scenario 3: I need to integrate with my mobile app 📱

1. Read: **README.md** (API endpoints & format)
2. Read: **API_EXAMPLES.md** (see request/response format)
3. Follow: Integration code for your language
4. Use: The `/api/predict` endpoint
5. Run: Backend services (setup.bat or setup.sh)

**Time**: ~30 minutes

### Scenario 4: I'm deploying to production 🚀

1. Read: **DEPLOYMENT.md** (all deployment options)
2. Choose: Your deployment strategy (Docker, AWS, local, etc.)
3. Configure: `.env` for production
4. Test: All endpoints before going live
5. Monitor: Set up logging & health checks

**Time**: Varies by strategy

---

## 🗂️ Project Structure Overview

```
backend_api/          ← You are here
├── src/              ← Express API code
├── python_service/   ← Flask model service
├── config/           ← Configuration files
├── *.md              ← Documentation (you're reading it!)
├── package.json      ← Node dependencies
└── .env              ← Your configuration
```

---

## ✅ Pre-flight Checklist

Before starting, verify you have:

- [ ] Node.js 16+ installed? Check: `node --version`
- [ ] Python 3.9+ installed? Check: `python --version`
- [ ] Ports 3000 and 5000 available?
- [ ] Model files exist? Check: `../NILM_SIDED/saved_models/`
- [ ] At least 4GB RAM available
- [ ] Git or file access to this directory

---

## 🚀 Three Steps to Running

### Step 1: Setup (5-10 minutes)
```bash
cd backend_api
setup.bat          # Windows
# or
bash setup.sh      # macOS/Linux
```

### Step 2: Start Services (2 terminals)
```bash
# Terminal 1: Python Service
cd python_service
venv\Scripts\activate    # Windows
python model_service.py

# Terminal 2: Express API
npm start
```

### Step 3: Test It
```bash
# Terminal 3: Test
curl http://localhost:3000/api/health
```

**Time Total**: ~15 minutes

---

## 📡 What This Backend Does

```
Your Mobile App (Flutter)
        ↓ (Sends 288 power readings)
Express API Server (Node.js)
        ↓ (Validates & forwards)
Flask Service (Python)
        ↓ (Runs AI model)
Predictions (5 appliances)
        ↓ (Returns to app)
User sees energy breakdown
```

---

## 🎓 Learning Path

**Day 1 - Get It Running**
1. Read QUICK_REFERENCE.md
2. Run setup.bat / setup.sh
3. Start services
4. Test /api/health endpoint

**Day 2 - Use The API**
1. Read README.md
2. Read API_EXAMPLES.md
3. Try making predictions manually
4. Test with curl/Postman

**Day 3 - Integrate With App**
1. Read integration section in README.md
2. Add API calls to your mobile app
3. Test with real data
4. Deploy!

---

## 🔧 If Something Goes Wrong

### Issue: Services won't start?
→ See: QUICK_REFERENCE.md → Troubleshooting section

### Issue: API not responding?
→ Check: Both services are running in separate terminals

### Issue: Validation errors?
→ See: README.md → Input Constraints section

### Issue: Need production setup?
→ Read: DEPLOYMENT.md

### Issue: Want to debug?
→ Check: Set LOG_LEVEL=debug in .env

---

## 📋 Checklist: Am I Ready to Integrate?

After following setup:

- [ ] `npm start` runs without errors
- [ ] `python model_service.py` runs without errors
- [ ] `curl http://localhost:3000/api/health` returns 200
- [ ] `curl http://localhost:3000/api/status` shows "operational"
- [ ] I can POST to `/api/predict` and get predictions back
- [ ] Predictions have 5 appliances (EVSE, PV, CS, CHP, BA)

If all checked ✅, you're ready to integrate with your mobile app!

---

## 🎯 Next Steps

### I've read everything and I'm ready!

1. **Start the services** (follow Quick Start section)
2. **Test the API** (see QUICK_REFERENCE.md)
3. **Read README.md** for detailed API documentation
4. **Integrate with mobile app** (see README.md integration section)
5. **Deploy to production** when ready (see DEPLOYMENT.md)

### I want more info on...

- **API Endpoints?** → README.md
- **Code Examples?** → API_EXAMPLES.md
- **Architecture?** → VISUAL_OVERVIEW.md
- **Production?** → DEPLOYMENT.md
- **Troubleshooting?** → QUICK_REFERENCE.md

---

## 🆘 Need Help?

1. **Check logs** - Both services print logs to console
2. **Read relevant doc** - Find your scenario above
3. **Test endpoints** - Use curl to test directly
4. **Verify setup** - Follow SETUP.md exactly
5. **Check ports** - Ensure 3000 & 5000 are free

---

## 📊 Project Status

✅ **Complete & Ready to Use**

- ✅ All files created
- ✅ Dependencies configured
- ✅ Documentation complete
- ✅ Examples provided
- ✅ Tests included
- ✅ Deployment options available

---

## 🎉 You're All Set!

Everything you need is here. Start with:

1. **QUICK_REFERENCE.md** (5 min overview)
2. **SETUP.md** (installation)
3. **README.md** (API usage)
4. **API_EXAMPLES.md** (code samples)

Then you're ready to integrate with your mobile app!

---

## 📚 Quick Links

| What I Need | File to Read |
|------------|---------|
| Fast start | QUICK_REFERENCE.md |
| Setup guide | SETUP.md |
| API docs | README.md |
| Code examples | API_EXAMPLES.md |
| Understand system | VISUAL_OVERVIEW.md |
| Deploy to prod | DEPLOYMENT.md |
| Project overview | PROJECT_SUMMARY.md |

---

## 🚀 Ready?

Pick a documentation file above and start reading!

**Most people start with**: QUICK_REFERENCE.md or SETUP.md

Happy coding! 🎉
