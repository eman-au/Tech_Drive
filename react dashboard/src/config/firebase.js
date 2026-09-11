import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyA5EZ4Qd6MeXeu3OzMbgSMqg9iNDK5gCVs",
  authDomain: "techdrive-1495f.firebaseapp.com",
  projectId: "techdrive-1495f",
  storageBucket: "techdrive-1495f.firebasestorage.app",
  messagingSenderId: "911869093508",
  appId: "1:911869093508:web:0e87f0de68d9fd76cd84d1",
  measurementId: "G-6QMRZ9JDXL"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;
