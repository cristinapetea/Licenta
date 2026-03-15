const router = require('express').Router();
const { Types } = require('mongoose');
const { Worker } = require('worker_threads');
const path = require('path');

const fakeAuth = (req, res, next) => {
  const id = req.headers['x-user'];
  if (!id || !Types.ObjectId.isValid(id)) {
    return res.status(401).json({ error: 'x-user header missing or invalid' });
  }
  req.user = { sub: id };
  next();
};

function runWorker(workerPath, workerData) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(workerPath, { workerData });
    worker.on('message', (message) => {
      message.success ? resolve(message.data) : reject(new Error(message.error || 'Worker failed'));
    });
    worker.on('error', reject);
    worker.on('exit', (code) => {
      if (code !== 0) reject(new Error(`Worker stopped with exit code ${code}`));
    });
  });
}

router.get('/ranking', fakeAuth, async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    console.log('📊 Getting ranking for household:', householdId);
    
    const workerPath = path.join(__dirname, '../workers/performance-worker.js');
    const fs = require('fs');
    
    if (!fs.existsSync(workerPath)) {
      console.warn('⚠️ Performance worker not found at:', workerPath);
      return res.json({
        members: [],
        message: 'Performance worker not implemented yet'
      });
    }
    
    console.log('🚀 Running performance worker...');
    const ranking = await runWorker(workerPath, { householdId });
    
    console.log('✅ Ranking generated with', ranking.members?.length || 0, 'members');
    res.json(ranking);
    
  } catch (err) {
    console.error('❌ Error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;