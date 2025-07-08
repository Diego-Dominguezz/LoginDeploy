const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    }
}, {
    collection: 'user',
    timestamps: true
});

// Prevenir error de modelo duplicado
module.exports = mongoose.models.User || mongoose.model('User', userSchema);