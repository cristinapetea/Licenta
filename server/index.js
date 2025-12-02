require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/db');
const { startTaskScheduler } = require('./utils/taskScheduler');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    await connectDB();                  //  conectare la Mongo Atlas
    app.listen(PORT, () => {
      console.log(`Server listening on http://localhost:${PORT}`);
      startTaskScheduler();
    });
  } catch (err) {
    console.error('Failed to start server:', err.message);
    process.exit(1);
  }
})();
