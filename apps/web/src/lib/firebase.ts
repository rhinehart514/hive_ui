import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getFunctions } from 'firebase/functions';

const firebaseConfig = {
  apiKey: "AIzaSyBcVRrMLPFHe7Z9mR9Lpe8sKx9k0vP8k0s",
  authDomain: "hive-9265c.firebaseapp.com",
  databaseURL: "https://hive-9265c-default-rtdb.firebaseio.com",
  projectId: "hive-9265c",
  storageBucket: "hive-9265c.appspot.com",
  messagingSenderId: "573191826528",
  appId: "1:573191826528:web:3f69854745f8ec41c1a705",
  measurementId: "G-XXXXXXXXXX"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const functions = getFunctions(app);

// Note: Emulator connections disabled for now to avoid development issues
// We'll use the production Firebase instance for testing

export default app; 