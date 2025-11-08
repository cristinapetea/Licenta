// import unic, cu nume clar
const UserModel = require('../model/User');

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
  const { email, password } = req.body;

  const user = await UserModel.findOne({ email });
  if (!user || user.password !== password) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  res.json({ message: 'Login successful', id: user._id });
};
