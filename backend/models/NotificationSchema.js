const mongoose = require('mongoose');

const NotificationSchema = mongoose.Schema({
    recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, required: true }, // e.g., 'RIDE_BOOKED', 'RIDE_CANCELLED'
    title: { type: String, required: true },
    message: { type: String, required: true },
    data: { type: Object }, // Additional data related to the notification
    read: { type: Boolean, default: false },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notification', NotificationSchema);
