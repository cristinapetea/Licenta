const router = require('express').Router();
const { Types } = require('mongoose');
const ctrl = require('../controller/task.controller');
const upload = require('../config/upload');


const fakeAuth = (req, res, next) => {
  console.log('fakeAuth middleware - checking x-user header');
  const id = req.headers['x-user'];
  console.log('x-user value:', id);
  if (!id || !Types.ObjectId.isValid(id)) {
    console.log('x-user validation failed');
    return res.status(401).json({ error: 'x-user header missing or invalid' });
  }
  req.user = { sub: id };
  console.log('fakeAuth passed, userId:', id);
  next();
};

// POST /api/tasks - creează task nou
router.post('/', fakeAuth, ctrl.create);

// GET /api/tasks?type=group&householdId=xxx&status=active
router.get('/', fakeAuth, ctrl.list);

// GET /api/tasks/stats?householdId=xxx
router.get('/stats', fakeAuth, ctrl.stats);

// GET /api/tasks/:id - get single task 
router.get('/:id', fakeAuth, ctrl.getById);

router.get('/performance', fakeAuth, ctrl.performanceStats);

// PATCH /api/tasks/:id/photo - upload photo + complete task
router.patch('/:id/photo', fakeAuth, upload.single('photo'), ctrl.updateWithPhoto);

// PATCH /api/tasks/:id - update task
router.patch('/:id', fakeAuth, ctrl.update);

// DELETE /api/tasks/:id - delete task
router.delete('/:id', fakeAuth, ctrl.delete);

// Shopping List endpoints
router.post('/:id/shopping', fakeAuth, ctrl.addShoppingItem);
router.patch('/:id/shopping/:itemId/toggle', fakeAuth, ctrl.toggleShoppingItem);
router.delete('/:id/shopping/:itemId', fakeAuth, ctrl.deleteShoppingItem);

module.exports = router;