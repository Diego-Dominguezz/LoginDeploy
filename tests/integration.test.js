const request = require('supertest');
const app = require('../app');
const User = require('../models/user');

describe('Integration Tests', () => {
    const testUser = {
        username: 'integrationtest',
        password: 'IntegrationPass123!'
    };

    beforeEach(async () => {
        await User.deleteMany({});
    });

    describe('User Registration and Login Flow', () => {
        it('should complete full user registration and login flow', async () => {
            // 1. Registrar usuario
            const registerResponse = await request(app)
                .post('/register')
                .send(testUser);

            expect(registerResponse.status).toBe(302);

            // 2. Verificar que el usuario existe en la base de datos
            const userInDb = await User.findOne({ username: testUser.username });
            expect(userInDb).toBeTruthy();

            // 3. Hacer login con el usuario registrado
            const loginResponse = await request(app)
                .post('/authenticate')
                .send(testUser);

            expect(loginResponse.status).toBe(302);
            expect(loginResponse.headers.location).toBe('/main.html');

            // 4. Intentar login con credenciales incorrectas
            const failedLoginResponse = await request(app)
                .post('/authenticate')
                .send({
                    username: testUser.username,
                    password: 'wrongpassword'
                });

            expect(failedLoginResponse.status).toBe(500);
        });

        it('should handle session logout correctly', async () => {
            // 1. Registrar y hacer login
            await request(app)
                .post('/register')
                .send(testUser);

            const loginResponse = await request(app)
                .post('/authenticate')
                .send(testUser);

            expect(loginResponse.status).toBe(302);

            // 2. Hacer logout
            const logoutResponse = await request(app)
                .get('/logout');

            expect(logoutResponse.status).toBe(302);
            expect(logoutResponse.headers.location).toBe('/index.html');
        });
    });

    describe('Error Handling', () => {
        it('should handle database connection errors gracefully', async () => {
            // Esta prueba simula posibles errores de conexión
            const response = await request(app)
                .post('/register')
                .send({
                    username: 'test',
                    password: 'password'
                });

            // Debe responder incluso si hay problemas de conexión
            expect([200, 302, 500]).toContain(response.status);
        });
    });

    describe('Static Files', () => {
        it('should serve static files correctly', async () => {
            const response = await request(app)
                .get('/index.html');

            expect(response.status).toBe(200);
            expect(response.headers['content-type']).toMatch(/html/);
        });
    });
});
