const mongoose = require('mongoose');

// Configurar timeout mayor para las pruebas
jest.setTimeout(30000);

// Configurar env para pruebas
process.env.NODE_ENV = 'test';

beforeAll(async () => {
    // Cerrar conexiones existentes
    if (mongoose.connection.readyState !== 0) {
        await mongoose.connection.close();
    }

    // Limpiar modelos existentes
    if (mongoose.models.User) {
        delete mongoose.models.User;
    }

    // Configurar una base de datos de pruebas
    const testDbUri = process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/logindb_test';

    try {
        await mongoose.connect(testDbUri);
        console.log('Connected to test database');
    } catch (error) {
        console.error('Error connecting to test database:', error);
    }
});

afterAll(async () => {
    // Limpiar base de datos y cerrar conexión
    if (mongoose.connection.readyState !== 0) {
        try {
            await mongoose.connection.db.dropDatabase();
            await mongoose.connection.close();
        } catch (error) {
            console.error('Error during cleanup:', error);
        }
    }

    // Limpiar modelos
    if (mongoose.models.User) {
        delete mongoose.models.User;
    }
});

beforeEach(async () => {
    // Limpiar colecciones antes de cada test
    if (mongoose.connection.readyState !== 0) {
        const collections = mongoose.connection.collections;
        for (const key in collections) {
            const collection = collections[key];
            try {
                await collection.deleteMany({});
            } catch (error) {
                console.error('Error clearing collection:', error);
            }
        }
    }
});
