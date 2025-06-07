const request = require('supertest');
const app = require('../index');

describe('Addition API', () => {
  test.each([
    [1, 2, 3],
    [-1, -2, -3],
    [2.5, 3.1, 5.6],
    [-8.1, 0, -8.1],
    [-8.9, -1.9, -10.8],
    [9999, 1, 10000],
    [0, 0, 0],
    [Number.MAX_SAFE_INTEGER, 1, Number.MAX_SAFE_INTEGER + 1],
    [-0.1, 0.1, 0],
    [0.0001, 0.0002, 0.0003],
    [-9999.999, -0.001, -10000.0],
    [Number.MIN_SAFE_INTEGER, -1, Number.MIN_SAFE_INTEGER - 1],
    [Number.MAX_VALUE, 1, Number.MAX_VALUE + 1],
    [-0.0000001, 0.0000001, 0],
    [Infinity, -Infinity, NaN],
    [NaN, 1, NaN],
    ['a', 2, NaN],
    [2, 'b', NaN],
    [null, 1, NaN],
    [1, undefined, NaN],
    [undefined, undefined, NaN]
  ])('adds %p + %p = %p', async (a, b, expected) => {
    const response = await request(app)
      .post('/add')
      .send({ a, b })
      .expect('Content-Type', /json/)
      .expect(200);

    if (Number.isNaN(expected)) {
      expect(Number.isNaN(response.body.result)).toBe(true);
    } else {
      expect(response.body.result).toBeCloseTo(expected);
    }
  });

  test('returns 400 when inputs are missing', async () => {
    const response = await request(app)
      .post('/add')
      .send({})
      .expect(400);
    expect(response.body.error).toBeDefined();
  });
});
