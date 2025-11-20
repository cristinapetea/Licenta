// server/routers/task.router.js
const router = require('express').Router();
const ctrl = require('../controller/task.controller.js');



// middleware demo: citește userId din header 'x-user' și îl validează
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


// Toate rutele necesită autentificare
router.use(fakeAuth);

// POST /api/tasks - crează task nou
router.post('/', ctrl.create);

// GET /api/tasks?type=group&householdId=xxx&status=active
// GET /api/tasks?type=personal&status=all&category=Sport
router.get('/', ctrl.list);

// GET /api/tasks/stats?householdId=xxx
router.get('/stats', ctrl.stats);

// PATCH /api/tasks/:id - update task
router.patch('/:id', ctrl.update);

// DELETE /api/tasks/:id - delete task
router.delete('/:id', ctrl.delete);

module.exports = router;