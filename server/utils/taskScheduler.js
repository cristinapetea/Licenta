// server/utils/taskScheduler.js
const Task = require('../model/Task');

// Verifică task-urile și marchează cele expirate ca failed
async function checkFailedTasks() {
  try {
    const now = new Date();
    
    // Găsește toate task-urile active cu deadline
    const activeTasks = await Task.find({
      status: 'active',
      dueDate: { $exists: true, $ne: null }
    });
    
    let failedCount = 0;
    
    for (const task of activeTasks) {
      // Construiește deadline-ul exact
      const deadline = new Date(task.dueDate);
      
      if (task.dueTime) {
        const [hours, minutes] = task.dueTime.split(':');
        deadline.setHours(parseInt(hours), parseInt(minutes), 0, 0);
      } else {
        deadline.setHours(23, 59, 59, 999);
      }
      
      // Dacă deadline-ul a trecut, marchează ca failed
      if (now > deadline) {
        task.status = 'failed';
        await task.save();
        failedCount++;
        console.log(`Task "${task.title}" marked as failed (deadline: ${deadline})`);
      }
    }
    
    if (failedCount > 0) {
      console.log(`✅ Marked ${failedCount} tasks as failed`);
    }
  } catch (error) {
    console.error('Error checking failed tasks:', error);
  }
}

// Rulează verificarea la fiecare 5 minute
function startTaskScheduler() {
  console.log('📅 Task scheduler started - checking for failed tasks every 5 minutes');
  
  // Rulează imediat
  checkFailedTasks();
  
  // Apoi la fiecare 5 minute
  setInterval(checkFailedTasks, 5 * 60 * 1000);
}

module.exports = { startTaskScheduler, checkFailedTasks };