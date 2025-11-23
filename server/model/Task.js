// server/model/Task.js
const { Schema, model } = require('mongoose');

const taskSchema = new Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, trim: true },
  
  // 'group' = task de household, 'personal' = task individual
  type: { type: String, enum: ['group', 'personal'], required: true },
  
  // Pentru task-uri de grup
  household: { type: Schema.Types.ObjectId, ref: 'Household' },
  assignedTo: { type: Schema.Types.ObjectId, ref: 'User' }, // cine trebuie să-l facă
  
  // Pentru task-uri personale
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, trim: true }, // Sport, Hobby, Muncă, Învățat, etc.
  
  // Comune
  status: { type: String, enum: ['active', 'completed', 'all'], default: 'active' },
  dueDate: { type: Date },
  dueTime: { type: String }, // format HH:mm
  points: { type: Number, default: 0 },
  photo: { type: String },

  
  // Metadata
  completedAt: { type: Date },
  completedBy: { type: Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

// Index pentru queries rapide
taskSchema.index({ household: 1, type: 1, status: 1 });
taskSchema.index({ owner: 1, type: 1, status: 1 });

module.exports = model('Task', taskSchema, 'Tasks');