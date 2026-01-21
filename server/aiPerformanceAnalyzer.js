
require('dotenv').config();
const mongoose = require('mongoose');

const Task = require('./model/Task');
const User = require('./model/User');
const Household = require('./model/Household');


const HOUSEHOLD_ID = '691a1acbcc1ce7336613116d';

// Task type categories
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

// Normalize task title to category
function getTaskCategory(title) {
  for (const [category, titles] of Object.entries(TASK_CATEGORIES)) {
    if (titles.includes(title)) {
      return category;
    }
  }
  return 'other';
}

// Get human-readable category name
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
  
  // Weighted final score 
  const finalScore = (
    completionRate * 40 +
    onTimeRate * 30 +
    speedScore * 20 +
    consistencyScore * 10
  );
  
  return finalScore;
}



async function analyzeMemberPerformance(memberId, memberName) {
  console.log(`\n📊 Analyzing ${memberName}...`);
  
  // Get all tasks for this member
  const allTasks = await Task.find({
    household: HOUSEHOLD_ID,
    assignedTo: memberId
  }).sort({ createdAt: 1 });
  
  if (allTasks.length === 0) {
    console.log(`   No tasks found for ${memberName}`);
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
    memberId,
    memberName,
    totalTasks: allTasks.length,
    totalCompleted: allTasks.filter(t => t.status === 'completed').length,
    overallCompletionRate: Math.round((allTasks.filter(t => t.status === 'completed').length / allTasks.length) * 100),
    top3Strengths: top3,
    allCategories: categoryScores
  };
}

async function generateHouseholdRanking() {
  console.log('\n🏆 HOUSEHOLD PERFORMANCE RANKING');
  console.log('=====================================\n');
  
  
  const household = await Household.findById(HOUSEHOLD_ID).populate('members');
  
  if (!household) {
    console.error('❌ Household not found!');
    return;
  }
  
  const results = [];
  
  
  for (const member of household.members) {
    const analysis = await analyzeMemberPerformance(member._id, member.name);
    if (analysis) {
      results.push(analysis);
    }
  }
  
 
  results.sort((a, b) => b.overallCompletionRate - a.overallCompletionRate);
  
  
  console.log('\n📈 OVERALL RANKING:');
  console.log('─────────────────────────────────────\n');
  
  results.forEach((result, index) => {
    console.log(`${index + 1}. ${result.memberName}`);
    console.log(`   Overall: ${result.totalCompleted}/${result.totalTasks} tasks (${result.overallCompletionRate}%)`);
    console.log('');
  });
  
  console.log('\n⭐ TOP 3 STRENGTHS PER MEMBER:');
  console.log('─────────────────────────────────────\n');
  
  results.forEach(result => {
    console.log(`\n👤 ${result.memberName.toUpperCase()}`);
    console.log(`   Total tasks: ${result.totalCompleted}/${result.totalTasks} (${result.overallCompletionRate}%)`);
    console.log('');
    
    if (result.top3Strengths.length > 0) {
      result.top3Strengths.forEach((strength, idx) => {
        console.log(`   ${idx + 1}. ${strength.displayName}`);
        console.log(`      Score: ${strength.score}/100`);
        console.log(`      Tasks: ${strength.completed}/${strength.totalTasks} (${strength.completionRate}%)`);
        console.log(`      On-time: ${strength.onTime}/${strength.completed} (${strength.onTimeRate}%)`);
        console.log('');
      });
    } else {
      console.log('   Not enough data for analysis');
    }
  });
  
  return results;
}


const fs = require('fs');

async function saveAnalysisToFile(results) {
  const output = {
    generatedAt: new Date().toISOString(),
    householdId: HOUSEHOLD_ID,
    analysis: results
  };
  
  fs.writeFileSync('household-performance-analysis.json', JSON.stringify(output, null, 2));
  console.log('\n💾 Analysis saved to: household-performance-analysis.json\n');
}


async function main() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    
    if (!mongoUri) {
      console.error('ERROR: MONGO_URI not found in .env file!');
      process.exit(1);
    }
    
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');
    
   
    const results = await generateHouseholdRanking();
    
    if (results && results.length > 0) {
      await saveAnalysisToFile(results);
    }
    
    console.log('\n✨ Analysis complete!\n');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
}


main();