// server/controller/household.controller.js
const Household = require('../model/Household');

// generator simplu: ABC-123-XYZ (fără dependențe externe)
function generateInviteCode() {
  const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // fără caractere ambigue
  const N = '23456789';
  const pick = (pool, n) => Array.from({length:n}, () => pool[Math.floor(Math.random()*pool.length)]).join('');
  return `${pick(A,3)}-${pick(N,3)}-${pick(A,3)}`;
}

exports.create = async (req, res) => {
  try {
    const userId = req.user?.sub || req.user?.id || req.user; // depinde cum atașezi user-ul în middleware
    const { name, address } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });

    // generează cod unic (reîncearcă dacă există coliziune)
    let code; let tries = 0;
    do {
      code = generateInviteCode();
      tries++;
    } while (tries < 5 && await Household.findOne({ inviteCode: code }));

    const doc = await Household.create({
      name, address,
      inviteCode: code,
      owner: userId,
      members: [userId],
    });

    res.status(201).json({
      id: doc._id,
      name: doc.name,
      inviteCode: doc.inviteCode
    });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
};

exports.joinByCode = async (req, res) => {
  try {
    const userId = req.user?.sub || req.user?.id || req.user;
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'code is required' });

    const hh = await Household.findOne({ inviteCode: code.toUpperCase().trim() });
    if (!hh) return res.status(404).json({ error: 'Invalid code' });

    if (!hh.members.some(m => String(m) === String(userId))) {
      hh.members.push(userId);
      await hh.save();
    }
    res.json({ id: hh._id, name: hh.name, inviteCode: hh.inviteCode });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
};

exports.mine = async (req, res) => {
  try {
    const userId = req.user?.sub || req.user?.id || req.user;
    const list = await Household.find({ members: userId })
      .select('_id name inviteCode stats');
    res.json(list);
  } catch {
    res.status(500).json({ error: 'Server error' });
  }
};
