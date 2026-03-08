// server/workers/ai-training-worker.js
const { parentPort, workerData } = require('worker_threads');
const mongoose = require('mongoose');
require('dotenv').config();

async function trainAI() {
  try {
    console.log('🔧 AI Training Worker started on SEPARATE THREAD');
    
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    
    const { getAI } = require('../services/aiTaskPrediction');
    const ai = getAI();
    
    const { householdId } = workerData;
    
    console.log('🧠 Training AI on BACKGROUND THREAD...');
    console.time('AI Training');
    
    const stats = await ai.train(householdId);
    
    console.timeEnd('AI Training');
    console.log('✅ AI Training completed on BACKGROUND THREAD');
    
    parentPort.postMessage({ 
      success: true, 
      data: stats 
    });
    
  } catch (error) {
    console.error('❌ Worker error:', error);
    parentPort.postMessage({ 
      success: false, 
      error: error.message 
    });
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

trainAI();