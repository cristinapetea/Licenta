const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../model/User'); 

exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validare input
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Please fill in all fields' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    // Verificare email existent
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'An account with this email already exists' });
    }

    const hashed = await bcrypt.hash(password, 10);   
    const doc = await User.create({
      name,
      email,
      password: hashed,                               
    });

    return res.status(201).json({ message: 'Account created successfully', id: doc._id });
  } catch (err) {
    console.error('Registration error:', err);
    return res.status(500).json({ error: 'Unable to create account. Please try again.' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Please enter your email and password' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Incorrect email or password' });
    }

    let ok = false;
    try { ok = await bcrypt.compare(password, user.password); } catch (_) {}

    if (!ok && password === user.password) ok = true;

    if (!ok) {
      return res.status(401).json({ error: 'Incorrect email or password' });
    }

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
    return res.status(500).json({ error: 'Unable to log in. Please try again later.' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    
    if (!email || !newPassword) {
      return res.status(400).json({ error: 'Please provide your email and new password' });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'No account found with this email address' });
    }
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    user.password = hashedPassword;
    await user.save();
    
    return res.status(200).json({ 
      message: 'Password updated successfully! You can now log in.',
      email: user.email 
    });
  } catch (e) {
    console.error('Reset password error:', e);
    return res.status(500).json({ error: 'Unable to reset password. Please try again.' });
  }
};