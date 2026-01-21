const brain = require('brain.js');
const Task = require('../model/Task');
const Household = require('../model/Household');

// CATEGORIES MAPPING 
const CATEGORIES = {
  'shopping': 0.1,
  'cleaning': 0.2,
  'cooking': 0.3,
  'laundry': 0.4,
  'dishes': 0.5,
  'trash': 0.6,
  'other': 0.7
};

function categorizeTask(title) {
  const lower = title.toLowerCase();
  if (lower.includes('shop') || lower.includes('buy')) return 'shopping';
  if (lower.includes('clean') || lower.includes('vacuum') || lower.includes('dust')) return 'cleaning';
  if (lower.includes('cook') || lower.includes('meal') || lower.includes('dinner')) return 'cooking';
  if (lower.includes('laundry') || lower.includes('wash')) return 'laundry';
  if (lower.includes('dish') || lower.includes('plates')) return 'dishes';
  if (lower.includes('trash') || lower.includes('garbage')) return 'trash';
  return 'other';
}

// EXTRAGERE FEATURES - o sa am 9 la final

function extractTaskFeatures(task, memberStats) {
  const createdAt = new Date(task.createdAt);
  const category = categorizeTask(task.title);
  
  return {
    // Task features
    taskPoints: Math.min(task.points / 30, 1),
    taskCategory: CATEGORIES[category] || 0.7,
    dayOfWeek: createdAt.getDay() / 6,
    hourOfDay: createdAt.getHours() / 23,
    hasDeadline: task.dueDate ? 1 : 0,
    
    // Member historical features
    memberAvgCompletion: memberStats.avgCompletion,
    memberAvgSpeed: memberStats.avgSpeed,
    memberConsistency: memberStats.consistency,
    memberCategoryExperience: memberStats.categoryExperience[category] || 0
  };
}

async function getMemberStats(memberId, householdId) {
  const tasks = await Task.find({
    household: householdId,
    assignedTo: memberId,
    status: { $in: ['completed', 'failed'] }
  });
  
  if (tasks.length === 0) {
    return {
      avgCompletion: 0.5,
      avgSpeed: 0.5,
      consistency: 0.5,
      categoryExperience: {}
    };
  }
  
  const completed = tasks.filter(t => t.status === 'completed');
  const avgCompletion = completed.length / tasks.length;
  
  const speeds = completed
    .filter(t => t.timeToComplete)
    .map(t => Math.max(0, 1 - (t.timeToComplete / 60 / 48)));
  const avgSpeed = speeds.length > 0 ? speeds.reduce((a, b) => a + b, 0) / speeds.length : 0.5;
  
  // Consistency
  const chunks = [];
  const chunkSize = Math.max(5, Math.floor(tasks.length / 4));
  for (let i = 0; i < tasks.length; i += chunkSize) {
    const chunk = tasks.slice(i, i + chunkSize);
    const rate = chunk.filter(t => t.status === 'completed').length / chunk.length;
    chunks.push(rate);
  }
  const mean = chunks.reduce((a, b) => a + b, 0) / chunks.length;
  const variance = chunks.reduce((sum, rate) => sum + Math.pow(rate - mean, 2), 0) / chunks.length;
  const consistency = Math.max(0, 1 - variance);
  
  // Category experience
  const categoryExperience = {};
  Object.keys(CATEGORIES).forEach(cat => {
    const catTasks = tasks.filter(t => categorizeTask(t.title) === cat);
    const catCompleted = catTasks.filter(t => t.status === 'completed');
    categoryExperience[cat] = catTasks.length > 0 ? catCompleted.length / catTasks.length : 0;
  });
  
  return {
    avgCompletion,
    avgSpeed,
    consistency,
    categoryExperience
  };
}

//  AI SYSTEM 

class TaskSuccessAI {
  constructor() {
    this.net = new brain.NeuralNetwork({
      hiddenLayers: [16, 12, 8],
      activation: 'sigmoid'
    });
    this.isTrained = false;
    this.trainingStats = null;
  }

  /**
   * Antrenează AI pe task-uri completate
   */
  async train(householdId) {
    console.log(' Training AI on historical task data...');
    
    const household = await Household.findById(householdId).populate('members');
    if (!household) throw new Error('Household not found');
    
    const trainingData = [];
    
    for (const member of household.members) {
      const memberStats = await getMemberStats(member._id, householdId);
      
      const tasks = await Task.find({
        household: householdId,
        assignedTo: member._id,
        status: { $in: ['completed', 'failed'] }
      }).sort({ createdAt: 1 });
      
      if (tasks.length < 5) continue;
      
      for (const task of tasks) {
        const features = extractTaskFeatures(task, memberStats);
        
        // OUTPUT REAL: A fost completat la timp?
        const success = task.status === 'completed' && task.completedOnTime === true;
        
        trainingData.push({
          input: features,
          output: { success: success ? 1 : 0 }
        });
      }
    }
    
    if (trainingData.length < 20) {
      throw new Error(`Need at least 20 completed tasks. Current: ${trainingData.length}`);
    }
    
    console.log(` Training on ${trainingData.length} tasks...`);
    
    this.trainingStats = this.net.train(trainingData, {
      iterations: 20000,
      errorThresh: 0.01,
      log: true,
      logPeriod: 2000
    });
    
    console.log('✅ Training complete!');
    console.log('Final error:', this.trainingStats.error);
    
    this.isTrained = true;
    return this.trainingStats;
  }

  /**
   * Prezice probabilitatea de succes pentru un task
   */
  async predictSuccess(memberId, taskData, householdId) {
    if (!this.isTrained) {
      await this.train(householdId);
    }
    
    const memberStats = await getMemberStats(memberId, householdId);
    
    const features = {
      taskPoints: Math.min((taskData.points || 10) / 30, 1),
      taskCategory: CATEGORIES[categorizeTask(taskData.title)] || 0.7,
      dayOfWeek: new Date().getDay() / 6,
      hourOfDay: new Date().getHours() / 23,
      hasDeadline: taskData.dueDate ? 1 : 0,
      memberAvgCompletion: memberStats.avgCompletion,
      memberAvgSpeed: memberStats.avgSpeed,
      memberConsistency: memberStats.consistency,
      memberCategoryExperience: memberStats.categoryExperience[categorizeTask(taskData.title)] || 0
    };
    
    const output = this.net.run(features);
    
    return {
      successProbability: Math.round(output.success * 100),
      confidence: memberStats.avgCompletion > 0.5 ? 'high' : 'medium',
      memberStats,
      features
    };
  }

  /**
   * Recomandă cel mai bun membru pentru un task
   */
  async recommendMember(taskData, householdId) {
    const household = await Household.findById(householdId).populate('members');
    if (!household) throw new Error('Household not found');
    
    const predictions = [];
    
    for (const member of household.members) {
      const prediction = await this.predictSuccess(member._id, taskData, householdId);
      
      predictions.push({
        memberId: member._id.toString(),
        memberName: member.name,
        successProbability: prediction.successProbability,
        confidence: prediction.confidence
      });
    }
    
    predictions.sort((a, b) => b.successProbability - a.successProbability);
    
    return {
      recommended: predictions[0],
      allPredictions: predictions,
      taskTitle: taskData.title
    };
  }

  /**
   * Generează ranking bazat pe predicții
   */
  async generateRanking(householdId) {
    const household = await Household.findById(householdId).populate('members');
    if (!household) throw new Error('Household not found');
    
    if (!this.isTrained) {
      await this.train(householdId);
    }
    
    const rankings = [];
    
    for (const member of household.members) {
      const memberStats = await getMemberStats(member._id, householdId);
      
      // Calculează scor bazat pe stats reale
      const score = (
        memberStats.avgCompletion * 50 +
        memberStats.avgSpeed * 30 +
        memberStats.consistency * 20
      );
      
      const tasks = await Task.find({
        household: householdId,
        assignedTo: member._id
      });
      
      rankings.push({
        memberId: member._id.toString(),
        memberName: member.name,
        aiScore: Math.round(score * 10) / 10,
        totalTasks: tasks.length,
        completionRate: Math.round(memberStats.avgCompletion * 100),
        avgSpeed: Math.round(memberStats.avgSpeed * 100),
        consistency: Math.round(memberStats.consistency * 100)
      });
    }
    
    rankings.sort((a, b) => b.aiScore - a.aiScore);
    rankings.forEach((r, i) => r.rank = i + 1);
    
    return {
      householdId: householdId.toString(),
      householdName: household.name,
      members: rankings,
      generatedBy: 'AI - Task Success Prediction',
      trainedOn: new Date().toISOString()
    };
  }

  exportModel() {
    return {
      network: this.net.toJSON(),
      isTrained: this.isTrained,
      stats: this.trainingStats
    };
  }

  importModel(data) {
    this.net.fromJSON(data.network);
    this.isTrained = data.isTrained;
    this.trainingStats = data.stats;
  }
}

// === SINGLETON ===

let aiSystem = null;

function getAI() {
  if (!aiSystem) {
    aiSystem = new TaskSuccessAI();
  }
  return aiSystem;
}

module.exports = {
  TaskSuccessAI,
  getAI,
  categorizeTask,
  getMemberStats
};