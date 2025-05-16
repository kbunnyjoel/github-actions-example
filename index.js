const math = require('./math');

const num1 = Number(process.env.NUMBER1 || 0);
const num2 = Number(process.env.NUMBER2 || 0);

console.log(`Adding ${num1} and ${num2}`);
console.log('Result:', num1 + num2);
