/**
 * This file initializes the Firebase Admin SDK.
 * The Admin SDK is used for backend operations that require elevated privileges:
 * - Verifying ID tokens sent by clients
 * - Bypassing Firestore security rules for backend logic
 * - Managing Cloud Storage directly
 */
const admin = require("firebase-admin");
require("dotenv").config();

// We extract the private key and handle the \n newline characters properly
// so that the key is parsed correctly from the .env string.
const privateKey = process.env.FIREBASE_PRIVATE_KEY 
  ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') 
  : undefined;

// Initialize Admin SDK using the Service Account credentials
admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: privateKey,
  }),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET
});

const db = admin.firestore();
const storage = admin.storage();
const adminAuth = admin.auth();

module.exports = { admin, db, storage, adminAuth };
