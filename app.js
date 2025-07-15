const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');

// const dotenv = require('dotenv');

require('dotenv').config();
const mongoose = require('mongoose');

const mongoUri = process.env.MONGODB_URI;
// Conexión de MongoDB Atlas
// const mongo_uri = 'mongodb+srv://alex:1234@deswebpro.5s0hk.mongodb.net/?retryWrites=true&w=majority&appName=DesWebPro';

// Conexión de MongoDB desde .env
// dotenv.config();
// const mongo_uri = process.env.MONGODB_URI;

// Conexión a MongoDB
async function connectDB() {
    try {
        await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
        console.log(`Successfully connected to ${mongoUri}`);
    } catch (err) {
        console.error('Error connecting to MongoDB:', err.message);
    }
}

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
if (process.env.NODE_ENV !== 'test') {
}

module.exports = app;
