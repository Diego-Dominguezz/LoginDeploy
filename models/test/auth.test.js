const request = require('supertest');
const app = require('../../app.js');

describe('Auth Routes', () => {
  const testUser = {
    username: 'testuser',
    password: 'TestPass123!',
  };

  beforeEach(async () => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    const User = require('../../models/user');
    await User.deleteMany({ username: testUser.username });
  });

  it('should register a user', async () => {
    const res = await request(app).post('/register').send(testUser);
    expect(res.statusCode).toBe(302); // Redirect después de registro exitoso
  });

  it('should login a user', async () => {
    await request(app).post('/register').send(testUser); // Registrar primero
    const res = await request(app).post('/authenticate').send(testUser);
    expect(res.statusCode).toBe(302); // Redirect después de login exitoso
  });

  it('should NOT login with wrong password', async () => {
    const res = await request(app).post('/authenticate').send({
      username: testUser.username,
      password: 'wrongpassword',
    });
    expect(res.statusCode).toBe(500);
  });
});