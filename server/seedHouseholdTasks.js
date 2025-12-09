// seedHouseholdTasks.js
// Run with: node seedHouseholdTasks.js
// Verify HOUSEHOLD_ID and USER_IDS before running

require('dotenv').config();
const mongoose = require('mongoose');

// Import models
const Task = require('./model/Task');
const User = require('./model/User');
const Household = require('./model/Household');

// ========================================
// CONFIGURATION
// ========================================
const HOUSEHOLD_ID = '691a1acbcc1ce7336613116d';
const USER_IDS = {
  ade: '690f620c49406f5fdb91194f',
  denisa: '690f64daebc822ee9f473db3',
  cristina: '6920193f50d36a96cf1350a2',
  mama: '69382d18adb8854c4b901b1e',
  tata: '69382d9eadb8854c4b901b47'
};

// Task definitions with realistic weekly frequency
const TASK_TYPES = {
  // Shopping - 1 per week
  shopping: {
    weeklyFrequency: 1,
    duration_minutes: 90,
    titles: ['Grocery shopping Lidl', 'Shopping at Kaufland', 'Farmers market', 'Weekly groceries'],
    preferredDays: [5, 6, 0], // Friday, Saturday, Sunday
    preferredHours: [9, 10, 11, 17, 18, 19],
    deadlineHours: 48
  },
  
  // Trash - 3-4 per week
  take_out_trash: {
    weeklyFrequency: 3.5,
    duration_minutes: 10,
    titles: ['Take out trash', 'Empty trash bins', 'Take out recycling', 'Take out glass'],
    preferredDays: [0, 1, 2, 3, 4, 5, 6],
    preferredHours: [19, 20, 21, 22],
    deadlineHours: 12
  },
  
  // Cleaning - 2 per week (divided into smaller tasks)
  vacuum: {
    weeklyFrequency: 0.7,
    duration_minutes: 45,
    titles: ['Vacuum living room', 'Vacuum bedroom', 'Vacuum entire house'],
    preferredDays: [6, 0], // Weekend
    preferredHours: [10, 11, 14, 15, 16],
    deadlineHours: 72
  },
  
  dust: {
    weeklyFrequency: 0.5,
    duration_minutes: 30,
    titles: ['Dust surfaces', 'Dust and vacuum', 'Clean surfaces'],
    preferredDays: [6, 0],
    preferredHours: [10, 11, 14, 15],
    deadlineHours: 72
  },
  
  clean_windows: {
    weeklyFrequency: 0.3,
    duration_minutes: 60,
    titles: ['Clean living room windows', 'Clean all windows', 'Windows and mirrors'],
    preferredDays: [6, 0],
    preferredHours: [11, 12, 13, 14],
    deadlineHours: 96
  },
  
  clean_bathroom: {
    weeklyFrequency: 0.5,
    duration_minutes: 40,
    titles: ['Clean bathroom', 'Bathroom and toilet', 'Deep clean bathroom'],
    preferredDays: [6, 0],
    preferredHours: [10, 11, 15, 16],
    deadlineHours: 72
  },
  
  // Dishes - 2-3 per week (start + unload)
  start_dishwasher: {
    weeklyFrequency: 2.5,
    duration_minutes: 10,
    titles: ['Start dishwasher', 'Load dishwasher', 'Run dishwasher'],
    preferredDays: [0, 1, 2, 3, 4, 5, 6],
    preferredHours: [21, 22, 23],
    deadlineHours: 6
  },
  
  unload_dishwasher: {
    weeklyFrequency: 2.5,
    duration_minutes: 15,
    titles: ['Unload dishwasher', 'Empty dishwasher', 'Put dishes away'],
    preferredDays: [0, 1, 2, 3, 4, 5, 6],
    preferredHours: [7, 8, 9, 18, 19],
    deadlineHours: 8
  },
  
  // Cooking - 5-6 per week
  cook_breakfast: {
    weeklyFrequency: 1.5,
    duration_minutes: 20,
    titles: ['Prepare breakfast', 'Make breakfast', 'Coffee and breakfast'],
    preferredDays: [6, 0],
    preferredHours: [8, 9, 10],
    deadlineHours: 2
  },
  
  cook_lunch: {
    weeklyFrequency: 2,
    duration_minutes: 60,
    titles: ['Cook lunch', 'Prepare lunch', 'Make lunch'],
    preferredDays: [0, 5, 6],
    preferredHours: [11, 12, 13],
    deadlineHours: 3
  },
  
  cook_dinner: {
    weeklyFrequency: 2.5,
    duration_minutes: 45,
    titles: ['Cook dinner', 'Prepare dinner', 'Make dinner'],
    preferredDays: [0, 1, 2, 3, 4, 5, 6],
    preferredHours: [18, 19, 20],
    deadlineHours: 3
  },
  
  // Laundry - 2 per week (start + hang)
  start_laundry: {
    weeklyFrequency: 2,
    duration_minutes: 15,
    titles: ['Start laundry', 'Run washing machine', 'Do laundry'],
    preferredDays: [6, 0, 3],
    preferredHours: [9, 10, 11, 18, 19],
    deadlineHours: 24
  },
  
  hang_laundry: {
    weeklyFrequency: 2,
    duration_minutes: 20,
    titles: ['Hang laundry to dry', 'Take out laundry', 'Hang clothes'],
    preferredDays: [6, 0, 3],
    preferredHours: [11, 12, 13, 20, 21],
    deadlineHours: 4
  }
};

const MEMBERS = [
  { id: USER_IDS.ade, name: 'Ade' },
  { id: USER_IDS.denisa, name: 'Denisa' },
  { id: USER_IDS.cristina, name: 'Cristina' },
  { id: USER_IDS.mama, name: 'Mama' },
  { id: USER_IDS.tata, name: 'Tata' }
];

// ========================================
// HELPER FUNCTIONS
// ========================================

// Select a random preferred day
function getPreferredDay(preferredDays) {
  return preferredDays[Math.floor(Math.random() * preferredDays.length)];
}

// Select a random preferred hour
function getPreferredHour(preferredHours) {
  return preferredHours[Math.floor(Math.random() * preferredHours.length)];
}

// Calculate if task will be completed
function willCompleteTask() {
  // 85% chance to be completed
  return Math.random() < 0.85;
}

// Calculate if task will be on time
function willBeOnTime() {
  // 75% chance to be on time (among completed tasks)
  return Math.random() < 0.75;
}

// Generate completion date
function generateCompletionDate(createdAt, deadline, onTime) {
  if (onTime) {
    // Completed between createdAt and deadline
    const timeWindow = deadline - createdAt;
    // Most complete in first half of interval
    const completionPoint = Math.random() < 0.7 
      ? Math.random() * 0.6 // 70% complete in first 60% of time
      : 0.6 + Math.random() * 0.4; // 30% complete in last 40%
    
    return new Date(createdAt.getTime() + timeWindow * completionPoint);
  } else {
    // Completed after deadline (1-24h delay)
    const delayHours = 1 + Math.random() * 23;
    return new Date(deadline.getTime() + delayHours * 60 * 60 * 1000);
  }
}

// Select random member (with realistic variation)
function selectRandomMember() {
  // You can adjust here to favor one member
  // Currently equal distribution
  return MEMBERS[Math.floor(Math.random() * MEMBERS.length)].id;
}

// ========================================
// TASK GENERATION
// ========================================
async function generateYearlyTasks() {
  console.log('Starting realistic task generation for 1 year...\n');
  
  const tasks = [];
  const startDate = new Date();
  startDate.setFullYear(startDate.getFullYear() - 1);
  startDate.setHours(0, 0, 0, 0);
  
  const endDate = new Date();
  let currentWeekStart = new Date(startDate);
  let weekNumber = 0;
  
  const stats = {
    total: 0,
    completed: 0,
    failed: 0,
    onTime: 0,
    late: 0
  };
  
  // Iterate through each week
  while (currentWeekStart < endDate) {
    weekNumber++;
    const weekEnd = new Date(currentWeekStart);
    weekEnd.setDate(weekEnd.getDate() + 7);
    
    console.log(`Week ${weekNumber}: ${currentWeekStart.toLocaleDateString('ro-RO')}`);
    
    // Generate tasks for each type
    for (const [taskType, config] of Object.entries(TASK_TYPES)) {
      // Calculate number of tasks for this week
      const baseFrequency = config.weeklyFrequency;
      const variation = Math.random() * 0.4 - 0.2; // ±20% variation
      const numTasks = Math.round(baseFrequency + variation);
      
      for (let i = 0; i < numTasks; i++) {
        // Select preferred day
        const dayOffset = getPreferredDay(config.preferredDays);
        const taskDate = new Date(currentWeekStart);
        
        // Calculate day in week
        const currentDay = taskDate.getDay();
        const daysToAdd = (dayOffset - currentDay + 7) % 7;
        taskDate.setDate(taskDate.getDate() + daysToAdd);
        
        // If past end date, skip
        if (taskDate >= endDate) continue;
        
        // Set preferred hour
        const hour = getPreferredHour(config.preferredHours);
        taskDate.setHours(hour, Math.floor(Math.random() * 60), 0, 0);
        
        // Calculate deadline
        const deadline = new Date(taskDate);
        deadline.setHours(deadline.getHours() + config.deadlineHours);
        
        // Select member
        const assignedTo = selectRandomMember();
        const assignedName = MEMBERS.find(m => m.id === assignedTo).name;
        
        // Determine if will be completed
        const completed = willCompleteTask();
        const onTime = completed ? willBeOnTime() : false;
        
        let status, completedAt, completedBy, points, timeToComplete;
        
        if (completed) {
          completedAt = generateCompletionDate(taskDate, deadline, onTime);
          completedBy = new mongoose.Types.ObjectId(assignedTo);
          points = 5 + Math.floor(Math.random() * 15);
          timeToComplete = Math.round((completedAt - taskDate) / (1000 * 60));
          status = 'completed';
          
          if (onTime) {
            stats.onTime++;
          } else {
            stats.late++;
          }
          stats.completed++;
        } else {
          status = 'active';
          points = 0;
          stats.failed++;
        }
        
        stats.total++;
        
        // Choose random title
        const title = config.titles[Math.floor(Math.random() * config.titles.length)];
        
        tasks.push({
          title,
          description: `Task ${taskType} - ${assignedName}`,
          type: 'group',
          household: new mongoose.Types.ObjectId(HOUSEHOLD_ID),
          assignedTo: new mongoose.Types.ObjectId(assignedTo),
          owner: new mongoose.Types.ObjectId(assignedTo),
          status: status,
          dueDate: deadline,
          dueTime: `${deadline.getHours().toString().padStart(2, '0')}:${deadline.getMinutes().toString().padStart(2, '0')}`,
          points: points,
          completedAt: completedAt,
          completedBy: completedBy,
          completedOnTime: completed ? onTime : undefined,
          timeToComplete: timeToComplete,
          createdAt: taskDate,
          updatedAt: completedAt || taskDate
        });
      }
    }
    
    // Move to next week
    currentWeekStart.setDate(currentWeekStart.getDate() + 7);
  }
  
  console.log(`\nGenerated ${tasks.length} tasks\n`);
  
  // Display statistics
  console.log('GENERATION STATISTICS:');
  console.log(`   Total tasks: ${stats.total}`);
  console.log(`   Completed: ${stats.completed} (${(stats.completed/stats.total*100).toFixed(1)}%)`);
  console.log(`   On time: ${stats.onTime} (${(stats.onTime/stats.completed*100).toFixed(1)}% of completed)`);
  console.log(`   Late: ${stats.late} (${(stats.late/stats.completed*100).toFixed(1)}% of completed)`);
  console.log(`   Not completed: ${stats.failed} (${(stats.failed/stats.total*100).toFixed(1)}%)\n`);
  
  return tasks;
}

// ========================================
// MAIN
// ========================================
async function main() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    
    if (!mongoUri) {
      console.error('❌ ERROR: MONGO_URI not found in .env file!');
      process.exit(1);
    }
    
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB\n');
    
    // Verifică household
    const household = await Household.findById(HOUSEHOLD_ID);
    if (!household) {
      console.error('❌ Household not found! Check HOUSEHOLD_ID');
      process.exit(1);
    }
    console.log(`✅ Household found: ${household.name}\n`);
    
    // Verifică userii
    for (const [name, id] of Object.entries(USER_IDS)) {
      const user = await User.findById(id);
      if (!user) {
        console.error(`❌ User ${name} not found! Check USER_IDS`);
        process.exit(1);
      }
      console.log(`✅ User found: ${user.name} (${name})`);
    }
    console.log('');
    
    // DELETE all existing tasks
    console.log('DELETING all existing tasks...');
    const deleteResult = await Task.deleteMany({ household: HOUSEHOLD_ID });
    console.log(`Deleted ${deleteResult.deletedCount} existing tasks\n`);
    
    // Generate new tasks
    const tasks = await generateYearlyTasks();
    
    // Insert into database
    console.log('Inserting tasks into database...');
    const result = await Task.insertMany(tasks);
    console.log(`Inserted ${result.length} tasks successfully!\n`);
    
    // Statistici finale din DB
    const dbStats = {
      total: await Task.countDocuments({ household: HOUSEHOLD_ID }),
      completed: await Task.countDocuments({ household: HOUSEHOLD_ID, status: 'completed' }),
      active: await Task.countDocuments({ household: HOUSEHOLD_ID, status: 'active' }),
      onTime: await Task.countDocuments({ household: HOUSEHOLD_ID, completedOnTime: true }),
    };
    
    console.log('DATABASE VERIFICATION:');
    console.log(`   Total in DB: ${dbStats.total}`);
    console.log(`   Completed: ${dbStats.completed}`);
    console.log(`   On time: ${dbStats.onTime}`);
    console.log(`   Active: ${dbStats.active}\n`);
    
    // Task-uri pe membru
    for (const member of MEMBERS) {
      const memberTasks = await Task.countDocuments({ 
        household: HOUSEHOLD_ID, 
        assignedTo: member.id 
      });
      const memberCompleted = await Task.countDocuments({ 
        household: HOUSEHOLD_ID, 
        assignedTo: member.id,
        status: 'completed'
      });
      console.log(`   ${member.name}: ${memberTasks} tasks (${memberCompleted} completed)`);
    }
    
    console.log('\nDONE! Database is now populated with realistic yearly tasks.\n');
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run
main();