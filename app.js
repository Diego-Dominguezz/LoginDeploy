const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');

// const dotenv = require('dotenv');

require('dotenv').config();
const mongoose = require('mongoose');
const packageJson = require('./package.json');

// App version for logging and monitoring (from package.json)
const APP_VERSION = packageJson.version;

// Enhanced logging function
const log = (message, level = 'INFO') => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${level}] [v${APP_VERSION}] ${message}`);
};

// Configuración de MongoDB URI con fallback para contenedor local
const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/logindb';
log(`Application starting - Version: ${APP_VERSION}`);
log(`MongoDB URI configurado: ${mongoUri}`);
log(`Environment variables - NODE_ENV: ${process.env.NODE_ENV}, PORT: ${process.env.PORT}`);

// Enable mongoose debugging for better MongoDB logs
mongoose.set('debug', true);
// Conexión de MongoDB Atlas
// const mongo_uri = 'mongodb+srv://alex:1234@deswebpro.5s0hk.mongodb.net/?retryWrites=true&w=majority&appName=DesWebPro';

// Conexión de MongoDB desde .env
// dotenv.config();
// const mongo_uri = process.env.MONGODB_URI;

// Conexión a MongoDB
async function connectDB() {
    try {
        log('Attempting to connect to MongoDB...', 'INFO');
        log(`Connection string: ${mongoUri}`, 'DEBUG');

        await mongoose.connect(mongoUri, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
            socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
        });

        log(`Successfully connected to MongoDB at ${mongoUri}`, 'SUCCESS');

        // Test the connection
        const admin = mongoose.connection.db.admin();
        const result = await admin.ping();
        log(`MongoDB ping result: ${JSON.stringify(result)}`, 'DEBUG');

    } catch (err) {
        log(`Error connecting to MongoDB: ${err.message}`, 'ERROR');
        log(`Full error: ${JSON.stringify(err, null, 2)}`, 'ERROR');

        // Log connection state
        log(`Mongoose connection state: ${mongoose.connection.readyState}`, 'DEBUG');
        // 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
    }
}

// Add connection event listeners for better monitoring
mongoose.connection.on('connected', () => {
    log('Mongoose connected to MongoDB', 'SUCCESS');
});

mongoose.connection.on('error', (err) => {
    log(`Mongoose connection error: ${err}`, 'ERROR');
});

mongoose.connection.on('disconnected', () => {
    log('Mongoose disconnected from MongoDB', 'WARNING');
});

// Define el esquema y modelo de usuario
const userSchema = new mongoose.Schema({
    username: { type: String, required: true },
    password: { type: String, required: true }
}, { collection: 'user' }); // Especifica el nombre de la colección

const User = mongoose.model('User', userSchema);

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

connectDB();

// Ruta para registrar un nuevo usuario
app.post('/register', async (req, res) => {
    const { username, password } = req.body;

    // Validar campos requeridos
    if (!username || !password) {
        return res.status(500).send('Username y password son requeridos');
    }

    try {
        // Eccripta la contraseña
        const hashedPassword = await bcrypt.hash(password, 10);

        const user = new User({ username, password: hashedPassword });
        await user.save(); // Guarda el usuario en la base de datos
        res.redirect('index.html'); // Redirige a login.html en caso de éxito
    } catch (err) {
        res.status(500).send('Error al registrar');
    }
});

// Ruta para autenticar un usuario
app.post('/authenticate', async (req, res) => {
    const { username, password } = req.body;

    try {
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(500).send('NO existe');
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (isMatch) {
            return res.redirect('/main.html'); // Redirige a inicio.html en caso de éxito
        } else {
            return res.status(500).send('Error en usuario o contraseña');
        }
    } catch (err) {
        res.status(500).send('Error al autenticar');
    }
});
const session = require('express-session');

app.use(session({
    secret: process.env.SESSION_SECRET || 'secret-key',
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Cambiar a true si usas HTTPS
}));

app.get('/logout', (req, res) => {
    if (req.session) {
        // Destruye la sesión
        req.session.destroy(err => {
            if (err) {
                return res.status(500).send('Error al cerrar sesión');
            }
            res.redirect('/index.html'); // Redirige a la página de inicio de sesión
        });
    } else {
        res.redirect('/index.html'); // Si no hay sesión, redirige de todas formas
    }
});

// Solo iniciar el servidor si no estamos en modo test
const server = app.listen(3000, () => {
    log(`Server started on port 3000 - Version: ${APP_VERSION}`, 'SUCCESS');
    log(`Process ID: ${process.pid}`, 'INFO');
    log(`Node.js version: ${process.version}`, 'INFO');
    log(`MongoDB connection state: ${mongoose.connection.readyState}`, 'INFO');
});

// Graceful shutdown
process.on('SIGINT', () => {
    log('Received SIGINT, shutting down gracefully...', 'INFO');
    server.close(() => {
        log('HTTP server closed', 'INFO');
        mongoose.connection.close(false, () => {
            log('MongoDB connection closed', 'INFO');
            process.exit(0);
        });
    });
});

process.on('SIGTERM', () => {
    log('Received SIGTERM, shutting down gracefully...', 'INFO');
    server.close(() => {
        log('HTTP server closed', 'INFO');
        mongoose.connection.close(false, () => {
            log('MongoDB connection closed', 'INFO');
            process.exit(0);
        });
    });
});

module.exports = app;
