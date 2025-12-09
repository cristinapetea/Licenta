// routes/performanceRoutes.js
// Add this to your Express backend

const express = require('express');
const router = express.Router();
const Task = require('../model/Task');
const Household = require('../model/Household');

// Task type categories mapping
const TASK_CATEGORIES = {
  shopping: ['Grocery shopping Lidl', 'Shopping at Kaufland', 'Farmers market', 'Weekly groceries'],
  trash: ['Take out trash', 'Empty trash bins', 'Take out recycling', 'Take out glass'],
  vacuum: ['Vacuum living room', 'Vacuum bedroom', 'Vacuum entire house'],
  dust: ['Dust surfaces', 'Dust and vacuum', 'Clean surfaces'],
  windows: ['Clean living room windows', 'Clean all windows', 'Windows and mirrors'],
  bathroom: ['Clean bathroom', 'Bathroom and toilet', 'Deep clean bathroom'],
  dishwasher_start: ['Start dishwasher', 'Load dishwasher', 'Run dishwasher'],
  dishwasher_unload: ['Unload dishwasher', 'Empty dishwasher', 'Put dishes away'],
  breakfast: ['Prepare breakfast', 'Make breakfast', 'Coffee and breakfast'],
  lunch: ['Cook lunch', 'Prepare lunch', 'Make lunch'],
  dinner: ['Cook dinner', 'Prepare dinner', 'Make dinner'],
  laundry_start: ['Start laundry', 'Run washing machine', 'Do laundry'],
  laundry_hang: ['Hang laundry to dry', 'Take out laundry', 'Hang clothes']
};

const CATEGORY_DISPLAY_NAMES = {
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

function getTaskCategory(title) {
  for (const [category, titles] of Object.entries(TASK_CATEGORIES)) {
    if (titles.includes(title)) {
      return category;
    }
  }
  return 'other';
}

function calculatePerformanceScore(tasks) {
  if (tasks.length === 0) return 0;

  const completed = tasks.filter(t => t.status === 'completed');
  const completedOnTime = completed.filter(t => t.completedOnTime === true);
  
  // Metric 1: Completion Rate (40% weight)
  const completionRate = completed.length / tasks.length;
  
  // Metric 2: On-Time Rate (30% weight)
  const onTimeRate = completed.length > 0 
    ? completedOnTime.length / completed.length 
    : 0;
  
  // Metric 3: Speed Efficiency (20% weight)
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
  
  // Metric 4: Consistency (10% weight)
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
  
  // Weighted final score (0-100)
  const finalScore = (
    completionRate * 40 +
    onTimeRate * 30 +
    speedScore * 20 +
    consistencyScore * 10
  );
  
  return finalScore;
}

async function analyzeMemberPerformance(memberId, memberName, householdId) {
  const allTasks = await Task.find({
    household: householdId,
    assignedTo: memberId
  }).sort({ createdAt: 1 });
  
  if (allTasks.length === 0) {
    return null;
  }
  
  // Group tasks by category
  const tasksByCategory = {};
  
  allTasks.forEach(task => {
    const category = getTaskCategory(task.title);
    if (!tasksByCategory[category]) {
      tasksByCategory[category] = [];
    }
    tasksByCategory[category].push(task);
  });
  
  // Calculate performance score for each category
  const categoryScores = [];
  
  for (const [category, tasks] of Object.entries(tasksByCategory)) {
    if (tasks.length < 3) continue;
    
    const score = calculatePerformanceScore(tasks);
    const completed = tasks.filter(t => t.status === 'completed').length;
    const onTime = tasks.filter(t => t.completedOnTime === true).length;
    
    categoryScores.push({
      category,
      displayName: CATEGORY_DISPLAY_NAMES[category] || category,
      score: Math.round(score * 10) / 10,
      totalTasks: tasks.length,
      completed,
      completionRate: Math.round((completed / tasks.length) * 100),
      onTime,
      onTimeRate: completed > 0 ? Math.round((onTime / completed) * 100) : 0
    });
  }
  
  // Sort by score (descending)
  categoryScores.sort((a, b) => b.score - a.score);
  
  // Get top 3
  const top3 = categoryScores.slice(0, 3);
  
  const totalCompleted = allTasks.filter(t => t.status === 'completed').length;
  
  return {
    memberId: memberId.toString(),
    memberName,
    totalTasks: allTasks.length,
    totalCompleted,
    overallCompletionRate: Math.round((totalCompleted / allTasks.length) * 100),
    top3Strengths: top3,
    allCategories: categoryScores
  };
}

// GET /api/performance/ranking?householdId=xxx
router.get('/ranking', async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const household = await Household.findById(householdId).populate('members');
    
    if (!household) {
      return res.status(404).json({ error: 'Household not found' });
    }
    
    const results = [];
    
    // Analyze each member
    for (const member of household.members) {
      const analysis = await analyzeMemberPerformance(
        member._id, 
        member.name, 
        householdId
      );
      if (analysis) {
        results.push(analysis);
      }
    }
    
    // Sort by overall completion rate
    results.sort((a, b) => b.overallCompletionRate - a.overallCompletionRate);
    
    // Add rank
    results.forEach((result, index) => {
      result.rank = index + 1;
    });
    
    res.json({
      householdId,
      householdName: household.name,
      members: results,
      generatedAt: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Error generating ranking:', error);
    res.status(500).json({ error: 'Failed to generate ranking' });
  }
});

// GET /api/performance/member/:memberId?householdId=xxx
router.get('/member/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    const household = await Household.findById(householdId).populate('members');
    
    if (!household) {
      return res.status(404).json({ error: 'Household not found' });
    }
    
    const member = household.members.find(m => m._id.toString() === memberId);
    
    if (!member) {
      return res.status(404).json({ error: 'Member not found in household' });
    }
    
    const analysis = await analyzeMemberPerformance(
      member._id,
      member.name,
      householdId
    );
    
    if (!analysis) {
      return res.status(404).json({ error: 'No data available for this member' });
    }
    
    res.json(analysis);
    
  } catch (error) {
    console.error('Error analyzing member:', error);
    res.status(500).json({ error: 'Failed to analyze member performance' });
  }
});

module.exports = router;