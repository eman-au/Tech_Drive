/**
 * Controller to handle authentication endpoints.
 * This uses the Firebase Client SDK to perform operations like signup, login, and password reset.
 */
const { auth } = require('../config/firebaseClient');
const { 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  sendPasswordResetEmail,
  signOut
} = require('firebase/auth');

// POST /api/auth/signup
exports.signup = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // You might also want to save additional user info in Firestore here
    
    res.status(201).json({
      message: 'User registered successfully',
      uid: user.uid,
      email: user.email
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // Get the ID token to send back to the client
    const idToken = await user.getIdToken();

    res.status(200).json({
      message: 'Login successful',
      token: idToken,
      uid: user.uid,
      email: user.email
    });
  } catch (error) {
    res.status(401).json({ error: 'Invalid credentials or login failed' });
  }
};

// POST /api/auth/reset-password
exports.resetPassword = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    await sendPasswordResetEmail(auth, email);
    res.status(200).json({ message: 'Password reset email sent successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// POST /api/auth/logout
exports.logout = async (req, res) => {
  try {
    await signOut(auth);
    res.status(200).json({ message: 'Logout successful' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
