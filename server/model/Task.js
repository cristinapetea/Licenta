const { Schema, model } = require('mongoose');

const taskSchema = new Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, trim: true },
  
  type: { type: String, enum: ['group', 'personal'], required: true },
  
  household: { type: Schema.Types.ObjectId, ref: 'Household' },
  assignedTo: { type: Schema.Types.ObjectId, ref: 'User' },
  
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, trim: true },
  
  
  status: { 
    type: String, 
    enum: ['active', 'completed', 'failed', 'all'], 
    default: 'active' 
  },
  
  
  dueDate: { type: Date },
  dueTime: { type: String }, 
  
  
  points: { type: Number, default: 0 },
  
  
  shoppingList: [{
    item: { type: String, required: true },
    checked: { type: Boolean, default: false },
    addedAt: { type: Date, default: Date.now }
  }],
  
  
  completedAt: { type: Date },
  completedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  
  // Performance metrics
  timeToComplete: { type: Number }, 
  completedOnTime: { type: Boolean }, 
  
  
  photo: { type: String },
}, { timestamps: true });


taskSchema.virtual('deadline').get(function() {
  if (!this.dueDate) return null;
  
  const deadline = new Date(this.dueDate);
  
  if (this.dueTime) {
    const [hours, minutes] = this.dueTime.split(':');
    deadline.setHours(parseInt(hours), parseInt(minutes), 0, 0);
  } else {
    
    deadline.setHours(23, 59, 59, 999);
  }
  
  return deadline;
});


taskSchema.methods.checkIfFailed = function() {
  if (this.status !== 'active') return false;
  if (!this.deadline) return false;
  
  return new Date() > this.deadline;
};


taskSchema.methods.markAsFailed = async function() {
  this.status = 'failed';
  await this.save();
};


taskSchema.methods.calculatePerformance = function() {
  if (!this.completedAt) return;
  
  
  this.timeToComplete = Math.round(
    (this.completedAt - this.createdAt) / (1000 * 60)
  );
  
  
  if (this.deadline) {
    this.completedOnTime = this.completedAt <= this.deadline;
  }
};


taskSchema.index({ household: 1, type: 1, status: 1 });
taskSchema.index({ owner: 1, type: 1, status: 1 });
taskSchema.index({ status: 1, dueDate: 1 }); 

taskSchema.set('toJSON', { virtuals: true });
taskSchema.set('toObject', { virtuals: true });

module.exports = model('Task', taskSchema, 'Tasks');