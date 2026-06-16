// Install Twilio SDK: npm install twilio
const twilio = require("twilio");
require('dotenv').config();

// Replace these values with your actual Twilio credentials from process.env
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const client = twilio(accountSid, authToken);

// Send an SMS
async function sendSms() {
  try {
    const message = await client.messages.create({
      body: "Hello, this is a test message from Twilio!",
      from: "MG75d173a98bb31033e1259b85884ad164", // Replace with your Twilio phone number
      to: "+918019570982"   // Replace with the recipient's phone number
    });    console.log(`Message sent with SID: ${message.sid}`);
  } catch (error) {
    console.error(`Failed to send SMS: ${error.message}`);
  }
}

sendSms();
