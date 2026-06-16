const express = require('express');
require('dotenv').config();
const { MongoClient, ServerApiVersion } = require('mongodb');
const app = express();
const port = process.env.PORT || 3000;
const cors = require('cors');
const { mongo, default: mongoose } = require('mongoose');
app.listen(port, () => {
    console.log(`Server is running on http://0.0.0.0:${port}`);
  });

// MongoDB connection string
const uri = process.env.MONGO_URI || 'mongodb+srv://sensorsyncinnovation:SreeH2025!@cluster0.jpksx.mongodb.net/pool_mate';
// const uri = 'mongodb+srv://koushik:koushik@cluster0.h2lzgvs.mongodb.net/pool_mate';

// Middleware
app.get("/", function (req, res){res.send('yo')})
app.use(express.json());
app.use(function (req , res , next) { 
  console.log(req.body);
  console.log(req.url  , req.method  , req.headers['authorization']);
  next();
 })
app.use(cors());
// Connect to MongoDB
async function connectDB() {
  try {
    await mongoose.connect(uri)
    console.log("Connected to MongoDB!");
  } catch (error) {
    console.error("Failed to connect to MongoDB:", error);
  }
}
connectDB();

const notificationRoutes = require('./routes/notification');

app.use('/' , require("./routes/User"))
app.use('/' , require("./routes/Rides"))
app.use('/api/notifications', notificationRoutes);
// // MongoDB Collection Reference
// app.get('/pool/:carPoolId', async (req, res) => {
//     try {
//       const carPoolId = req.params.carPoolId;
  
//       console.log('Car Pool ID received:', carPoolId);
  
//       const query = {
//         $or: [
//           { carPoolId: String(carPoolId) },
//           { carPoolId: Number(carPoolId) }
//         ]
//       };
  
//       console.log('Query:', query);
  
//       const carPool = await poolCollection.findOne(query);
  
//       if (!carPool) {
//         console.log('No car pool found for the query:', query);
//         return res.status(404).json({ message: 'Car pool not found' });
//       }
  
//       res.status(200).json(carPool);
//     } catch (error) {
//       console.error('Error fetching car pool:', error.message);
//       res.status(500).json({ error: 'Failed to fetch car pool details' });
//     }
//   });



//   app.get('/pools', async (req, res) => {
//     try {
//       // Fetch all car pools without any filter
//       const carPools = await poolCollection.find().toArray();
  
//       if (carPools.length === 0) {
//         console.log('No car pools found');
//         return res.status(404).json({ message: 'No car pools found' });
//       }
  
//       res.status(200).json(carPools);
//     } catch (error) {
//       console.error('Error fetching car pools:', error.message);
//       res.status(500).json({ error: 'Failed to fetch car pool details' });
//     }
// });

// // 2. **POST** - Create a new car pool
// app.post('/pool', async (req, res) => {
//   const {
//     carPoolId,
//     source,
//     destination,
//     seats,
//     startTime,
//     driverId,
//     chatRoomId,
//     createdAt,
//     updatedAt,
//   } = req.body;

//   // Check for missing required fields
//   if (
//     !carPoolId ||
//     !source ||
//     !destination ||
//     !seats ||
//     !startTime ||
//     !driverId ||
//     !chatRoomId
//   ) {
//     return res.status(400).json({ error: 'Missing required fields in request body' });
//   }

//   // Ensure carPoolId is unique
//   const existingCarPool = await poolCollection.findOne({ carPoolId });
//   if (existingCarPool) {
//     return res.status(400).json({ error: 'Car pool with this carPoolId already exists' });
//   }

//   const newCarPool = {
//     carPoolId,
//     source,
//     destination,
//     seats,
//     startTime,
//     driverId,
//     chatRoomId,
//     createdAt: createdAt || new Date(),
//     updatedAt: updatedAt || new Date(),
//   };

//   try {
//     const result = await poolCollection.insertOne(newCarPool);
//     res.status(201).json({ message: 'Car pool created successfully!', poolId: result.insertedId });
//   } catch (error) {
//     console.error('Error creating car pool:', error.message);
//     res.status(500).json({ error: 'Failed to create car pool' });
//   }
// });

// // 3. **PUT** - Update car pool details by `carPoolId`
// app.put('/pool/:carPoolId', async (req, res) => {
//   const carPoolId = req.params.carPoolId;
//   const updates = req.body;

//   // Check for empty update fields
//   if (!updates || Object.keys(updates).length === 0) {
//     return res.status(400).json({ error: 'No updates provided in request body' });
//   }

//   try {
//     const result = await poolCollection.updateOne(
//       { carPoolId }, // Find the car pool by carPoolId
//       { $set: updates, $currentDate: { updatedAt: true } } // Update fields
//     );

//     if (result.matchedCount > 0) {
//       res.json({ message: 'Car pool updated successfully!' });
//     } else {
//       res.status(404).json({ message: 'Car pool not found to update' });
//     }
//   } catch (error) {
//     console.error('Error updating car pool:', error.message);
//     res.status(500).json({ error: 'Failed to update car pool' });
//   }
// });


// app.delete('/pool/:carPoolId', async (req, res) => {
//     const carPoolId = req.params.carPoolId;
  
//     try {
//       const result = await poolCollection.deleteOne({ carPoolId }); 
  
//       if (result.deletedCount > 0) {
//         res.json({ message: 'Car pool deleted successfully!' });
//       } else {
//         res.status(404).json({ message: 'Car pool not found to delete' });
//       }
//     } catch (error) {
//       console.error('Error deleting car pool:', error.message);
//       res.status(500).json({ error: 'Failed to delete car pool' });
//     }
//   });


//   // Source Collection Ref
// // 1. **GET** - Retrieve source by `sourceId`
// app.get('/source/:sourceId', async (req, res) => {
//   const sourceId = req.params.sourceId;

//   try {
//     const source = await sourceCollection.findOne({ sourceId });

//     if (!source) {
//       return res.status(404).json({ message: 'Source not found' });
//     }

//     res.status(200).json(source);
//   } catch (error) {
//     console.error('Error fetching source:', error.message);
//     res.status(500).json({ error: 'Failed to fetch source' });
//   }
// });

// app.get('/sources', async (req, res) => {
//     try {
//       // Fetch all documents and project only the location field
//       const sources = await sourceCollection.find({}, { projection: { location: 1, _id: 0 } }).toArray();
  
//       // Check if any sources are found
//       if (!sources || sources.length === 0) {
//         return res.status(404).json({ message: 'No sources found' });
//       }
  
//       // Extract the location names into an array
//       const locations = sources.map((source) => source.location);
  
//       // Send the array of locations as the response
//       res.status(200).json(locations);
//     } catch (error) {
//       console.error('Error fetching sources:', error); // Log full error for debugging
//       res.status(500).json({ error: 'Failed to fetch sources' });
//     }
//   });
  
  

// // 2. **POST** - Create a new source
// app.post('/source', async (req, res) => {
//   const { sourceId, location } = req.body;

//   if (!sourceId || !location) {
//     return res.status(400).json({ error: 'Missing required fields: sourceId or location' });
//   }

//   const newSource = { sourceId, location };

//   try {
//     const result = await sourceCollection.insertOne(newSource);
//     res.status(201).json({ message: 'Source created successfully!', sourceId: result.insertedId });
//   } catch (error) {
//     console.error('Error creating source:', error.message);
//     res.status(500).json({ error: 'Failed to create source' });
//   }
// });




// // 3. **PUT** - Update source by `sourceId`
// app.put('/source/:sourceId', async (req, res) => {
//   const sourceId = req.params.sourceId;
//   const updates = req.body;

//   if (!updates || Object.keys(updates).length === 0) {
//     return res.status(400).json({ error: 'No updates provided in request body' });
//   }

//   try {
//     const result = await sourceCollection.updateOne(
//       { sourceId },
//       { $set: updates, $currentDate: { updatedAt: true } }
//     );

//     if (result.matchedCount > 0) {
//       res.json({ message: 'Source updated successfully!' });
//     } else {
//       res.status(404).json({ message: 'Source not found to update' });
//     }
//   } catch (error) {
//     console.error('Error updating source:', error.message);
//     res.status(500).json({ error: 'Failed to update source' });
//   }
// });

// // 4. **DELETE** - Delete source by `sourceId`
// app.delete('/source/:sourceId', async (req, res) => {
//   const sourceId = req.params.sourceId;

//   try {
//     const result = await sourceCollection.deleteOne({ sourceId });

//     if (result.deletedCount > 0) {
//       res.json({ message: 'Source deleted successfully!' });
//     } else {
//       res.status(404).json({ message: 'Source not found to delete' });
//     }
//   } catch (error) {
//     console.error('Error deleting source:', error.message);
//     res.status(500).json({ error: 'Failed to delete source' });
//   }
// });
//   // Destination Collection Refer
// // 1. **GET** - Retrieve destination by `destinationId`
// app.get('/destination/:destinationId', async (req, res) => {
//   const destinationId = req.params.destinationId;

//   try {
//     const destination = await destinationCollection.findOne({ destinationId });

//     if (!destination) {
//       return res.status(404).json({ message: 'Destination not found' });
//     }

//     res.status(200).json(destination);
//   } catch (error) {
//     console.error('Error fetching destination:', error.message);
//     res.status(500).json({ error: 'Failed to fetch destination' });
//   }
// });

// app.get('/destinations', async (req, res) => {
//     try {
//       // Fetch all documents and project only the location field
//       const destinations = await destinationCollection.find({}, { projection: { location: 1, _id: 0 } }).toArray();
  
//       // Check if any destinations are found
//       if (!destinations || destinations.length === 0) {
//         return res.status(404).json({ message: 'No destinations found' });
//       }
  
//       // Extract the location names into an array
//       const locations = destinations.map((dest) => dest.location);
  
//       // Send the array of locations as the response
//       res.status(200).json(locations);
//     } catch (error) {
//       console.error('Error fetching destinations:', error.message);
//       res.status(500).json({ error: 'Failed to fetch destinations' });
//     }
//   });
  
  

// // 2. **POST** - Create a new destination
// app.post('/destination', async (req, res) => {
//   const { destinationId, location } = req.body;

//   if (!destinationId || !location) {
//     return res.status(400).json({ error: 'Missing required fields: destinationId or location' });
//   }

//   const newDestination = { destinationId, location };

//   try {
//     const result = await destinationCollection.insertOne(newDestination);
//     res.status(201).json({ message: 'Destination created successfully!', destinationId: result.insertedId });
//   } catch (error) {
//     console.error('Error creating destination:', error.message);
//     res.status(500).json({ error: 'Failed to create destination' });
//   }
// });

// // 3. **PUT** - Update destination by `destinationId`
// app.put('/destination/:destinationId', async (req, res) => {
//   const destinationId = req.params.destinationId;
//   const updates = req.body;

//   if (!updates || Object.keys(updates).length === 0) {
//     return res.status(400).json({ error: 'No updates provided in request body' });
//   }

//   try {
//     const result = await destinationCollection.updateOne(
//       { destinationId },
//       { $set: updates, $currentDate: { updatedAt: true } }
//     );

//     if (result.matchedCount > 0) {
//       res.json({ message: 'Destination updated successfully!' });
//     } else {
//       res.status(404).json({ message: 'Destination not found to update' });
//     }
//   } catch (error) {
//     console.error('Error updating destination:', error.message);
//     res.status(500).json({ error: 'Failed to update destination' });
//   }
// });

// // 4. **DELETE** - Delete destination by `destinationId`
// app.delete('/destination/:destinationId', async (req, res) => {
//   const destinationId = req.params.destinationId;

//   try {
//     const result = await destinationCollection.deleteOne({ destinationId });

//     if (result.deletedCount > 0) {
//       res.json({ message: 'Destination deleted successfully!' });
//     } else {
//       res.status(404).json({ message: 'Destination not found to delete' });
//     }
//   } catch (error) {
//     console.error('Error deleting destination:', error.message);
//     res.status(500).json({ error: 'Failed to delete destination' });
//   }
// });

  

// // Start the server
// app.listen(port, () => {
//   console.log(`Server is running at http://localhost:${port}`);
// });
