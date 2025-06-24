const fs = require('fs');
const https = require('https');
const express = require('express');
const path = require('path');
const app = express();
console.log('Running in NODE_ENV:', process.env.NODE_ENV);
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

// Middleware to enforce API key, except on whitelisted paths
app.use((req, res, next) => {
  const isHealthCheck = req.path === '/status';
  const isTestEnv = process.env.NODE_ENV === 'test';

  if (isHealthCheck || isTestEnv) return next();

  const exemptPaths = [
    '/',
    '/favicon.ico',
    '/robots.txt',
    '/.well-known/appspecific/com.chrome.devtools.json'
  ];

  const apiKey = req.headers['x-api-key'] || (req.headers['authorization'] && req.headers['authorization'].replace('Bearer ', ''));
  const expectedKey = process.env.EXPECTED_API_KEY;

  const url = req.originalUrl.split('?')[0];
  const isExempt = exemptPaths.some(p => url === p || url.startsWith(p + '/'));
  if (isExempt) return next();

  console.log('Incoming request path:', req.path);
  console.log('Full original URL:', req.originalUrl);
  console.log('Request headers:', req.headers);
  console.log('Received API Key:', apiKey);
  console.log('Expected API Key:', expectedKey);

  if (!apiKey || apiKey !== expectedKey) {
    return res.status(401).send('Api Key was not provided.');
  }

  next();
});

// Health check endpoint
app.get('/status', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Render the form
app.get('/', (req, res) => {
  res.render('index');
});

// Handle form submission
app.post('/add', (req, res) => {
  const { num1, num2 } = req.body;
  console.log('Received inputs:', num1, num2);

  if (
    num1 === undefined || num2 === undefined ||
    num1 === null || num2 === null ||
    num1 === '' || num2 === ''
  ) {
    return res.status(400).json({ error: 'Both num1 and num2 are required and cannot be empty or missing.' });
  }

  const parsedNum1 = parseFloat(num1);
  const parsedNum2 = parseFloat(num2);
  console.log('Parsed inputs:', parsedNum1, parsedNum2);

  const result = parsedNum1 + parsedNum2;
  console.log('Calculated result:', result);

  if (Number.isNaN(result)) {
    return res.status(200).json({ result: NaN });
  }

  if (!Number.isFinite(result)) {
    return res.status(200).json({ result: null });
  }

  const roundedResult = Math.round(result * 100000) / 100000;
  return res.status(200).json({ result: roundedResult });
});

if (require.main === module) {
  if (fs.existsSync(path.join(__dirname, 'certs', 'key.pem')) &&
      fs.existsSync(path.join(__dirname, 'certs', 'cert.pem'))) {
    const httpsOptions = {
      key: fs.readFileSync(path.join(__dirname, 'certs', 'key.pem')),
      cert: fs.readFileSync(path.join(__dirname, 'certs', 'cert.pem')),
    };
    const server = https.createServer(httpsOptions, app).listen(port, '0.0.0.0', () => {
      console.log(`HTTPS server is running on https://0.0.0.0:${port}`);
    }).on('error', (err) => {
      console.error('Failed to start HTTPS server:', err);
    });
    module.exports = { app, server };
  } else {
    const server = app.listen(port, '0.0.0.0', () => {
      console.log(`HTTP server is running on http://0.0.0.0:${port}`);
    }).on('error', (err) => {
      console.error('Failed to start HTTP server:', err);
    });
    module.exports = { app, server };
  }
} else {
  const server = app.listen(0);
  module.exports = { app, server };
}
