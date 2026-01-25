// server/routes/aiRoutes.js
const express = require('express');
const router = express.Router();
const { getAI } = require('../services/aiTaskPrediction');

// GET /api/ai/ranking?householdId=xxx
router.get('/ranking', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const ai = getAI();
    const ranking = await ai.generateRanking(householdId);
    
    res.json(ranking);
  } catch (err) {
    console.error('❌ Error generating ranking:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/ai/recommend
// Body: { taskTitle, points, dueDate, householdId }
router.post('/recommend', async (req, res) => {
  try {
    const { taskTitle, points, dueDate, householdId } = req.body;
    
    if (!taskTitle || !householdId) {
      return res.status(400).json({ 
        error: 'taskTitle and householdId are required' 
      });
    }
    
    const ai = getAI();
    
    const recommendation = await ai.recommendMember(
      { title: taskTitle, points, dueDate },
      householdId
    );
    
    res.json(recommendation);
  } catch (err) {
    console.error('❌ Error recommending member:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/ai/train
// Body: { householdId }
router.post('/train', async (req, res) => {
  try {
    const { householdId } = req.body;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const ai = getAI();
    const stats = await ai.train(householdId);
    
    res.json({
      success: true,
      message: 'AI trained successfully',
      stats
    });
  } catch (err) {
    console.error('❌ Error training AI:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;