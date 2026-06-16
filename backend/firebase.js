const admin = require('firebase-admin');
const serviceAccount = require('./service.json'); // Replace with your service account file

if (!admin.apps.length) {
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
}
module.exports = admin;
