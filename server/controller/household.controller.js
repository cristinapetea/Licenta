// server/controller/household.controller.js
// ❌ era: const Household = require('./model/Household');
const Household = require('../model/Household'); // ✅ corect
const { Types } = require('mongoose');

function generateInviteCode() {
  const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const N = '23456789';
  const pick = (pool, n) => Array.from({ length: n }, () => pool[Math.floor(Math.random()*pool.length)]).join('');
  return `${pick(A,3)}-${pick(N,3)}-${pick(A,3)}`;
}

exports.create = async (req, res) => {
  try {
    console.log('Creating household - request received');
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    // Convert userId to ObjectId
    let userId;
    try {
      userId = new Types.ObjectId(userIdStr);
    } catch (e) {
      console.error('Invalid userId format:', userIdStr);
      return res.status(400).json({ error: 'Invalid user ID format' });
    }
    
    const { name, address } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });

    console.log('Generating invite code...');
    // Generate unique invite code
    let code;
    let tries = 0;
    const maxTries = 10;
    let found = false;
    
    while (tries < maxTries && !found) {
      code = generateInviteCode();
      tries++;
      const existing = await Household.findOne({ inviteCode: code }).lean();
      if (!existing) {
        found = true;
      }
    }

    if (!found) {
      console.error('Failed to generate unique invite code after', maxTries, 'tries');
      return res.status(500).json({ error: 'Failed to generate unique invite code' });
    }

    console.log('Creating household with code:', code);
    const doc = await Household.create({
      name, 
      address: address || undefined,
      inviteCode: code,
      owner: userId,
      members: [userId],
    });

    console.log('Household created successfully:', doc._id);
    return res.status(201).json({ id: doc._id, name: doc.name, inviteCode: doc.inviteCode });
  } catch (e) {
    console.error('create household error:', e.message || e);
    console.error('Full error stack:', e.stack);
    
    // Handle specific MongoDB errors
    if (e.name === 'ValidationError') {
      return res.status(400).json({ error: 'Validation error: ' + e.message });
    }
    if (e.code === 11000) {
      return res.status(409).json({ error: 'Duplicate invite code, please try again' });
    }
    
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

exports.joinByCode = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'code is required' });

    const hh = await Household.findOne({ inviteCode: code.toUpperCase().trim() });
    if (!hh) return res.status(404).json({ error: 'Invalid code' });

    if (!hh.members.some(m => String(m) === String(userId))) {
      hh.members.push(userId);
      await hh.save();
    }
    return res.json({ id: hh._id, name: hh.name, inviteCode: hh.inviteCode });
  } catch (e) {
    console.error('join household error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};

exports.mine = async (req, res) => {
  try {
    const userIdStr = req.user?.sub || req.user?.id || req.user;
    if (!userIdStr) {
      return res.status(401).json({ error: 'User ID is required' });
    }
    
    const userId = new Types.ObjectId(userIdStr);
    const list = await Household.find({ members: userId }).select('_id name inviteCode stats');
    return res.json(list);
  } catch (e) {
    console.error('mine households error:', e.message || e);
    return res.status(500).json({ error: e.message || 'Server error' });
  }
};
