// import unic, cu nume clar
/* const UserModel = require('../model/User');

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const doc = await UserModel.create({
      name,
      email,
      password,                 // (hash adăugăm ulterior)
    });

    res.status(201).json({ message: 'User created', id: doc._id });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;         // CHEI: email, password
    if (!email || !password) {
      return res.status(400).json({ error: 'Missing fields' });
    }

    const user = await UserModel.findOne({ email });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    // opțional: token
    const token = jwt.sign({ sub: user._id }, process.env.JWT_SECRET || 'dev', { expiresIn: '7d' });

    return res.status(200).json({
      
      name: user.name,
      email: user.email,
      token
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Server error' });
  }
};
*/
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../model/User'); // nume unitar
/*
// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ error: 'Missing fields' });

    const exists = await User.findOne({ email });
    if (exists) return res.status(409).json({ error: 'Email already in use' });

    const hash = await bcrypt.hash(password, 10);
    const doc = await User.create({ name, email, password: hash });

    return res.status(201).json({ message: 'User created', id: doc._id });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Server error' });
  }
};
*/


exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const hashed = await bcrypt.hash(password, 10);   // ✅ HASH
    const doc = await User.create({
      name,
      email,
      password: hashed,                               // ✅ salvezi HASH-ul
    });

    return res.status(201).json({ message: 'User created', id: doc._id });
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
};


// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Missing fields' });

    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    // întâi încearcă bcrypt (pentru conturile noi)
    let ok = false;
    try { ok = await bcrypt.compare(password, user.password); } catch (_) {}

    // fallback pentru conturile vechi salvate în clar
    if (!ok && password === user.password) ok = true;

    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    // Verifică dacă utilizatorul are deja un household
    const Household = require('../model/Household');
    const households = await Household.find({ members: user._id }).select('_id name').limit(1);
    const hasHousehold = households.length > 0;

    return res.status(200).json({ 
      id: user._id, 
      name: user.name, 
      email: user.email,
      hasHousehold: hasHousehold,
      householdId: hasHousehold ? households[0]._id : null,
    });
  } catch (e) {
    console.error('Login error:', e);
    return res.status(500).json({ error: 'Server error' });
  }
};
