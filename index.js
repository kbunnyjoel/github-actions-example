const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// --- Live Reload Setup (for development) ---
if (process.env.NODE_ENV === 'development') { // Only run in development
  const livereload = require('livereload');
  const connectLiveReload = require('connect-livereload');

  // Create a livereload server instance
  // It will watch files in 'public' and 'views' directories
  const liveReloadServer = livereload.createServer();
  liveReloadServer.watch(path.join(__dirname, 'public'));
  liveReloadServer.watch(path.join(__dirname, 'views'));

  // Use connect-livereload middleware to inject the client script
  app.use(connectLiveReload());

  // Refresh browser on server restart (after nodemon)
  liveReloadServer.server.once("connection", () => {
    setTimeout(() => liveReloadServer.refresh("/"), 100);
  });
}
// --- End Live Reload Setup ---
// Set view engine to EJS
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Serve static files from 'public' directory
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json()); // Add this line to parse JSON request bodies

// Render the form
app.get('/', (req, res) => {
  res.render('index');
});

// Handle form submission
app.post('/add', (req, res) => {
  const { num1, num2 } = req.body;

  if (
    num1 === undefined || num2 === undefined ||
    num1 === null || num2 === null ||
    num1 === '' || num2 === ''
  ) {
    return res.status(400).json({ error: 'Both num1 and num2 are required and cannot be empty or missing.' });
  }

  const parsedNum1 = parseFloat(num1);
  const parsedNum2 = parseFloat(num2);

  const result = parsedNum1 + parsedNum2;

  if (Number.isNaN(result)) {
    return res.status(200).json({ result: NaN });
  }

  if (!Number.isFinite(result)) {
    return res.status(200).json({ result: null });
  }

  const roundedResult = Math.round(result * 100000) / 100000;
  return res.status(200).json({ result: roundedResult });
});

const server = app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${port}`);
});

// Export the app for supertest and server for explicit closing if needed
module.exports = { app, server };
