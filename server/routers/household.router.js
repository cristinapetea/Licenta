// server/routers/household.router.js
const router = require('express').Router();
const ctrl = require('../controller/household.controller');

// TODO: adaugă un middleware auth real aici
const fakeAuth = (req, _res, next) => {
  // DEMO: citește userId din header 'x-user' sau din JWT (în proiectul tău)
  req.user = { sub: req.headers['x-user'] }; 
  next();
};

router.post('/',        fakeAuth, ctrl.create);      // POST /api/households
router.post('/join',    fakeAuth, ctrl.joinByCode);  // POST /api/households/join
router.get('/mine',     fakeAuth, ctrl.mine);        // GET  /api/households/mine

module.exports = router;
