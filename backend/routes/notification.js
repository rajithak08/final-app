const express = require('express');
const router = express.Router();
const notificationService = require('../services/notificationService');
const User = require('../models/UserSchema');

// Update FCM token
router.post('/token', async (req, res) => {
    try {
        const { userId, fcmToken } = req.body;
        if (!fcmToken || !userId) {
            return res.status(400).json({ message: 'FCM token and userId are required' });
        }

        await User.findByIdAndUpdate(userId, { fcmToken });
        res.json({ message: 'FCM token updated successfully' });
    } catch (error) {
        console.error('Error updating FCM token:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Get user's notifications
router.get('/:userId', async (req, res) => {
    try {
        const notifications = await notificationService.getNotifications(req.params.userId);
        res.json(notifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Mark notification as read
router.put('/:id/read', async (req, res) => {
    try {
        const notification = await notificationService.markAsRead(req.params.id);
        res.json(notification);
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
