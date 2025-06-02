const express = require('express');
const app = express();
const port = 3000;

app.use(express.static('public'));

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>🎈 Cool Number Adder 🎈</title>
        <link rel="icon" href="https://emojiapi.dev/api/v1/rocket/64.png" type="image/png">
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            text-align: center;
            margin-top: 50px;
            background: linear-gradient(to right, #74ebd5, #acb6e5);
            color: #333;
          }
          input, button {
            padding: 15px;
            margin: 10px;
            font-size: 1.2em;
            border-radius: 8px;
            border: none;
          }
          button {
            background-color: #ff7675;
            color: white;
            cursor: pointer;
          }
          @keyframes bounce {
            0% { transform: scale(1); }
            50% { transform: scale(1.1); }
            100% { transform: scale(1); }
          }
          button:hover {
            background-color: #d63031;
            animation: bounce 0.3s ease-in-out;
          }
        </style>
      </head>
      <body>
        <h1>🧪 Testing Nodemon Live Reload! 🧪</h1>
        <form action="/add" method="get">
          <input type="number" name="num1" placeholder="Enter first number" required>
          <input type="number" name="num2" placeholder="Enter second number" required>
          <br>
          <button type="submit">💥 Add Numbers 💥</button>
        </form>
      </body>
    </html>
  `);
});

app.get('/add', (req, res) => {
  const num1 = Number(req.query.num1 || 0);
  const num2 = Number(req.query.num2 || 0);
  const result = num1 + num2;

  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>🎉 Result</title>
        <link rel="icon" href="https://emojiapi.dev/api/v1/rocket/64.png" type="image/png">
        <style>
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            text-align: center;
            margin-top: 50px;
            background: linear-gradient(to right, #ffecd2, #fcb69f);
            color: #2d3436;
          }
          .result {
            font-size: 2em;
            font-weight: bold;
            color: #d63031;
            animation: pop 0.6s ease-out;
          }
          @keyframes pop {
            0% { transform: scale(0.7); opacity: 0; }
            100% { transform: scale(1); opacity: 1; }
          }
          a {
            display: inline-block;
            margin-top: 20px;
            text-decoration: none;
            color: #0984e3;
            font-weight: bold;
          }
        </style>
      </head>
      <body>
        <h1>🚀 Live Result with Nodemon! 🚀</h1>
        <p class="result">${num1} + ${num2} = ${result}</p>
        <a href="/">🔙 Go Back</a>
      </body>
    </html>
  `);
});

app.get('/status', (req, res) => {
  res.json({ status: 'live', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
