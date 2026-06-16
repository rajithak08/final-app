const express = require('express');
const router = express.Router();
const Rides = require('../models/RideSchema');
const multer = require('multer');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const User = require('../models/UserSchema');
const admin = require('../firebase');
const SECRET_KEY = "your_secret_key"; // Replace with a secure key in production
const my_email = "koushik.p22@iiits.in"

// Configure Nodemailer
const transporter = nodemailer.createTransport({
  service: 'gmail', // Use your preferred email service
  auth: {
    user: my_email, // Your email
    pass: 'evpx kleh ppsv zcsy', // Your email password or app-specific password
  },
     
     
     
});

const sendNotificationToDriverAndPassenger = async (driverFCMToken, seats_available, passengerFCMToken, message) => {
  try {
    console.log(`Sending notification to driver: ${driverFCMToken}`);
    // Send notification to the driver
    const response = await admin.messaging().send({
      token: driverFCMToken,
      notification: {
        title: 'New Passenger Joined Pool',
        body: `A new passenger has joined your pool. ${seats_available} seats are available.`,
      },
    });
    console.log('Notification sent to driver successfully:', response);

    console.log(`Sending notification to passenger: ${passengerFCMToken}`);
    // Send notification to the passenger
    const passengerResponse = await admin.messaging().send({
      token: passengerFCMToken,
      notification: {
        title: 'Joined Pool Successfully',
        body: message,
      },
    });
    console.log('Notification sent to passenger successfully:', passengerResponse);
  } catch (error) {
    console.error('Error sending FCM notification:', error);
  }
};
const sendfullcabNotificationToDriverAndPassenger = async (driverFCMToken, seats_available, passengerFCMToken, message) => {
  try {
    console.log(`Sending notification to driver: ${driverFCMToken}`);
    // Send notification to the driver
    const response = await admin.messaging().send({
      token: driverFCMToken,
      notification: {
        title: 'New Passenger Joined Pool',
        body: `A passenger has booked your full pool. ${seats_available} seats are available.`,
      },
    });
    console.log('Notification sent to driver successfully:', response);

    console.log(`Sending notification to passenger: ${passengerFCMToken}`);
    // Send notification to the passenger
    const passengerResponse = await admin.messaging().send({
      token: passengerFCMToken,
      notification: {
        title: 'Joined Pool Successfully',
        body: message,
      },
    });
    console.log('Notification sent to passenger successfully:', passengerResponse);
  } catch (error) {
    console.error('Error sending FCM notification:', error);
  }
};
async function sendRemovePassengerNotification(fcmToken, pool, message) {
  console.log(`Sending notification to passenger: ${fcmToken}`);
  try {
    // Implement your FCM notification logic here
    // Example: Using Firebase Admin SDK
    const payload = {
      notification: {
        title: 'Pool Update',
        body: message,
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(payload);
    console.log('Notification sent successfully:', response);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// Function to send notifications to user and driver
async function sendLeavePoolNotification(fcmToken, pool, user) {
  const payload = {
    notification: {
      title: 'Pool Update',
      body: `${user.email} has left the pool from ${pool.pickupLocation} to ${pool.dropoffLocation}.`,
    },
    token: fcmToken,
  };

  console.log(`Sending notification to driver: ${fcmToken}`);
  try {
    const response = await admin.messaging().send(payload);
    console.log('Notification sent successfully:', response);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}
async function sendDriverCancelNotification(fcmToken, pool, driver) {
  const payload = {
    notification: {
      title: 'Ride Canceled',
      body: `The driver ${driver.name} has canceled the ride from ${pool.pickupLocation} to ${pool.dropoffLocation}.`,
    },
    token: fcmToken,
  };

  console.log(`Sending notification to passenger: ${fcmToken}`);
  try {
    const response = await admin.messaging().send(payload);
    console.log('Notification sent successfully:', response);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

router.get('/rides', async  (req, res)=> {
  const currentTime = new Date(); // Get the current date and time
  try {
      const rides = await Rides.find({ startTime: { $gt: currentTime } }).exec();
      res.json(rides);
  } catch (err) {
      res.status(500).send(err);
  }
});
router.post('/rides', async (req, res) => {
  try {
    // Validate input fields
    const { 
      pickupLocation, 
      dropoffLocation, 
      date, 
      startTime, 
      cost, 
      seats_available, 
      driver_phone, 
      driver_email 
    } = req.body;

    // Validate date format (YYYY-MM-DD)
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(date)) {
      return res.status(400).json({ message: 'Invalid date format. Use YYYY-MM-DD' });
    }

    // Validate time format (HH:MM AM/PM)
    const timeRegex = /^(0[1-9]|1[0-2]):[0-5][0-9]\s*(AM|PM)$/i;
    if (!timeRegex.test(startTime)) {
      return res.status(400).json({ message: 'Invalid time format. Use HH:MM AM/PM' });
    }

    // Find the user to get FCM token
    const user = await User.findOne({ email: driver_email });

    // Check for existing rides at the same time and location
    const existingRide = await Rides.findOne({
      pickupLocation,
      dropoffLocation,
      date,
      startTime,
      driver_email
    });

    if (existingRide) {
      return res.status(400).json({ message: 'A ride with the same details already exists' });
    }

    // Create new ride
    const ride = new Rides({
      driver: '', // You might want to populate this with user's name if available
      passengers: [],
      pickupLocation,
      dropoffLocation,
      date,
      startTime,
      cost,
      seats_available: Number(seats_available),
      driver_phone,
      driver_email,
      driver_fcms: user ? user.fcmToken : ''
    });

    const savedRide = await ride.save();

    // Send FCM notification if user has a token
    if (user && user.fcmToken) {
      const message = {
        notification: {
          title: 'New Ride Created',
          body: `Hi ${driver_email}, a new ride from ${pickupLocation} to ${dropoffLocation} on ${date} at ${startTime} has been created. The cost of the ride is ${cost} and there are ${seats_available} seats available.`,
        },
        token: user.fcmToken,
      };
      
      try {
        await admin.messaging().send(message);
        console.log('Notification sent successfully to:', user.fcmToken);
      } catch (error) {
        console.error('Error sending notification:', error);
      }
    } else {
      console.warn('No FCM token available for this user.');
    }

    res.status(201).json(savedRide);
  } catch (error) {
    console.error('Ride creation error:', error);
    res.status(500).json({ message: 'Failed to create ride', error: error.message });
  }
});
router.post('/findride', async (req, res) => {
  const { pickupLocation, dropoffLocation, email } = req.body;
  try {
    console.log(`Received request to find ride from ${pickupLocation} to ${dropoffLocation} for user ${email}`);

    // Get current date and time
    const now = new Date();
    const currentDateString = now.toISOString().split('T')[0];

    console.log('Current DateTime:', now);
    console.log('Current Date String:', currentDateString);

    // Fetch rides from database
    const rides = await Rides.find({
      pickupLocation,
      dropoffLocation,
      date: { $gte: currentDateString }
    }).exec();

    console.log(`Fetched ${rides.length} rides from database`);

    const validRides = rides.filter(ride => {
      // Log the ride being checked
      console.log(`Checking ride: date=${ride.date}, startTime=${ride.startTime}, pickup=${ride.pickupLocation}, dropoff=${ride.dropoffLocation}`);

      // Parse ride date and time
      const [hours, minutes] = ride.startTime.split(':');
      const period = ride.startTime.split(' ')[1].toUpperCase();
      
      // Create a date object for the ride time
      const rideDateTime = new Date(ride.date);
      
      // Convert to 24-hour format
      let hours24 = parseInt(hours);
      if (period === 'PM' && hours24 !== 12) {
        hours24 += 12;
      } else if (period === 'AM' && hours24 === 12) {
        hours24 = 0;
      }
      
      rideDateTime.setHours(hours24, parseInt(minutes), 0, 0);
      
      console.log(`Comparing times: rideDateTime=${rideDateTime}, currentDateTime=${now}, isInFuture=${rideDateTime > now}`);

      // Check if user is not already a passenger
      const isNotPassenger = !ride.passengers.some(passenger => passenger.email === email);

      console.log(`Checking if user ${email} is not already a passenger: ${isNotPassenger}`);

      // Return true if ride is in future and user is not a passenger
      return rideDateTime > now && isNotPassenger;
    });

    console.log(`Valid rides found: ${validRides.length}`);
    res.status(200).json(validRides);

  } catch (error) {
    console.error('Error finding rides:', error);
    res.status(500).json({ 
      error: 'Something went wrong while finding rides',
      details: error.message 
    });
  }
});

router.post('/join-pool', async (req, res) => {
  try {
    const { email, poolId } = req.body;

    // Check if pool exists and has available seats
    const pool = await Rides.findById(poolId);
    if (!pool) {
      return res.status(404).json({ message: 'Pool not found' });
    }

    if (pool.seats_available <= 0) {
      return res.status(400).json({ message: 'No seats available in this pool' });
    }

    // Get user details
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if passenger is already in the pool
    const isPassengerAlreadyInPool = pool.passengers.some(
      passenger => passenger.email === email
    );

    if (isPassengerAlreadyInPool) {
      return res.status(400).json({ message: 'You are already a passenger in this pool' });
    }

    // Add user to the pool's passengers list
    const updatedPool = await Rides.findByIdAndUpdate(
      poolId,
      {
        $push: {
          passengers: {
            id: user._id,
            name: user.name,
            phoneNumber: user.phone,
            booking_type:"single",
            email: user.email,
            fcms_Token: user.fcmToken, // Add FCM token of the user
          },
        },
        $inc: { seats_available: -1 }, // Decrease available seats
      },
      { new: true }
    );

    // Add pool to user's joined_pools
    const updatedUser = await User.findOneAndUpdate(
      { email },
      {
        $push: {
          joined_pools: {
            id: poolId,
            driver_phone: pool.driver_phone,
            driver_email: pool.driver_email,
            driver_fcms: pool.driver_fcms,
            pickupLocation: pool.pickupLocation,
            dropoffLocation: pool.dropoffLocation,
            booking_type: "single",
            startTime: pool.startTime,
            startdate: pool.date
          },
        },
      },
      { new: true }
    );

    // Send FCM notifications to driver and user
    const driverFCMToken = pool.driver_fcms;
    const passengerFCMToken = user.fcmToken;
    const message = `You have successfully joined the pool with driver ${pool.driver_email}.`;
    sendNotificationToDriverAndPassenger(driverFCMToken, updatedPool.seats_available, passengerFCMToken, message);
    res.json({
      message: 'Successfully joined pool',
      pool: updatedPool,
      user: updatedUser,
    });
  } catch (error) {
    console.error('Error in joining pool:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }              
});
router.post('/join-pool/full', async (req, res) => {
  try {
    const { email, poolId } = req.body;
    console.log(email, poolId);
    // Check if pool exists and has available seats
    const pool = await Rides.findById(poolId);
    if (!pool) {
      return res.status(404).json({ message: 'Pool not found' });
    }

    if (pool.seats_available <= 0) {
      return res.status(400).json({ message: 'No seats available in this pool' });
    }

    // Get user details
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    console.log(user)
    // Check if passenger is already in the pool
    const isPassengerAlreadyInPool = pool.passengers.some(
      passenger => passenger.email === email
    );

    if (isPassengerAlreadyInPool) {
      return res.status(400).json({ message: 'You are already a passenger in this pool' });
    }

    // Add user to the pool's passengers list
    const updatedPool = await Rides.findByIdAndUpdate(
      poolId,
      {
        $push: {
          passengers: {
            id: user._id,
            name: user.name,
            phoneNumber: user.phone,
            booking_type: "full", 
            email: user.email,
            fcms_Token: user.fcmToken, // Add FCM token of the user
          },
        },
        $set: { seats_available: 0 }, // Set available seats to 0
      },
      { new: true }
    );
    
    // Add pool to user's joined_pools
    const updatedUser = await User.findOneAndUpdate(
      { email },
      {
        $push: {
          joined_pools: {
            id: poolId,
            driver_phone: pool.driver_phone,
            driver_email: pool.driver_email,
            driver_fcms: pool.driver_fcms,
            pickupLocation: pool.pickupLocation,
            dropoffLocation: pool.dropoffLocation,
            booking_type: "full",
            startTime: pool.startTime,
            startdate: pool.date
          },
        },
      },
      { new: true }
    );

    // Send FCM notifications to driver and user
    const driverFCMToken = pool.driver_fcms;
    const passengerFCMToken = user.fcmToken;
    const message = `You have successfully joined the pool with driver ${pool.driver_email}.`;
    sendfullcabNotificationToDriverAndPassenger(driverFCMToken, updatedPool.seats_available, passengerFCMToken, message);
    res.json({
      message: 'Successfully joined pool',
      pool: updatedPool,
      user: updatedUser,
    });
  } catch (error) {
    console.error('Error in joining pool:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }              
});

router.get('/mypools/:email', async (req, res) => {
  try {
      const { email } = req.params;
      const response = await Rides.find({ driver_email: email }).exec();
      if (response.length === 0) {
          return res.status(404).json({ message: 'No pools found for this user' });
      }
      res.status(200).json(response);
  } catch (error) {
      console.log(error);
      res.status(500).json({ message: 'Failed to fetch pools', error });
  }
});

// Delete a pool by Driver
router.delete('/pool/:id', async (req, res) => {
  try {
    const id = req.params.id;
    console.log(`Attempting to delete pool with ID: ${id}`);

    // Find the pool to retrieve passenger and driver data
    const pool = await Rides.findById(id).exec();
    if (!pool) {
      console.log(`Pool ${id} not found`);
      return res.status(404).json({ message: 'Pool not found' });
    }

    console.log(`Pool ${id} found. Proceeding to notify ${pool.passengers.length} passengers`);

    // Driver information
    const driver = {
      name: pool.driver,
    };

    // Notify passengers that the driver has canceled the ride
    const notificationPromises = pool.passengers.map((passenger) =>
      sendDriverCancelNotification(passenger.fcms_Token, pool, driver)
    );

    console.log(`Sending notifications to ${pool.passengers.length} passengers`);

    // Wait for all notifications to be sent
    await Promise.all(notificationPromises);

    console.log('Notifications sent successfully');

    // Prepare pool history entry
    const poolHistoryEntry = {
      id: pool._id,
      driver_phone: pool.driver_phone,
      driver_email: pool.driver_email,
      driver_fcms: pool.driver_fcms,
      pickupLocation: pool.pickupLocation,
      dropoffLocation: pool.dropoffLocation,
      booking_type: pool.booking_type,
      startTime: pool.startTime,
      startdate: pool.date
    };

    console.log(`Preparing pool history entry ${poolHistoryEntry.id}`);

    // Remove the ride from all passengers joined pools and add to history
    const passengersIds = pool.passengers.map(passenger => passenger.id);
    console.log(`Removing ride from ${passengersIds.length} users`);
    const users = await User.find({ _id: { $in: passengersIds } });
    const userPromises = users.map(user => User.findByIdAndUpdate(user._id, 
      {
        $pull: {
          joined_pools: { id: pool._id },
        },
        $push: {
          history: poolHistoryEntry
        }
      }, 
      { new: true }
    ));
    console.log(`Updating history of ${users.length} users`);
    await Promise.all(userPromises);

    console.log('Users updated successfully');

    // Also add to driver's history if applicable
    const driverUser = await User.findOne({ email: pool.driver_email });
    if (driverUser) {
      console.log(`Adding to driver history ${driverUser.email}`);
      await User.findByIdAndUpdate(driverUser._id, 
        {
          $push: {
            history: poolHistoryEntry
          }
        },
        { new: true }
      );
    }

    // Delete the pool
    const response = await Rides.findByIdAndDelete(id).exec();
    if (!response) {
      console.log(`Pool ${id} not found`);
      return res.status(404).json({ message: 'Pool not found' });
    }

    console.log(`Pool ${id} deleted successfully. Added to ${users.length} user histories.`);
    res.status(200).json({ 
      message: 'Pool deleted successfully', 
      usersAffected: users.length 
    });
  } catch (error) {
    console.error(`Error deleting pool ${id}:`, error);
    res.status(500).json({ 
      message: 'Failed to delete pool', 
      error: error.message 
    });
  }
});

// POST: Add a passenger to a pool

router.delete('/leave-pool', async (req, res) => {
  try {
    const { poolId, email } = req.body;

    console.log(`Received request to leave pool ${poolId} from user ${email}`);

    // Step 1: Find the pool and check if the user is in the passengers list
    const pool = await Rides.findById(poolId);
    if (!pool) {
      console.log(`Pool ${poolId} not found`);
      return res.status(404).json({ message: 'Pool not found' });
    }

    console.log(`Pool ${poolId} found, checking if user ${email} is in the passengers list`);

    // Check if the user is in the passengers array
    const passengerIndex = pool.passengers.findIndex(passenger => passenger.email === email);
    if (passengerIndex === -1) {
      console.log(`User ${email} not in the pool`);
      return res.status(400).json({ message: 'User not in the pool' });
    }

    console.log(`User ${email} found in the pool, removing from passengers list`);

    // Step 2: Remove the user from the pool's passengers list
    pool.passengers.splice(passengerIndex, 1);

    pool.seats_available += 1;

    console.log(`Pool updated, saving`);

    // Save the updated pool
    await pool.save();

    console.log(`Pool saved, removing pool from user's joined_pools array`);

    // Step 3: Remove the pool from the user's joined_pools array and add to history
    const user = await User.findOneAndUpdate(
      { email: email },
      { 
        $pull: { joined_pools: { id: poolId } },
        $push: { 
          history: {
            id: pool._id,
            driver_phone: pool.driver_phone,
            driver_email: pool.driver_email,
            driver_fcms: pool.driver_fcms,
            pickupLocation: pool.pickupLocation,
            dropoffLocation: pool.dropoffLocation,
            startTime: pool.startTime
          }
        }
      },
      { new: true }
    );

    if (!user) {
      console.log(`User ${email} not found`);
      return res.status(404).json({ message: 'User not found' });
    }

    console.log(`User ${email} found, sending notifications`);

    // Step 4: Send a notification to the driver and the user (if needed)
    sendLeavePoolNotification(pool.driver_fcms, pool, user);
    sendLeavePoolNotification(user.fcmToken, pool, user);

    console.log(`Notifications sent, returning response`);

    // Return a response indicating success
    res.status(200).json({
      message: 'User successfully left the pool',
      pool,
      user,
    });
  } catch (error) {
    console.error(`Error in leaving pool: ${error}`);
    res.status(500).json({ message: 'Failed to leave pool', error });
  }
});


// GET: Retrieve a particular ride by ID
router.get('/rides/:id', async (req, res) => {
  try {
      const ride = await Rides.findById(req.params.id);
      if (!ride) {
          return res.status(404).json({ message: 'Ride not found' });
      }
      res.status(200).json(ride);
  } catch (error) {
      res.status(500).json({ message: 'Failed to retrieve ride', error });
  }
});
// PUT: Update a particular ride by ID
router.put('/rides/:id', async (req, res) => {
  try {
      const updatedRide = await Rides.findByIdAndUpdate(
          req.params.id,
          {
              driver: req.body.driver,
              passengers: req.body.passengers,
              pickupLocation: req.body.pickupLocation,
              dropoffLocation: req.body.dropoffLocation,
              startTime: req.body.startTime,
              endTime: req.body.endTime,
              distance: req.body.distance,
              cost: req.body.cost,
              seats_availabe: req.body.seats_availabe,
          },
          { new: true } // returns the updated document
      );

      if (!updatedRide) {
          return res.status(404).json({ message: 'Ride not found' });
      }

      res.status(200).json(updatedRide);
  } catch (error) {
      res.status(500).json({ message: 'Failed to update ride', error });
  }
});
// DELETE: Delete a particular ride by ID
router.delete('/rides/:id', async (req, res) => {
  try {
      const deletedRide = await Rides.findByIdAndDelete(req.params.id);
      if (!deletedRide) {
          return res.status(404).json({ message: 'Ride not found' });
      }
      res.status(200).json({ message: 'Ride deleted successfully' });
  } catch (error) {
      res.status(500).json({ message: 'Failed to delete ride', error });
  }
});

// Get joined pools for a user
router.get('/user/joined-pools/:email', async (req, res) => {
  try {
    const user = await User.findOne({ email:  req.params.email });
    if (!user) {
      return res.status(404).json({ 
        message: 'User not found', 
        joinedPools: [],
        history: [] 
      });
    }
    
    // Fetch all rides that the user has joined
    const joinedPools = await Rides.find({ 
      '_id': { $in: user.joined_pools.map(pool => pool.id) } 
    });
    
    console.log({
      joinedPools,
      history: user.history || []
    })

    res.json({
      joinedPools,
      history: user.history || []
    });
  } catch (error) {
    console.error('Error fetching joined pools and history:', error);
    res.status(500).json({ 
      message: 'Failed to fetch joined pools and history', 
      error: error.message,
      joinedPools: [],
      history: [] 
    });
  }
});

// Function to send notification when a passenger is removed
async function sendRemovePassengerNotification(fcmToken, pool, message) {
  const payload = {
    notification: {
      title: 'Passenger Removed',
      body: message,
    },
    token: fcmToken,
  };

  console.log(`Sending notification: ${message}`);
  try {
    await admin.messaging().send(payload);
    console.log('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// DELETE: Remove a passenger from a pool
router.delete('/remove-passenger', async (req, res) => {
  try {
    const { poolId, email } = req.body;

    // Step 1: Find the pool and get the passenger info (needed for notifications)
    const pool = await Rides.findById(poolId);
    if (!pool) {
      return res.status(404).json({ message: 'Pool not found' });
    }

    // Step 2: Remove the passenger from the ride
    const updatedPool = await Rides.findByIdAndUpdate(
      poolId,
      {
        $pull: {
          passengers: { email: email },
        },
        $inc: { seats_available: 1 }, // Increment seats available when a passenger leaves
      },
      { new: true }
    );

    // Step 3: Remove the pool from the user's joined_pools
    const user = await User.findOneAndUpdate(
      { email },
      {
        $pull: {
          joined_pools: { id: poolId },
        },
      },
      { new: true }
    );
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Step 4: Send notification to the user and driver
    const userFcmToken = user.fcmToken; // User's FCM token for notification
    const driverFcmToken = pool.driver_fcms; // Driver's FCM token for notification

    // Send notifications
    if (userFcmToken) {
      await sendRemovePassengerNotification(
        userFcmToken, 
        pool, 
        `You have been removed from the pool from ${pool.pickupLocation} to ${pool.dropoffLocation} on ${pool.date} at ${pool.startTime}. The driver's phone number is ${pool.driver_phone}.`
      );
    }
    // Send the updated pool data as response
    res.status(200).json({
      message: 'Passenger removed successfully',
      updatedPool,
      user,
    });
  } catch (error) {
    console.error('Error removing passenger:', error);
    res.status(500).json({ message: 'Failed to remove passenger', error: error.message });
  }
});

module.exports = router;
