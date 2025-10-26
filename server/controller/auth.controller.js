// import unic, cu nume clar
const UserModel = require('../model/User');

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { firstName, lastName, age, occupation, email, password } = req.body;

    const doc = await UserModel.create({
      firstName,
      lastName,
      age: Number(age),         // dacă vine ca string din Flutter
      occupation,
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
