const express = require('express');
const cors = require('cors');
const path = require('path');
const aiRoutes = require('./routers/aiRoutes');
// ❌ ȘTERGE: app.use('/api/performance', require('./routes/performance'));
// ⬆️ Această linie era ÎNAINTE de a defini `app` - EROARE!

const app = express(); // ⭐ ACUM definești app

app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Request body:', JSON.stringify(req.body));
  }
  if (req.headers['x-user']) {
    console.log('x-user header:', req.headers['x-user']);
  }
  next();
});

// Health check
app.get('/health', (_req, res) => res.send('ok'));

// ⭐ Routes
app.use('/api/auth', require('./routers/auth.router'));
app.use('/api/households', require('./routers/household.router'));
app.use('/api/tasks', require('./routers/task.router'));
app.use('/api/performance', require('./routers/performance.router')); // ⭐ DOAR O DATĂ!
app.use('/api/ai', aiRoutes);

module.exports = app;