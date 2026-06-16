const admin = require('firebase-admin');
//b
// Initialize Firebase Admin SDK
const serviceAccount = require('./service.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const message = {
  notification: {
    title: 'Hello!',
    body: 'This is a test notification.',
  },
  token: 'cEmSwo4hT8-FCEtllxUdVk:APA91bFjB8LlovEC-_qR-7hSxK8rIA-i5_5D1ldaF8BgsqaT8CkOUkg9O6P8vbj8euDG-_IODXmSru1cb1klKXm8v2cN8qPdEmK48SfoDTl41yXCj1g0k_M', // Your FCM Token
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.error('Error sending message:', error);
  });
