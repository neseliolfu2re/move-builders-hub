const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { MongoClient } = require('mongodb');
const { AptosClient, AptosAccount, FaucetClient } = require('aptos');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Aptos client setup
const NODE_URL = process.env.APTOS_NODE_URL || 'https://fullnode.testnet.aptoslabs.com/v1';
const FAUCET_URL = process.env.APTOS_FAUCET_URL || 'https://faucet.testnet.aptoslabs.com';
const aptosClient = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);

// MongoDB connection
let db;
MongoClient.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/movehub')
  .then(client => {
    console.log('Connected to MongoDB');
    db = client.db('movehub');
  })
  .catch(error => console.error('MongoDB connection error:', error));

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'https://movebuildershub.xyz',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

app.use(express.json());
app.use(express.static('public'));

// Routes

// Get user progress
app.get('/api/user-progress/:address', async (req, res) => {
  try {
    const { address } = req.params;
    
    // Validate address format
    if (!address || address.length !== 66) {
      return res.status(400).json({ error: 'Invalid wallet address' });
    }

    const user = await db.collection('users').findOne({ walletAddress: address });
    
    if (!user) {
      // Return default user data
      return res.json({
        walletAddress: address,
        quests: [],
        totalCompleted: 0,
        streak: 0,
        badges: [],
        joinedAt: new Date()
      });
    }

    res.json(user);
  } catch (error) {
    console.error('Error fetching user progress:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Complete quest
app.post('/api/complete-quest', async (req, res) => {
  try {
    const { walletAddress, questId, timestamp } = req.body;

    // Validate input
    if (!walletAddress || !questId || !timestamp) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Simulate on-chain transaction
    const txHash = await submitQuestToBlockchain(walletAddress, questId);

    // Update user progress in database
    const questData = {
      id: questId,
      completed: true,
      progress: 100,
      onChainTx: txHash,
      completedAt: new Date(timestamp)
    };

    await db.collection('users').updateOne(
      { walletAddress },
      { 
        $push: { quests: questData },
        $inc: { totalCompleted: 1 },
        $set: { lastActive: new Date() }
      },
      { upsert: true }
    );

    // Update global stats
    await db.collection('stats').updateOne(
      { type: 'global' },
      { 
        $inc: { 
          totalQuestsCompleted: 1,
          totalTransactions: 1 
        },
        $set: { lastUpdated: new Date() }
      },
      { upsert: true }
    );

    res.json({ 
      success: true, 
      txHash,
      message: 'Quest completed successfully!' 
    });

  } catch (error) {
    console.error('Error completing quest:', error);
    res.status(500).json({ error: 'Failed to complete quest' });
  }
});

// Get analytics data
app.get('/api/analytics', async (req, res) => {
  try {
    const stats = await db.collection('stats').findOne({ type: 'global' });
    const userCount = await db.collection('users').countDocuments();
    
    // Get recent activity
    const recentActivity = await db.collection('users').aggregate([
      { $unwind: '$quests' },
      { $sort: { 'quests.completedAt': -1 } },
      { $limit: 10 },
      { $project: {
        walletAddress: { $concat: [
          { $substr: ['$walletAddress', 0, 6] },
          '...',
          { $substr: ['$walletAddress', -4, 4] }
        ]},
        questId: '$quests.id',
        completedAt: '$quests.completedAt'
      }}
    ]).toArray();

    const analytics = {
      totalUsers: userCount,
      totalQuestsCompleted: stats?.totalQuestsCompleted || 0,
      totalTransactions: stats?.totalTransactions || 0,
      dailyActiveUsers: Math.floor(Math.random() * 20) + 35, // Simulated
      weeklyNewUsers: Math.floor(Math.random() * 10) + 8,   // Simulated
      recentActivity
    };

    res.json(analytics);
  } catch (error) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({ error: 'Failed to fetch analytics' });
  }
});

// Get leaderboard
app.get('/api/leaderboard', async (req, res) => {
  try {
    const leaderboard = await db.collection('users').aggregate([
      { $project: {
        walletAddress: { $concat: [
          { $substr: ['$walletAddress', 0, 6] },
          '...',
          { $substr: ['$walletAddress', -4, 4] }
        ]},
        totalCompleted: 1,
        streak: 1,
        lastActive: 1
      }},
      { $sort: { totalCompleted: -1, streak: -1 } },
      { $limit: 10 }
    ]).toArray();

    res.json(leaderboard);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

// Submit quest completion to blockchain
async function submitQuestToBlockchain(walletAddress, questId) {
  try {
    // In a real implementation, this would:
    // 1. Create a Move transaction
    // 2. Submit to Aptos blockchain
    // 3. Return actual transaction hash
    
    // For now, simulate with a realistic transaction hash
    const mockTxHash = '0x' + Array.from({length: 64}, () => 
      Math.floor(Math.random() * 16).toString(16)
    ).join('');
    
    console.log(`Quest ${questId} completed by ${walletAddress}, tx: ${mockTxHash}`);
    
    return mockTxHash;
  } catch (error) {
    console.error('Blockchain submission error:', error);
    throw error;
  }
}

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`🚀 Move Builders Hub API running on port ${PORT}`);
  console.log(`📊 Analytics: http://localhost:${PORT}/api/analytics`);
  console.log(`🏆 Leaderboard: http://localhost:${PORT}/api/leaderboard`);
});
