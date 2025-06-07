const request = require('supertest');
const { app, server } = require('../index'); // Destructure app and server

describe('Addition API', () => {
  // Close the server after all tests are done
  afterAll((done) => {
    server.close(done);
  });
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
    [-0.0000001, 0.0000001, 0]
  ])('adds %p + %p = %p', async (a, b, expected) => {
    const response = await request(app)
      .post('/add')
      .send({ num1: a, num2: b }) // Changed to num1, num2
      .expect('Content-Type', /json/)
      .expect(200);

    if (Number.isNaN(expected)) {
      expect(Number.isNaN(response.body.result)).toBe(true);
    } else {
      expect(response.body.result).toBeCloseTo(expected, 5);
    }
  });

  test('returns 400 when inputs are missing', async () => {
    const response = await request(app)
      .post('/add')
      .send({})
      .expect(400);
    expect(response.body.error).toBeDefined();
  });

  test('returns 400 when num1 is missing', async () => {
    const response = await request(app)
      .post('/add')
      .send({ num2: 5 })
      .expect('Content-Type', /json/)
      .expect(400);
    expect(response.body.error).toBeDefined();
    // Consider checking for a specific error message if your API provides one
    // e.g., expect(response.body.error).toBe('Input num1 is required.');
  });

  test('returns 400 when num2 is missing', async () => {
    const response = await request(app)
      .post('/add')
      .send({ num1: 5 })
      .expect('Content-Type', /json/)
      .expect(400);
    expect(response.body.error).toBeDefined();
  });

  test('returns 400 when num1 is an empty string', async () => {
    const response = await request(app)
      .post('/add')
      .send({ num1: '', num2: 5 })
      .expect('Content-Type', /json/)
      .expect(400);
    expect(response.body.error).toBeDefined();
  });

  test('returns 400 when num2 is an empty string', async () => {
    const response = await request(app)
      .post('/add')
      .send({ num1: 5, num2: '' })
      .expect('Content-Type', /json/)
      .expect(400);
    expect(response.body.error).toBeDefined();
  });
});
