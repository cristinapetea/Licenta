const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// ✅ healthcheck GET (trebuie să-ți răspundă "ok" în browser)
app.get('/health', (_req, res) => res.send('ok'));

// rutele tale de auth
app.use('/api/auth', require('./routers/auth.router'));

module.exports = app;
