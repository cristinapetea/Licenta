const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Logging middleware pentru debugging
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

// ✅ healthcheck GET (trebuie să-ți răspundă "ok" în browser)
app.get('/health', (_req, res) => res.send('ok'));

// rutele tale de auth
app.use('/api/auth', require('./routers/auth.router'));

app.use('/api/households', require('./routers/household.router'));

module.exports = app;
