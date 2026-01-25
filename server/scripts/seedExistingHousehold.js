// server/scripts/seedExistingHousehold.js
const mongoose = require('mongoose');
const Household = require('../model/Household');
const User = require('../model/User');
const Task = require('../model/Task');

// Template-uri de task-uri
const TASK_TEMPLATES = [
  // Cooking
  { title: 'Cook dinner', category: 'cooking', points: 15 },
  { title: 'Prepare breakfast', category: 'cooking', points: 10 },
  { title: 'Make lunch', category: 'cooking', points: 12 },
  { title: 'Cook pasta', category: 'cooking', points: 10 },
  { title: 'Prepare meal for tomorrow', category: 'cooking', points: 15 },
  
  // Dishes
  { title: 'Start dishwasher', category: 'dishes', points: 5 },
  { title: 'Unload dishwasher', category: 'dishes', points: 8 },
  { title: 'Wash plates by hand', category: 'dishes', points: 10 },
  { title: 'Clean kitchen sink', category: 'dishes', points: 7 },
  
  // Laundry
  { title: 'Hang laundry', category: 'laundry', points: 10 },
  { title: 'Wash clothes', category: 'laundry', points: 8 },
  { title: 'Fold laundry', category: 'laundry', points: 12 },
  { title: 'Iron shirts', category: 'laundry', points: 15 },
  
  // Cleaning
  { title: 'Vacuum living room', category: 'cleaning', points: 12 },
  { title: 'Clean bathroom', category: 'cleaning', points: 15 },
  { title: 'Dust furniture', category: 'cleaning', points: 8 },
  { title: 'Mop floor', category: 'cleaning', points: 12 },
  { title: 'Clean windows', category: 'cleaning', points: 10 },
  
  // Shopping
  { title: 'Buy groceries', category: 'shopping', points: 15 },
  { title: 'Shop for vegetables', category: 'shopping', points: 10 },
  { title: 'Buy cleaning supplies', category: 'shopping', points: 8 },
  
  // Trash
  { title: 'Take out trash', category: 'trash', points: 5 },
  { title: 'Take out garbage', category: 'trash', points: 5 },
  { title: 'Empty trash bins', category: 'trash', points: 7 },
];

function randomDate(daysAgo) {
  const date = new Date();
  date.setDate(date.getDate() - Math.floor(Math.random() * daysAgo));
  date.setHours(Math.floor(Math.random() * 24));
  return date;
}

function randomBool(probability = 0.5) {
  return Math.random() < probability;
}

async function seedExistingHousehold() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/household-app');
    console.log('✅ Connected to MongoDB\n');

    // Găsește primul household
    const household = await Household.findOne().populate('members').populate('owner');
    
    if (!household) {
      console.log('❌ No household found!');
      console.log('💡 Run this instead: node scripts/seedDatabase.js');
      process.exit(1);
    }

    console.log(`📋 Found household: "${household.name}"`);
    console.log(`👤 Owner: ${household.owner ? household.owner.name : 'Unknown'}`);
    console.log(`👥 Members: ${household.members.map(m => m.name).join(', ')}`);
    console.log(`🎫 Invite Code: ${household.inviteCode}\n`);

    if (household.members.length === 0) {
      console.log('❌ Household has no members!');
      console.log('💡 Add members to the household first.');
      process.exit(1);
    }

    // Verifică câte task-uri există deja
    const existingTasks = await Task.countDocuments({ household: household._id });
    console.log(`📊 Existing tasks: ${existingTasks}\n`);

    // Întreabă utilizatorul
    console.log('🤔 How many tasks do you want to generate per member?');
    console.log('   Recommended: 80-100 tasks per member for good AI training\n');

    const tasksPerMember = 80; // Poți face asta interactiv dacă vrei
    console.log(`📝 Will generate ${tasksPerMember} tasks per member...\n`);

    // Definește caracteristici per membru (AI-ul va învăța din asta)
    const memberProfiles = household.members.map((member, index) => {
      // Fiecare membru are caracteristici diferite
      const profiles = [
        { completionRate: 0.88, onTimeRate: 0.82, strengths: ['cooking', 'dishes'] },
        { completionRate: 0.86, onTimeRate: 0.75, strengths: ['dishes', 'laundry'] },
        { completionRate: 0.84, onTimeRate: 0.70, strengths: ['cleaning', 'shopping'] },
      ];
      
      return {
        user: member,
        ...profiles[index % profiles.length]
      };
    });

    let totalTasks = 0;
    let completedTasks = 0;

    console.log('🚀 Generating tasks...\n');

    for (const profile of memberProfiles) {
      console.log(`   Generating tasks for ${profile.user.name}...`);
      
      for (let i = 0; i < tasksPerMember; i++) {
        const template = TASK_TEMPLATES[Math.floor(Math.random() * TASK_TEMPLATES.length)];
        const createdAt = randomDate(60); // Ultimele 60 de zile
        
        // Membru e mai bun la categoria sa de strength
        const isStrength = profile.strengths.includes(template.category);
        const completionChance = isStrength ? profile.completionRate + 0.1 : profile.completionRate;
        const onTimeChance = isStrength ? profile.onTimeRate + 0.1 : profile.onTimeRate;
        
        const isCompleted = randomBool(completionChance);
        const isOnTime = isCompleted ? randomBool(onTimeChance) : false;
        
        const task = {
          title: template.title,
          description: `Generated for AI training`,
          points: template.points,
          household: household._id,
          assignedTo: profile.user._id,
          createdBy: household.owner._id,
          status: isCompleted ? 'completed' : (randomBool(0.1) ? 'failed' : 'pending'),
          createdAt: createdAt,
        };

        // Dacă e completat, adaugă date de completare
        if (isCompleted) {
          const completedAt = new Date(createdAt);
          completedAt.setHours(completedAt.getHours() + Math.floor(Math.random() * 48));
          
          task.completedAt = completedAt;
          task.completedOnTime = isOnTime;
          task.timeToComplete = (completedAt - createdAt) / (1000 * 60); // minute
          
          completedTasks++;
        }

        await Task.create(task);
        totalTasks++;
      }
      
      console.log(`   ✓ ${tasksPerMember} tasks created for ${profile.user.name}`);
    }

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('🎉 Tasks generated successfully!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('\n📊 Summary:');
    console.log(`   Household: ${household.name}`);
    console.log(`   Members: ${memberProfiles.map(p => p.user.name).join(', ')}`);
    console.log(`   Tasks before: ${existingTasks}`);
    console.log(`   Tasks added: ${totalTasks}`);
    console.log(`   Total now: ${existingTasks + totalTasks}`);
    console.log(`   Completed: ${completedTasks} (${Math.round(completedTasks/totalTasks*100)}%)`);
    console.log('\n🚀 Now you can run:');
    console.log('   node scripts/testRanking.js');
    console.log('═══════════════════════════════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Rulează seed
if (require.main === module) {
  seedExistingHousehold();
}

module.exports = { seedExistingHousehold };