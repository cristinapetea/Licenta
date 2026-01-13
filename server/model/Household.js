const { Schema, model, Types } = require('mongoose');

const householdSchema = new Schema({
  name:      { type: String, required: true, trim: true },
  address:   { type: String, trim: true },
  inviteCode:{ type: String, required: true, unique: true, index: true },

  owner:     { type: Types.ObjectId, ref: 'User', required: true },
  members:   [{ type: Types.ObjectId, ref: 'User' }],

  stats: {
    points:           { type: Number, default: 0 },
    tasksCompleted:   { type: Number, default: 0 },
    tasksToday:       { type: Number, default: 0 },
  }
}, { timestamps: true });

module.exports = model('Household', householdSchema);
