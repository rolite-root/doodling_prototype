const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.storeMACAddress = functions.auth.user().onCreate((user) => {
  const macAddress = user.macAddress; // Passed in when registering
  return admin.firestore().collection('users').doc(user.uid).set({
    email: user.email,
    macAddress: macAddress
  });
});
