// workers/performance-worker.js
const { parentPort, workerData } = require('worker_threads');
const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Task = require('../model/Task');
const Household = require('../model/Household');
const User = require('../model/User');

// ⭐ Funcțiile tale de analiză (copiază din analyze-performance.js)
function calculatePerformanceScore(tasks) {
  if (tasks.length === 0) return 0;

  const completed = tasks.filter(t => t.status === 'completed');
  const completedOnTime = completed.filter(t => t.completedOnTime === true);
  
  const completionRate = completed.length / tasks.length;
  const onTimeRate = completed.length > 0 ? completedOnTime.length / completed.length : 0;
  
  let speedScore = 0;
  if (completed.length > 0) {
    const speedScores = completed
      .filter(t => t.timeToComplete && t.completedOnTime)
      .map(t => {
        const hoursToComplete = t.timeToComplete / 60;
        return Math.max(0, 1 - (hoursToComplete / 48)); 
      });
    
    speedScore = speedScores.length > 0
      ? speedScores.reduce((a, b) => a + b, 0) / speedScores.length
      : 0;
  }
  
  let consistencyScore = 0;
  if (tasks.length >= 4) {
    const chunks = 4;
    const chunkSize = Math.floor(tasks.length / chunks);
    const chunkRates = [];
    
    for (let i = 0; i < chunks; i++) {
      const start = i * chunkSize;
      const end = (i === chunks - 1) ? tasks.length : start + chunkSize;
      const chunkTasks = tasks.slice(start, end);
      const chunkCompleted = chunkTasks.filter(t => t.status === 'completed').length;
      chunkRates.push(chunkCompleted / chunkTasks.length);
    }
    
    const mean = chunkRates.reduce((a, b) => a + b, 0) / chunkRates.length;
    const variance = chunkRates.reduce((sum, rate) => sum + Math.pow(rate - mean, 2), 0) / chunkRates.length;
    consistencyScore = Math.max(0, 1 - (variance * 2));
  }
  
  const finalScore = (
    completionRate * 40 +
    onTimeRate * 30 +
    speedScore * 20 +
    consistencyScore * 10
  );
  
  return finalScore;
}

function getTaskCategory(title) {
  const TASK_CATEGORIES = {
    shopping: ['Grocery shopping Lidl', 'Shopping at Kaufland', 'Farmers market', 'Weekly groceries'],
    trash: ['Take out trash', 'Empty trash bins', 'Take out recycling'],
    vacuum: ['Vacuum living room', 'Vacuum bedroom', 'Vacuum entire house'],
    dust: ['Dust surfaces', 'Dust and vacuum', 'Clean surfaces'],
    windows: ['Clean living room windows', 'Clean all windows'],
    bathroom: ['Clean bathroom', 'Bathroom and toilet'],
    dishwasher_start: ['Start dishwasher', 'Load dishwasher'],
    dishwasher_unload: ['Unload dishwasher', 'Empty dishwasher'],
    breakfast: ['Prepare breakfast', 'Make breakfast'],
    lunch: ['Cook lunch', 'Prepare lunch'],
    dinner: ['Cook dinner', 'Prepare dinner'],
    laundry_start: ['Start laundry', 'Run washing machine'],
    laundry_hang: ['Hang laundry to dry', 'Take out laundry']
  };
  
  for (const [category, titles] of Object.entries(TASK_CATEGORIES)) {
    if (titles.includes(title)) {
      return category;
    }
  }
  return 'other';
}

function getCategoryDisplayName(category) {
  const names = {
    shopping: 'Shopping',
    trash: 'Taking out trash',
    vacuum: 'Vacuuming',
    dust: 'Dusting',
    windows: 'Cleaning windows',
    bathroom: 'Cleaning bathroom',
    dishwasher_start: 'Starting dishwasher',
    dishwasher_unload: 'Unloading dishwasher',
    breakfast: 'Preparing breakfast',
    lunch: 'Cooking lunch',
    dinner: 'Cooking dinner',
    laundry_start: 'Starting laundry',
    laundry_hang: 'Hanging laundry',
    other: 'Other tasks'
  };
  return names[category] || category;
}

async function analyzeMemberPerformance(memberId, memberName, householdId) {
  const allTasks = await Task.find({
    household: householdId,
    assignedTo: memberId
  }).sort({ createdAt: 1 });
  
  if (allTasks.length === 0) {
    return null;
  }
  
  const tasksByCategory = {};
  
  allTasks.forEach(task => {
    const category = getTaskCategory(task.title);
    if (!tasksByCategory[category]) {
      tasksByCategory[category] = [];
    }
    tasksByCategory[category].push(task);
  });
  
  const categoryScores = [];
  
  for (const [category, tasks] of Object.entries(tasksByCategory)) {
    if (tasks.length < 3) continue;
    
    const score = calculatePerformanceScore(tasks);
    const completed = tasks.filter(t => t.status === 'completed').length;
    const onTime = tasks.filter(t => t.completedOnTime === true).length;
    
    categoryScores.push({
      category,
      displayName: getCategoryDisplayName(category),
      score: Math.round(score * 10) / 10,
      totalTasks: tasks.length,
      completed,
      completionRate: Math.round((completed / tasks.length) * 100),
      onTime,
      onTimeRate: completed > 0 ? Math.round((onTime / completed) * 100) : 0
    });
  }
  
  categoryScores.sort((a, b) => b.score - a.score);
  const top3 = categoryScores.slice(0, 3);
  
  return {
    memberId: memberId.toString(),  // ✅ Convertește ObjectId la string!
    memberName,
    totalTasks: allTasks.length,
    totalCompleted: allTasks.filter(t => t.status === 'completed').length,
    overallCompletionRate: Math.round((allTasks.filter(t => t.status === 'completed').length / allTasks.length) * 100),
    top3Strengths: top3,
    allCategories: categoryScores
  };
}

// ⭐⭐⭐ LOGICA PRINCIPALĂ - RULEAZĂ ÎN BACKGROUND! ⭐⭐⭐
async function run() {
  try {
    console.log('🔧 Worker started with data:', workerData);
    
    // Conectare la MongoDB
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    console.log('✅ Worker connected to MongoDB');
    
    const { householdId } = workerData;
    
    // Găsește household-ul
    const household = await Household.findById(householdId).populate('members');
    
    if (!household) {
      throw new Error('Household not found');
    }
    
    const results = [];
    
    // Analizează fiecare membru
    for (const member of household.members) {
      const analysis = await analyzeMemberPerformance(member._id, member.name, householdId);
      if (analysis) {
        results.push(analysis);
      }
    }
    
    // Sortează după completion rate
    results.sort((a, b) => b.overallCompletionRate - a.overallCompletionRate);
    
    // Adaugă rank
    results.forEach((result, index) => {
      result.rank = index + 1;
    });
    
    console.log('✅ Worker finished analysis');
    
    // ⭐ Trimite rezultatele înapoi la main thread
    parentPort.postMessage({ 
      success: true, 
      data: { members: results } 
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

// Rulează!
run();