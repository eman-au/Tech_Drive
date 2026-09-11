/**
 * This file initializes the Firebase Client SDK.
 * The Client SDK is used in this Node.js backend primarily to handle 
 * user sign-up and login logic (returning ID tokens), which simulates 
 * how a frontend application might interact with Firebase Auth.
 */
const { initializeApp } = require("firebase/app");
const { getAuth } = require("firebase/auth");
require("dotenv").config();

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

// Initialize Firebase Client
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

module.exports = { app, auth };
