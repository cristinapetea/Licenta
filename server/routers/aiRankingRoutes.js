// server/routes/aiRankingRoutes.js
const express = require('express');
const router = express.Router();
const { getAISystem } = require('../services/aiRanking');

// GET /api/ai-ranking?householdId=xxx
// Generează ranking cu AI
router.get('/', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const aiSystem = getAISystem();
    
    console.log('🤖 Generating AI-powered ranking...');
    const ranking = await aiSystem.generateRanking(householdId);
    
    res.json(ranking);
    
  } catch (error) {
    console.error('❌ AI Ranking error:', error);
    res.status(500).json({ 
      error: 'Failed to generate AI ranking',
      details: error.message 
    });
  }
});

// POST /api/ai-ranking/train
// Antrenează manual AI-ul (opțional)
router.post('/train', async (req, res) => {
  try {
    const { householdId } = req.body;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const aiSystem = getAISystem();
    
    console.log('🤖 Training AI...');
    const success = await aiSystem.train(householdId);
    
    if (!success) {
      return res.status(400).json({ 
        error: 'Not enough data to train AI',
        message: 'Need at least 5 tasks per member'
      });
    }
    
    res.json({ 
      message: 'AI trained successfully',
      trainedAt: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Training error:', error);
    res.status(500).json({ 
      error: 'Failed to train AI',
      details: error.message 
    });
  }
});

// GET /api/ai-ranking/predict/:memberId?householdId=xxx
// Prezice scorul pentru un singur membru
router.get('/predict/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const aiSystem = getAISystem();
    
    // Antrenăm mai întâi dacă nu e antrenat
    if (!aiSystem.isTrained) {
      await aiSystem.train(householdId);
    }
    
    const score = await aiSystem.predictScore(memberId, householdId);
    
    res.json({
      memberId,
      predictedScore: Math.round(score * 10) / 10,
      generatedBy: 'AI',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Prediction error:', error);
    res.status(500).json({ 
      error: 'Failed to predict score',
      details: error.message 
    });
  }
});

// GET /api/ai-ranking/compare?householdId=xxx
// Compară AI vs formula clasică
router.get('/compare', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const aiSystem = getAISystem();
    
    // Generăm ranking cu AI
    const aiRanking = await aiSystem.generateRanking(householdId);
    
    // Pentru comparație, ar trebui să ai și formula clasică
    // (poți importa din performanceRoutes.js)
    
    res.json({
      aiRanking,
      message: 'AI ranking generated. Import classic ranking for comparison.'
    });
    
  } catch (error) {
    console.error('❌ Comparison error:', error);
    res.status(500).json({ 
      error: 'Failed to compare rankings',
      details: error.message 
    });
  }
});

module.exports = router;