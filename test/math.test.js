// math.test.js

// Import the function we want to test
const { add } = require('../math');

// Describe block groups related tests
describe('Math functions', () => {

  // 'it' or 'test' defines a single test case
  it('should correctly add two numbers', () => {
    // Use Jest's expect function to make assertions
    expect(add(1, 2)).toBe(3); // Test case 1: 1 + 2 should be 3
    expect(add(-1, 5)).toBe(4); // Test case 2: -1 + 5 should be 4
    expect(add(0, 0)).toBe(0);   // Test case 3: 0 + 0 should be 0
  });

  // You could add more test cases here if needed
  // it('should handle floating point numbers', () => {
  //   expect(add(0.1, 0.2)).toBeCloseTo(0.3); // Use toBeCloseTo for floats
  // });

});
