// server/controller/performance.controller.js
const { Worker } = require('worker_threads');
const path = require('path');

function runWorker(workerPath, workerData) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(workerPath, { workerData });
    worker.on('message', (msg) => msg.success ? resolve(msg.data) : reject(new Error(msg.error)));
    worker.on('error', reject);
  });
}

exports.getRanking = async (req, res) => {
  try {
    const { householdId } = req.query;
    if (!householdId) return res.status(400).json({ error: 'householdId required' });
    
    const ranking = await runWorker(
      path.join(__dirname, '../workers/performance-worker.js'),
      { householdId }
    );
    
    res.json(ranking);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};