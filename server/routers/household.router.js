// server/routers/household.router.js
const router = require('express').Router();
const { Types } = require('mongoose');
const ctrl = require('../controller/household.controller');

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

router.post('/',           fakeAuth, ctrl.create);     // POST /api/households
router.post('/join',       fakeAuth, ctrl.joinByCode); // POST /api/households/join
router.get('/mine',        fakeAuth, ctrl.mine);       // GET  /api/households/mine
router.get('/:id/members', fakeAuth, ctrl.getMembers); // GET  /api/households/:id/members

module.exports = router;
