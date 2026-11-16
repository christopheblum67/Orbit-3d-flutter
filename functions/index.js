'use strict';

const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {createHandlers} = require('./pairing_handlers');

initializeApp();
const handlers = createHandlers({db: getFirestore(), authService: getAuth(), Timestamp, HttpsError});
const options = {enforceAppCheck: true, region: 'europe-west9'};
for (const [name, handler] of Object.entries(handlers)) {
  exports[name] = onCall(options, handler);
}
