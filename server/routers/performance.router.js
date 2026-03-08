// server/routers/performance.router.js
const router = require('express').Router();
const { Types } = require('mongoose');

const fakeAuth = (req, res, next) => {
  const id = req.headers['x-user'];
  if (!id || !Types.ObjectId.isValid(id)) {
    return res.status(401).json({ error: 'x-user header missing or invalid' });
  }
  req.user = { sub: id };
  next();
};

// GET /api/performance/ranking?householdId=xxx
router.get('/ranking', fakeAuth, async (req, res) => {
  try {
    const { householdId } = req.query;
    
    if (!householdId) {
      return res.status(400).json({ error: 'householdId is required' });
    }
    
    console.log('📊 Getting ranking for household:', householdId);
    
    // TODO: Worker thread implementation
    res.json({
      members: [],
      message: 'Ranking endpoint ready - worker implementation pending'
    });
    
  } catch (err) {
    console.error('❌ Error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;