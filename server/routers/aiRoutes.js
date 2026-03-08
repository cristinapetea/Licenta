// server/routers/aiRoutes.js
const express = require('express');
const router = express.Router();
const { Worker } = require('worker_threads');
const path = require('path');
const { getAI } = require('../services/aiTaskPrediction');

// ⭐⭐⭐ HELPER: Rulează worker și returnează Promise ⭐⭐⭐
function runWorker(workerPath, workerData) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(workerPath, { workerData });
    
    worker.on('message', (message) => {
      if (message.success) {
        resolve(message.data);
      } else {
        reject(new Error(message.error || 'Worker failed'));
      }
    });
    
    worker.on('error', (error) => {
      reject(error);
    });
    
    worker.on('exit', (code) => {
      if (code !== 0) {
        reject(new Error(`Worker stopped with exit code ${code}`));
      }
    });
  });
}

// ⭐ GET /api/ai/ranking?householdId=xxx
// RULEAZĂ PE BACKGROUND THREAD - NU BLOCHEAZĂ SERVER-UL!
router.get('/ranking', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    console.log('🚀 Starting ranking analysis on WORKER THREAD...');
    
    const workerPath = path.join(__dirname, '../workers/performance-worker.js');
    const fs = require('fs');
    
    // Verifică dacă worker-ul există
    if (!fs.existsSync(workerPath)) {
      console.warn('⚠️ Performance worker not found, returning mock data');
      return res.json({
        members: [],
        message: 'Performance worker not implemented yet'
      });
    }
    
    // ⭐ Rulează worker-ul în background
    const ranking = await runWorker(workerPath, { householdId });
    
    console.log('✅ Ranking analysis completed');
    res.json(ranking);
    
  } catch (err) {
    console.error('❌ Error generating ranking:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ⭐ POST /api/ai/recommend
// Body: { taskTitle, points, dueDate, householdId }
// RULEAZĂ PE BACKGROUND THREAD!
router.post('/recommend', async (req, res) => {
  try {
    const { taskTitle, points, dueDate, householdId } = req.body;
    
    if (!taskTitle || !householdId) {
      return res.status(400).json({ 
        error: 'taskTitle and householdId are required' 
      });
    }
    
    console.log('🚀 Starting member recommendation...');
    
    const workerPath = path.join(__dirname, '../workers/recommendation-worker.js');
    const fs = require('fs');
    
    // Verifică dacă worker-ul există
    if (!fs.existsSync(workerPath)) {
      console.warn('⚠️ Recommendation worker not found, using direct AI service');
      
      // Fallback: folosește service-ul direct (temporar)
      const ai = getAI();
      const recommendation = await ai.recommendMember(
        { title: taskTitle, points, dueDate },
        householdId
      );
      
      return res.json(recommendation);
    }
    
    // ⭐ Rulează worker-ul în background
    const recommendation = await runWorker(workerPath, {
      task: { title: taskTitle, points, dueDate },
      householdId
    });
    
    console.log('✅ Recommendation completed');
    res.json(recommendation);
    
  } catch (err) {
    console.error('❌ Error recommending member:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ⭐⭐⭐ POST /api/ai/train
// Body: { householdId }
// RULEAZĂ PE BACKGROUND THREAD - NU BLOCHEAZĂ APLICAȚIA!
router.post('/train', async (req, res) => {
  try {
    const { householdId } = req.body;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    console.log('🚀 Starting AI training on WORKER THREAD...');
    
    const workerPath = path.join(__dirname, '../workers/ai-training-worker.js');
    const fs = require('fs');
    
    // Verifică dacă worker-ul există
    if (!fs.existsSync(workerPath)) {
      console.warn('⚠️ AI training worker not found');
      
      // OPȚIUNEA A: Răspunde imediat, training în background pe main thread (suboptimal)
      res.json({
        success: true,
        message: 'Training started (worker not implemented, running on main thread)',
        status: 'processing'
      });
      
      // Training asincron (dar tot pe main thread)
      setImmediate(async () => {
        try {
          const ai = getAI();
          const stats = await ai.train(householdId);
          console.log('✅ Training completed:', stats);
        } catch (err) {
          console.error('❌ Training error:', err);
        }
      });
      
      return;
    }
    
    // OPȚIUNEA B: Fire-and-forget (recomandată pentru training lung)
    // Răspunde IMEDIAT, worker-ul rulează în background
    res.json({
      success: true,
      message: 'AI training started on background thread',
      status: 'processing'
    });
    
    // ⭐ Pornește worker-ul (NON-BLOCKING pentru alte request-uri!)
    const worker = new Worker(workerPath, { 
      workerData: { householdId } 
    });
    
    worker.on('message', (message) => {
      if (message.success) {
        console.log('✅ AI training completed on WORKER THREAD:', message.data);
      } else {
        console.error('❌ AI training failed:', message.error);
      }
    });
    
    worker.on('error', (error) => {
      console.error('❌ Worker error:', error);
    });
    
    worker.on('exit', (code) => {
      if (code !== 0) {
        console.error(`⚠️ Worker stopped with exit code ${code}`);
      }
    });
    
    // OPȚIUNEA C: Așteaptă rezultatul (worker-ul tot rulează separat!)
    // Alte request-uri NU sunt blocate, doar acest request așteaptă
    // const stats = await runWorker(workerPath, { householdId });
    // res.json({
    //   success: true,
    //   message: 'AI trained successfully',
    //   stats
    // });
    
  } catch (err) {
    console.error('❌ Error training AI:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;