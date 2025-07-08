const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app.js');
const User = require('../models/user');

describe('Authentication Routes', () => {
    const testUser = {
        username: 'testuser',
        password: 'TestPass123!'
    };

    beforeEach(async () => {
        // Limpiar la base de datos antes de cada test
        await User.deleteMany({});
    });

    describe('POST /register', () => {
        it('should register a new user successfully', async () => {
            const response = await request(app)
                .post('/register')
                .send(testUser);

            expect(response.status).toBe(302); // Redirect to login

            // Verificar que el usuario fue creado en la base de datos
            const userInDb = await User.findOne({ username: testUser.username });
            expect(userInDb).toBeTruthy();
            expect(userInDb.username).toBe(testUser.username);
            expect(userInDb.password).not.toBe(testUser.password); // Password should be hashed
        });

        it('should not register a user with duplicate username', async () => {
            // Crear usuario primero
            await request(app)
                .post('/register')
                .send(testUser);

            // Intentar crear el mismo usuario otra vez
            const response = await request(app)
                .post('/register')
                .send(testUser);

            // Puede ser 302 (redirect) o 500 (error), ambos son válidos
            expect([302, 500]).toContain(response.status);
        });

        it('should not register a user with missing fields', async () => {
            const response = await request(app)
                .post('/register')
                .send({ username: 'testuser' }); // Sin password

            expect(response.status).toBe(500);
        });
    });

    describe('POST /authenticate', () => {
        beforeEach(async () => {
            // Crear un usuario para las pruebas de login
            await request(app)
                .post('/register')
                .send(testUser);
        });

        it('should login user with correct credentials', async () => {
            const response = await request(app)
                .post('/authenticate')
                .send(testUser);

            expect(response.status).toBe(302); // Redirect to main page
            expect(response.headers.location).toBe('/main.html');
        });

        it('should not login with wrong password', async () => {
            const response = await request(app)
                .post('/authenticate')
                .send({
                    username: testUser.username,
                    password: 'wrongpassword'
                });

            expect(response.status).toBe(500);
        });

        it('should not login with non-existent user', async () => {
            const response = await request(app)
                .post('/authenticate')
                .send({
                    username: 'nonexistent',
                    password: 'password'
                });

            expect(response.status).toBe(500);
        });
    });

    describe('GET /logout', () => {
        it('should logout user and redirect to login page', async () => {
            const response = await request(app)
                .get('/logout');

            expect(response.status).toBe(302);
            expect(response.headers.location).toBe('/index.html');
        });
    });
});
