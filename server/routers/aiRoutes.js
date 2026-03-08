const express = require('express');
const router = express.Router();
const { Worker } = require('worker_threads');
const path = require('path');
const { getAI } = require('../services/aiTaskPrediction');

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

router.get('/ranking', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const workerPath = path.join(__dirname, '../workers/performance-worker.js');
    const fs = require('fs');
    
    if (!fs.existsSync(workerPath)) {
      return res.json({
        members: [],
        message: 'Performance worker not implemented yet'
      });
    }
    
    const ranking = await runWorker(workerPath, { householdId });
    res.json(ranking);
    
  } catch (err) {
    console.error('Error generating ranking:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/recommend', async (req, res) => {
  try {
    const { taskTitle, points, dueDate, householdId } = req.body;
    
    if (!taskTitle || !householdId) {
      return res.status(400).json({ 
        error: 'taskTitle and householdId are required' 
      });
    }
    
    const workerPath = path.join(__dirname, '../workers/recommendation-worker.js');
    const fs = require('fs');
    
    if (!fs.existsSync(workerPath)) {
      const ai = getAI();
      const recommendation = await ai.recommendMember(
        { title: taskTitle, points, dueDate },
        householdId
      );
      return res.json(recommendation);
    }
    
    const recommendation = await runWorker(workerPath, {
      task: { title: taskTitle, points, dueDate },
      householdId
    });
    
    res.json(recommendation);
    
  } catch (err) {
    console.error('Error recommending member:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/train', async (req, res) => {
  try {
    const { householdId } = req.body;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const workerPath = path.join(__dirname, '../workers/ai-training-worker.js');
    const fs = require('fs');
    
    if (!fs.existsSync(workerPath)) {
      res.json({
        success: true,
        message: 'Training started',
        status: 'processing'
      });
      
      setImmediate(async () => {
        try {
          const ai = getAI();
          await ai.train(householdId);
        } catch (err) {
          console.error('Training error:', err);
        }
      });
      
      return;
    }
    
    res.json({
      success: true,
      message: 'AI training started on background thread',
      status: 'processing'
    });
    
    const worker = new Worker(workerPath, { workerData: { householdId } });
    
    worker.on('message', (message) => {
      if (message.success) {
        console.log('Training completed');
      }
    });
    
    worker.on('error', (error) => {
      console.error('Worker error:', error);
    });
    
  } catch (err) {
    console.error('Error training AI:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/parse-shopping-list', async (req, res) => {
  try {
    const { spokenText } = req.body;
    
    if (!spokenText) {
      return res.status(400).json({ error: 'spokenText is required' });
    }
    
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
        max_tokens: 1024,
        messages: [{
          role: 'user',
          content: `You are a shopping list parser. Extract items from Romanian voice input. Return ONLY a valid JSON array of strings, nothing else.

CRITICAL: These are NOT items, remove them completely:
- "vreau să cumpar", "vreau sa cumpar", "vreau"
- "îmi trebuie", "imi trebuie"
- "mai trebuie", "mai vreau"
- "aș mai vrea", "as mai vrea"
- "și mai", "si mai"
- Any standalone "aș", "as", "și", "si"

Rules:
1. Separate on: "și", "si", commas, "plus", "cu"
2. Numbers: "două"→"2", "trei"→"3", "patru"→"4", etc.
3. Units: "kilograme"→"kg", "grame"→"g", "litri"→"l"
4. Capitalize first letter
5. Detect quantities: "2 kg mere 3 l lapte" = ["2 kg mere", "3 l lapte"]

Examples:
Input: "vreau să cumpar două kg mere și 500 grame zahăr"
Output: ["2 kg mere", "500 g zahăr"]

Input: "2 kg mere aș mai vrea și pâine și ouă"
Output: ["2 kg mere", "Pâine", "Ouă"]

Input: "lapte și brânză aș mai vrea și unt"
Output: ["Lapte", "Brânză", "Unt"]

Input: "2 kg cartofi 3 l apă 500 g făină 2 l de suc 1 calculator 2 baxuri de bere 1 uscător de păr"
Output: ["2 kg cartofi", "3 l apă", "500 g făină", "2 l suc", "1 calculator", "2 baxuri bere", "1 uscător de păr"]

Now parse: "${spokenText}"

Return ONLY the JSON array, no markdown, no explanation:`
        }]
      })
    });
    
    if (!response.ok) {
      throw new Error(`Claude API failed: ${response.status}`);
    }
    
    const data = await response.json();
    const itemsText = data.content[0].text.trim();
    const cleanedText = itemsText.replace(/```json\n?|\n?```/g, '').trim();
    const items = JSON.parse(cleanedText);
    
    res.json({ items });
    
  } catch (err) {
    console.error('Error parsing shopping list:', err.message);
    
    const fallbackItems = req.body.spokenText
      .split(/\s+și\s+|\s+si\s+|,\s*/i)
      .map(s => s.trim())
      .filter(s => s.length > 2)
      .map(s => s[0].toUpperCase() + s.substring(1));
    
    res.json({ items: fallbackItems });
  }
});

module.exports = router;