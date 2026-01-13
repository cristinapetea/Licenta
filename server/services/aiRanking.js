// server/services/aiRanking.js
const brain = require('brain.js');
const Task = require('../model/Task');
const Household = require('../model/Household');

// === PARTEA 1: PREGĂTIREA DATELOR ===

/**
 * Extrage features (caracteristici) dintr-un task pentru AI
 */
function extractTaskFeatures(task) {
  const now = new Date();
  const createdAt = new Date(task.createdAt);
  const completedAt = task.completedAt ? new Date(task.completedAt) : null;
  
  // Feature 1: A fost completat? (0 sau 1)
  const wasCompleted = task.status === 'completed' ? 1 : 0;
  
  // Feature 2: A fost la timp? (0, 0.5, sau 1)
  let wasOnTime = 0;
  if (wasCompleted && task.completedOnTime === true) wasOnTime = 1;
  else if (wasCompleted && task.completedOnTime === false) wasOnTime = 0;
  else wasOnTime = 0.5; // încă activ
  
  // Feature 3: Speed score (0-1, cât de repede)
  let speedScore = 0.5;
  if (task.timeToComplete && task.completedOnTime) {
    const hours = task.timeToComplete / 60;
    speedScore = Math.max(0, Math.min(1, 1 - (hours / 48)));
  }
  
  // Feature 4: Puncte normalize (0-1)
  const normalizedPoints = Math.min(task.points / 50, 1); // max 50 puncte
  
  // Feature 5: Ziua săptămânii (0-1)
  const dayOfWeek = createdAt.getDay() / 6; // 0=duminică, 6=sâmbătă
  
  // Feature 6: Ora zilei (0-1)
  const hourOfDay = createdAt.getHours() / 23;
  
  // Feature 7: Are deadline? (0 sau 1)
  const hasDeadline = task.dueDate ? 1 : 0;
  
  return {
    wasCompleted,
    wasOnTime,
    speedScore,
    normalizedPoints,
    dayOfWeek,
    hourOfDay,
    hasDeadline
  };
}

/**
 * Agregă features pentru un membru (media tuturor task-urilor)
 */
function aggregateMemberFeatures(tasks) {
  if (tasks.length === 0) {
    return {
      avgCompletion: 0,
      avgOnTime: 0,
      avgSpeed: 0,
      totalTasks: 0,
      avgPoints: 0,
      consistency: 0
    };
  }
  
  const features = tasks.map(extractTaskFeatures);
  
  // Calculăm medii
  const avgCompletion = features.reduce((sum, f) => sum + f.wasCompleted, 0) / features.length;
  const avgOnTime = features.reduce((sum, f) => sum + f.wasOnTime, 0) / features.length;
  const avgSpeed = features.reduce((sum, f) => sum + f.speedScore, 0) / features.length;
  const avgPoints = features.reduce((sum, f) => sum + f.normalizedPoints, 0) / features.length;
  
  // Consistență (varianța completion rate-ului)
  const chunkSize = Math.max(1, Math.floor(tasks.length / 4));
  const chunks = [];
  for (let i = 0; i < 4 && i * chunkSize < tasks.length; i++) {
    const start = i * chunkSize;
    const end = Math.min(start + chunkSize, tasks.length);
    const chunkTasks = tasks.slice(start, end);
    const chunkRate = chunkTasks.filter(t => t.status === 'completed').length / chunkTasks.length;
    chunks.push(chunkRate);
  }
  
  const mean = chunks.reduce((a, b) => a + b, 0) / chunks.length;
  const variance = chunks.reduce((sum, rate) => sum + Math.pow(rate - mean, 2), 0) / chunks.length;
  const consistency = Math.max(0, 1 - variance);
  
  return {
    avgCompletion,
    avgOnTime,
    avgSpeed,
    totalTasks: tasks.length,
    avgPoints,
    consistency
  };
}

// === PARTEA 2: NEURAL NETWORK ===

class AIRankingSystem {
  constructor() {
    // Creăm o rețea neuronală
    this.net = new brain.NeuralNetwork({
      hiddenLayers: [10, 8], // 2 straturi ascunse
      activation: 'sigmoid'
    });
    
    this.isTrained = false;
  }
  
  /**
   * Antrenează AI-ul pe datele existente
   */
  async train(householdId) {
    console.log('🤖 Training AI on household data...');
    
    const household = await Household.findById(householdId).populate('members');
    if (!household) throw new Error('Household not found');
    
    const trainingData = [];
    
    // Pentru fiecare membru, extragem datele
    for (const member of household.members) {
      const tasks = await Task.find({
        household: householdId,
        assignedTo: member._id
      }).sort({ createdAt: 1 });
      
      if (tasks.length < 5) continue; // skip dacă sunt prea puține task-uri
      
      const features = aggregateMemberFeatures(tasks);
      
      // Input pentru AI: features-urile
      const input = {
        avgCompletion: features.avgCompletion,
        avgOnTime: features.avgOnTime,
        avgSpeed: features.avgSpeed,
        consistency: features.consistency,
        avgPoints: features.avgPoints,
        taskVolume: Math.min(features.totalTasks / 100, 1) // normalize
      };
      
      // Output așteptat: scorul de performanță (0-1)
      // Îl calculăm similar cu formula veche, dar AI-ul va învăța să-l aproximeze
      const expectedScore = (
        features.avgCompletion * 0.4 +
        features.avgOnTime * 0.3 +
        features.avgSpeed * 0.2 +
        features.consistency * 0.1
      );
      
      trainingData.push({
        input,
        output: { score: expectedScore }
      });
    }
    
    if (trainingData.length === 0) {
      console.log('❌ Not enough data to train');
      return false;
    }
    
    console.log(`📊 Training on ${trainingData.length} members...`);
    
    // Antrenăm rețeaua
    const stats = this.net.train(trainingData, {
      iterations: 20000,
      errorThresh: 0.005,
      log: true,
      logPeriod: 1000
    });
    
    console.log('✅ Training complete!', stats);
    this.isTrained = true;
    
    return true;
  }
  
  /**
   * Prezice scorul pentru un membru
   */
  async predictScore(memberId, householdId) {
    if (!this.isTrained) {
      throw new Error('AI not trained yet! Call train() first.');
    }
    
    const tasks = await Task.find({
      household: householdId,
      assignedTo: memberId
    }).sort({ createdAt: 1 });
    
    if (tasks.length === 0) return 0;
    
    const features = aggregateMemberFeatures(tasks);
    
    const input = {
      avgCompletion: features.avgCompletion,
      avgOnTime: features.avgOnTime,
      avgSpeed: features.avgSpeed,
      consistency: features.consistency,
      avgPoints: features.avgPoints,
      taskVolume: Math.min(features.totalTasks / 100, 1)
    };
    
    const output = this.net.run(input);
    
    return output.score * 100; // convertim din 0-1 în 0-100
  }
  
  /**
   * Generează ranking AI pentru tot household-ul
   */
  async generateRanking(householdId) {
    // Antrenăm AI-ul mai întâi
    await this.train(householdId);
    
    const household = await Household.findById(householdId).populate('members');
    if (!household) throw new Error('Household not found');
    
    const rankings = [];
    
    for (const member of household.members) {
      const tasks = await Task.find({
        household: householdId,
        assignedTo: member._id
      });
      
      if (tasks.length === 0) continue;
      
      // AI prezice scorul
      const aiScore = await this.predictScore(member._id, householdId);
      
      const completed = tasks.filter(t => t.status === 'completed').length;
      const onTime = tasks.filter(t => t.completedOnTime === true).length;
      
      rankings.push({
        memberId: member._id.toString(),
        memberName: member.name,
        aiScore: Math.round(aiScore * 10) / 10,
        totalTasks: tasks.length,
        completed,
        completionRate: Math.round((completed / tasks.length) * 100),
        onTime,
        onTimeRate: completed > 0 ? Math.round((onTime / completed) * 100) : 0
      });
    }
    
    // Sortăm după scorul AI
    rankings.sort((a, b) => b.aiScore - a.aiScore);
    
    // Adăugăm rank
    rankings.forEach((r, i) => r.rank = i + 1);
    
    return {
      householdId: householdId.toString(),
      householdName: household.name,
      members: rankings,
      generatedBy: 'AI',
      trainedOn: new Date().toISOString()
    };
  }
  
  /**
   * Salvează modelul antrenat
   */
  exportModel() {
    return this.net.toJSON();
  }
  
  /**
   * Încarcă un model salvat
   */
  importModel(json) {
    this.net.fromJSON(json);
    this.isTrained = true;
  }
}

// === PARTEA 3: EXPORT ===

// Singleton instance
let aiSystem = null;

function getAISystem() {
  if (!aiSystem) {
    aiSystem = new AIRankingSystem();
  }
  return aiSystem;
}

module.exports = {
  getAISystem,
  AIRankingSystem,
  extractTaskFeatures,
  aggregateMemberFeatures
};