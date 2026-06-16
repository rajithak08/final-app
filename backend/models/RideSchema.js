const mongoose = require('mongoose');

const RideSchema = mongoose.Schema({
    driver: String,
    driver_phone: String,
    driver_email: String,
    driver_fcms: String,
    passengers: [{
        id: String,
        name: String,
        phoneNumber: String,
        booking_type: { type: String, enum: ['single', 'full'] }, // Enum added here
        email: String,
        fcms_Token: String
    }],
    pickupLocation: {
        type: String,
        required: true
    },
    dropoffLocation: {
        type: String,
        required: true
    },
    date: {
        type: String,
        required: true
    },
    startTime: {
        type: String,
        required: true
    },
    endTime: String,
    distance: Number,
    cost: {
        type: Number,
        required: true,
        min: 0
    },
    seats_available: {
        type: Number,
        required: true,
        min: 1,
        max: 20
    },
    seats_booked: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['open', 'full', 'completed'],
        default: 'open'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Ride', RideSchema);