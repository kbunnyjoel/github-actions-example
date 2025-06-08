

const express = require('express');
const bodyParser = require('body-parser');
const { add } = require('./math');

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get('/', (req, res) => {
  res.send(`
    <form method="POST" action="/add">
      <input type="number" name="a" step="any" required />
      +
      <input type="number" name="b" step="any" required />
      <button type="submit">Add</button>
    </form>
  `);
});

app.post('/add', (req, res) => {
  const a = parseFloat(req.body.a);
  const b = parseFloat(req.body.b);
  if (isNaN(a) || isNaN(b)) {
    return res.status(400).send('Invalid numbers provided.');
  }
  const result = add(a, b);
  res.send(`<h1>${a} + ${b} = ${result}</h1>`);
});

module.exports = app;
