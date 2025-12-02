// server/model/Task.js
const { Schema, model } = require('mongoose');

const taskSchema = new Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, trim: true },
  
  // 'group' = task de household, 'personal' = task individual
  type: { type: String, enum: ['group', 'personal'], required: true },
  
  // Pentru task-uri de grup
  household: { type: Schema.Types.ObjectId, ref: 'Household' },
  assignedTo: { type: Schema.Types.ObjectId, ref: 'User' },
  
  // Pentru task-uri personale
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, trim: true },
  
  // Status: active, completed, failed
  status: { 
    type: String, 
    enum: ['active', 'completed', 'failed'], 
    default: 'active' 
  },
  
  // Deadline
  dueDate: { type: Date },
  dueTime: { type: String }, // format HH:mm
  
  // Points
  points: { type: Number, default: 0 },
  
  // Shopping list
  shoppingList: [{
    item: { type: String, required: true },
    checked: { type: Boolean, default: false },
    addedAt: { type: Date, default: Date.now }
  }],
  
  // Completion tracking
  completedAt: { type: Date },
  completedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  
  // Performance metrics
  timeToComplete: { type: Number }, // minutes from creation to completion
  completedOnTime: { type: Boolean }, // true if completed before deadline
  
  // Photo proof
  photo: { type: String },
}, { timestamps: true });

// Virtual pentru a calcula deadline-ul exact
taskSchema.virtual('deadline').get(function() {
  if (!this.dueDate) return null;
  
  const deadline = new Date(this.dueDate);
  
  if (this.dueTime) {
    const [hours, minutes] = this.dueTime.split(':');
    deadline.setHours(parseInt(hours), parseInt(minutes), 0, 0);
  } else {
    // Dacă nu e specificată ora, deadline e la 23:59
    deadline.setHours(23, 59, 59, 999);
  }
  
  return deadline;
});

// Method pentru a verifica dacă task-ul e failed
taskSchema.methods.checkIfFailed = function() {
  if (this.status !== 'active') return false;
  if (!this.deadline) return false;
  
  return new Date() > this.deadline;
};

// Method pentru a marca ca failed
taskSchema.methods.markAsFailed = async function() {
  this.status = 'failed';
  await this.save();
};

// Method pentru a calcula performanța când e completat
taskSchema.methods.calculatePerformance = function() {
  if (!this.completedAt) return;
  
  // Timpul de la creare până la completare (în minute)
  this.timeToComplete = Math.round(
    (this.completedAt - this.createdAt) / (1000 * 60)
  );
  
  // A fost completat la timp?
  if (this.deadline) {
    this.completedOnTime = this.completedAt <= this.deadline;
  }
};

// Index pentru queries rapide
taskSchema.index({ household: 1, type: 1, status: 1 });
taskSchema.index({ owner: 1, type: 1, status: 1 });
taskSchema.index({ status: 1, dueDate: 1 }); // Pentru a găsi task-uri failed

// Setează virtuals să fie incluse în JSON
taskSchema.set('toJSON', { virtuals: true });
taskSchema.set('toObject', { virtuals: true });

module.exports = model('Task', taskSchema, 'Tasks');