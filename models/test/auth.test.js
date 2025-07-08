const request = require('supertest');
const app = require('../../app.js');

describe('Auth Routes', () => {
  const testUser = {
    username: 'testuser',
    password: 'TestPass123!',
  };

  beforeEach(async () => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await require('../models/user').deleteMany({ username: testUser.username }).exec();
  });

  it('should register a user', async () => {
    const res = await request(app).post('/register').send(testUser);
    expect(res.statusCode).toBe(200);
  });

  it('should login a user', async () => {
    await request(app).post('/register').send(testUser); // Registrar primero
    const res = await request(app).post('/authenticate').send(testUser);
    expect(res.statusCode).toBe(200);
  });

  it('should NOT login with wrong password', async () => {
    const res = await request(app).post('/authenticate').send({
      username: testUser.username,
      password: 'wrongpassword',
    });
    expect(res.statusCode).toBe(500);
  });
});