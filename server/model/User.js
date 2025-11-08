const { Schema, model } = require('mongoose');

const userSchema = new Schema({
  name: { type: String, required: true, trim: true },
  email:     { type: String, required: true, unique: true, lowercase: true, trim: true },
  password:  { type: String, required: true } // (hash ulterior)
}, { timestamps: true });

// al 3-lea argument fixează exact numele colecției: 'Users'
module.exports = model('User', userSchema, 'Users');
