// server/controller/task.controller.js
const Task = require('../model/Task');
const Household = require('../model/Household');
const { Types } = require('mongoose');

// CREATE - Crează task nou (grup sau personal)
exports.create = async (req, res) => {
  try {
    console.log('=== CREATE TASK DEBUG ===');
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    console.log('req.user:', req.user);
    
    const userIdStr = req.headers['x-user'] || req.user?.sub || req.user?.id || req.user;
    console.log('Extracted userIdStr:', userIdStr);
    
    if (!userIdStr) {
      console.log('ERROR: No user ID found');
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { title, description, type, householdId, assignedTo, category, dueDate, dueTime, points } = req.body;
    
    if (!title || !type) {
      return res.status(400).json({ error: 'title and type are required' });
    }
    
    if (!['group', 'personal'].includes(type)) {
      return res.status(400).json({ error: 'type must be group or personal' });
    }
    
    const taskData = {
      title,
      description,
      type,
      owner: userId,
      dueDate: dueDate ? new Date(dueDate) : undefined,
      dueTime,
      points: points || 0,
    };
    
    // Task de grup
    if (type === 'group') {
      if (!householdId) {
        return res.status(400).json({ error: 'householdId is required for group tasks' });
      }
      
      // Verifică că user-ul este membru
      const hh = await Household.findById(householdId);
      if (!hh) {
        return res.status(404).json({ error: 'Household not found' });
      }
      
      const isMember = hh.members.some(m => String(m) === String(userId));
      if (!isMember) {
        return res.status(403).json({ error: 'You are not a member of this household' });
      }
      
      taskData.household = new Types.ObjectId(householdId);
      if (assignedTo) {
        taskData.assignedTo = new Types.ObjectId(assignedTo);
      }
    }
    
    // Task personal
    if (type === 'personal') {
      taskData.category = category;
    }
    
    const task = await Task.create(taskData);
    const populated = await Task.findById(task._id)
      .populate('assignedTo', 'name email')
      .populate('owner', 'name email');
    
    return res.status(201).json(populated);
  } catch (e) {
    console.error('create task error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

// GET - Lista task-uri (filtrate după tip și household/owner)
exports.list = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { type, householdId, status, category } = req.query;
    
    const filter = {};
    
    if (type === 'group') {
      if (!householdId) {
        return res.status(400).json({ error: 'householdId is required for group tasks' });
      }
      filter.household = new Types.ObjectId(householdId);
      filter.type = 'group';
    } else if (type === 'personal') {
      filter.owner = userId;
      filter.type = 'personal';
    } else {
      return res.status(400).json({ error: 'type must be group or personal' });
    }
    
    if (status && status !== 'all') {
      filter.status = status;
    }
    
    if (category) {
      filter.category = category;
    }
    
    const tasks = await Task.find(filter)
      .populate('assignedTo', 'name email')
      .populate('owner', 'name email')
      .populate('completedBy', 'name email')
      .sort({ createdAt: -1 });
    
    return res.json(tasks);
  } catch (e) {
    console.error('list tasks error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

// Înlocuiește funcțiile update și updateWithPhoto în task.controller.js

// UPDATE - Actualizează task (inclusiv toggle complete)
exports.update = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { id } = req.params;
    const updates = req.body;
    
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    // Verifică permisiuni
    if (task.type === 'personal') {
      if (String(task.owner) !== String(userId)) {
        return res.status(403).json({ error: 'Not authorized' });
      }
    } else if (task.type === 'group') {
      const hh = await Household.findById(task.household);
      if (!hh) {
        return res.status(404).json({ error: 'Household not found' });
      }
      const isMember = hh.members.some(m => String(m) === String(userId));
      if (!isMember) {
        return res.status(403).json({ error: 'Not authorized' });
      }
    }
    
    // Update status special pentru complete
    if (updates.status === 'completed' && task.status !== 'completed') {
      updates.completedAt = new Date();
      updates.completedBy = userId;
      
      // Calculează performanța
      Object.assign(task, updates);
      task.calculatePerformance();
      await task.save();
      
      console.log(`Task completed: ${task.title}`);
      console.log(`Time to complete: ${task.timeToComplete} minutes`);
      console.log(`Completed on time: ${task.completedOnTime}`);
    } else if (updates.status === 'active') {
      updates.completedAt = undefined;
      updates.completedBy = undefined;
      updates.timeToComplete = undefined;
      updates.completedOnTime = undefined;
      
      Object.assign(task, updates);
      await task.save();
    } else {
      Object.assign(task, updates);
      await task.save();
    }
    
    const populated = await Task.findById(task._id)
      .populate('assignedTo', 'name email')
      .populate('owner', 'name email')
      .populate('completedBy', 'name email');
    
    return res.json(populated);
  } catch (e) {
    console.error('update task error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

// UPDATE WITH PHOTO - Upload photo & complete task
exports.updateWithPhoto = async (req, res) => {
  try {
    console.log('=== UPDATE WITH PHOTO ===');
    console.log('File received:', req.file);
    
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }

    const userId = new Types.ObjectId(userIdStr);
    const { id } = req.params;

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (!req.file) {
      console.log('❌ No file in request');
      return res.status(400).json({ error: 'Photo file is required' });
    }

    // Save photo + mark as completed
    task.photo = `/uploads/${req.file.filename}`;
    task.status = 'completed';
    task.completedAt = new Date();
    task.completedBy = userId;
    
    // Calculează performanța
    task.calculatePerformance();

    await task.save();

    console.log('✅ Photo saved successfully:', task.photo);
    console.log(`Time to complete: ${task.timeToComplete} minutes`);
    console.log(`Completed on time: ${task.completedOnTime}`);

    const populated = await Task.findById(task._id)
      .populate('assignedTo', 'name email')
      .populate('owner', 'name email')
      .populate('completedBy', 'name email');

    console.log('Response task photo path:', populated.photo);

    return res.json(populated);
  } catch (e) {
    console.error('❌ updateWithPhoto error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};
// DELETE - Șterge task
exports.delete = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { id } = req.params;
    
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    // Verifică permisiuni
    if (task.type === 'personal') {
      if (String(task.owner) !== String(userId)) {
        return res.status(403).json({ error: 'Not authorized' });
      }
    } else if (task.type === 'group') {
      const hh = await Household.findById(task.household);
      if (!hh) {
        return res.status(404).json({ error: 'Household not found' });
      }
      const isMember = hh.members.some(m => String(m) === String(userId));
      if (!isMember) {
        return res.status(403).json({ error: 'Not authorized' });
      }
    }
    
    await Task.findByIdAndDelete(id);
    return res.json({ message: 'Task deleted', id });
  } catch (e) {
    console.error('delete task error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

// GET stats pentru dashboard
exports.stats = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { householdId } = req.query;
    
    let filter = {};
    if (householdId) {
      filter.household = new Types.ObjectId(householdId);
      filter.type = 'group';
    } else {
      filter.owner = userId;
    }
    
    const [completed, total, today] = await Promise.all([
      Task.countDocuments({ ...filter, status: 'completed' }),
      Task.countDocuments(filter),
      Task.countDocuments({
        ...filter,
        status: 'active',
        dueDate: {
          $gte: new Date(new Date().setHours(0, 0, 0, 0)),
          $lt: new Date(new Date().setHours(23, 59, 59, 999))
        }
      })
    ]);
    
    const points = await Task.aggregate([
      { $match: { ...filter, status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$points' } } }
    ]);
    
    return res.json({
      completed,
      total,
      today,
      points: points[0]?.total || 0
    });
  } catch (e) {
    console.error('stats error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

// Shopping List Operations
exports.addShoppingItem = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const { id } = req.params;
    const { item } = req.body;
    
    if (!item) {
      return res.status(400).json({ error: 'Item is required' });
    }
    
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    task.shoppingList.push({ item, checked: false });
    await task.save();
    
    return res.json(task);
  } catch (e) {
    console.error('add shopping item error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};

exports.toggleShoppingItem = async (req, res) => {
  try {
    const { id, itemId } = req.params;
    
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    const item = task.shoppingList.id(itemId);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }
    
    item.checked = !item.checked;
    await task.save();
    
    return res.json(task);
  } catch (e) {
    console.error('toggle shopping item error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};

exports.deleteShoppingItem = async (req, res) => {
  try {
    const { id, itemId } = req.params;
    
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    task.shoppingList.pull(itemId);
    await task.save();
    
    return res.json(task);
  } catch (e) {
    console.error('delete shopping item error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Adaugă această funcție în task.controller.js (la sfârșit, după exports.deleteShoppingItem)

// GET single task by ID
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('Getting task by ID:', id);
    
    const task = await Task.findById(id)
      .populate('assignedTo', 'name email')
      .populate('owner', 'name email')
      .populate('completedBy', 'name email');
    
    if (!task) {
      console.log('Task not found');
      return res.status(404).json({ error: 'Task not found' });
    }
    
    console.log('Task found, shoppingList items:', task.shoppingList.length);
    return res.json(task);
  } catch (e) {
    console.error('get task by id error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};


// GET performance stats pentru un user
exports.performanceStats = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { householdId } = req.query;
    
    let filter = { status: 'completed' };
    
    if (householdId) {
      filter.household = new Types.ObjectId(householdId);
      filter.type = 'group';
    } else {
      filter.owner = userId;
      filter.type = 'personal';
    }
    
    const completedTasks = await Task.find(filter);
    
    const stats = {
      totalCompleted: completedTasks.length,
      completedOnTime: completedTasks.filter(t => t.completedOnTime).length,
      completedLate: completedTasks.filter(t => t.completedOnTime === false).length,
      averageTimeToComplete: 0,
      fastestCompletion: null,
      slowestCompletion: null,
    };
    
    if (completedTasks.length > 0) {
      const times = completedTasks
        .filter(t => t.timeToComplete)
        .map(t => t.timeToComplete);
      
      if (times.length > 0) {
        stats.averageTimeToComplete = Math.round(
          times.reduce((a, b) => a + b, 0) / times.length
        );
        stats.fastestCompletion = Math.min(...times);
        stats.slowestCompletion = Math.max(...times);
      }
    }
    
    // Failed tasks
    const failedTasks = await Task.countDocuments({
      ...filter,
      status: 'failed'
    });
    
    stats.failed = failedTasks;
    stats.successRate = stats.totalCompleted + failedTasks > 0
      ? Math.round((stats.totalCompleted / (stats.totalCompleted + failedTasks)) * 100)
      : 100;
    
    return res.json(stats);
  } catch (e) {
    console.error('performance stats error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};