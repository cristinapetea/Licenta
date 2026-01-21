// server/routes/aiRoutes.js
const express = require('express');
const router = express.Router();
const { getAI } = require('../services/aiTaskPrediction');

// GET /api/ai/ranking?householdId=xxx
router.get('/ranking', async (req, res) => {
  try {
    const { householdId } = req.query;
    const ai = getAI();
    const ranking = await ai.generateRanking(householdId);
    res.json(ranking);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/ai/recommend
// Body: { taskTitle, points, dueDate, householdId }
router.post('/recommend', async (req, res) => {
  try {
    const { taskTitle, points, dueDate, householdId } = req.body;
    const ai = getAI();
    
    const recommendation = await ai.recommendMember(
      { title: taskTitle, points, dueDate },
      householdId
    );
    
    res.json(recommendation);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;