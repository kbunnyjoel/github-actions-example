const math = require('./math');
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const num1 = Number(process.env.NUMBER1 || 0);
const num2 = Number(process.env.NUMBER2 || 0);

console.log(`Adding ${num1} and ${num2}`);
console.log('Result:', num1 + num2);

app.get('/status', (req, res) => {
  res.json({ status: 'live', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
