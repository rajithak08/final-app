const mongoose = require('mongoose')

const UserSchema = mongoose.Schema({
    name: { type: String },
    role: { type: String },
    email: String,
    phone: String,
    otp: String,
    otp_expires_at: Date,
    fcmToken: String,
    isDriver: Boolean,
    Aadhar_url: String,
    License_url: String,
    created_at: { type: Date, default: Date.now },
    joined_pools: [{
        id: String,
        driver_phone: String,
        driver_email: String,
        driver_fcms: String,
        booking_type: { type: String, enum: ['single', 'full'] }, // Enum added here
        pickupLocation: String,
        dropoffLocation: String,
        startTime: String,
        startdate: String,
    }],
    history: [{
        id: String,
        driver_phone: String,
        driver_email: String,
        driver_fcms: String,
        booking_type: { type: String, enum: ['single', 'full'] }, // Enum added here
        pickupLocation: String,
        dropoffLocation: String,
        startTime: String,
        startdate: String,
    }],
    updated_at: { type: Date, default: Date.now }
})

module.exports = mongoose.model('User', UserSchema)
