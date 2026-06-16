const admin = require('firebase-admin');
const Notification = require('../models/NotificationSchema');
const User = require('../models/UserSchema');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
    const serviceAccount = require('../service.json'); // Explicitly provide the service account key
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

const notificationService = {
    async sendNotification(userId, title, message, data = {}) {
        try {
            // Create notification in the database
            const notification = new Notification({
                recipient: userId,
                type: data.type || 'GENERAL',
                title,
                message,
                data,
            });
            await notification.save();

            // Get user's FCM token
            const user = await User.findById(userId);
            if (!user || !user.fcmToken) {
                console.log('User not found or FCM token not available');
                return null;
            }

            // Prepare FCM notification
            const fcmMessage = {
                notification: { title, body: message },
                data: { ...data, notificationId: notification._id.toString() },
                token: user.fcmToken,
            };

            // Send notification
            const response = await admin.messaging().send(fcmMessage);
            console.log('Successfully sent notification:', response);
            return notification;
        } catch (error) {
            console.error('Error sending notification:', error.message, error.stack);
            throw error;
        }
    },

    async getNotifications(userId) {
        try {
            return await Notification.find({ recipient: userId })
                .sort({ createdAt: -1 }); // Sort by creation date (newest first)
        } catch (error) {
            console.error('Error fetching notifications:', error.message, error.stack);
            throw error;
        }
    },

    async markAsRead(userId, notificationId) {
        try {
            const notification = await Notification.findOne({ _id: notificationId, recipient: userId });
            if (!notification) {
                throw new Error('Notification not found or unauthorized');
            }
            notification.read = true;
            await notification.save();
            return notification;
        } catch (error) {
            console.error('Error marking notification as read:', error.message, error.stack);
            throw error;
        }
    },
};

module.exports = notificationService;