const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// --- Live Reload Setup (for development) ---
if (process.env.NODE_ENV !== 'production') {
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

// Render the form
app.get('/', (req, res) => {
  res.render('index');
});

// Handle form submission
app.post('/add', (req, res) => {
  const { num1: num1Str, num2: num2Str } = req.body;
  const num1 = parseFloat(num1Str);
  const num2 = parseFloat(num2Str);

  if (isNaN(num1) || isNaN(num2)) {
    // If inputs are not valid numbers, re-render with an error message
    return res.render('index', { error: 'Invalid input. Please enter numbers only.' });
  }

  const result = num1 + num2;
  res.render('index', { result: result });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
