const request = require('supertest');
const app = require('../app.js');

describe('Basic App Tests', () => {
    test('should respond to GET /', async () => {
        const response = await request(app).get('/');
        expect(response.status).toBe(200);
    });

    test('should respond to POST /register with valid data', async () => {
        const response = await request(app)
            .post('/register')
            .send({
                username: 'testuser',
                password: 'testpass123'
            });
        expect(response.status).toBe(302);
    });

    test('should respond to POST /register with missing data', async () => {
        const response = await request(app)
            .post('/register')
            .send({
                username: 'testuser'
                // Sin password
            });
        expect(response.status).toBe(500);
    });

    test('should respond to POST /authenticate', async () => {
        const response = await request(app)
            .post('/authenticate')
            .send({
                username: 'testuser',
                password: 'testpass123'
            });
        expect([302, 500]).toContain(response.status);
    });
});
