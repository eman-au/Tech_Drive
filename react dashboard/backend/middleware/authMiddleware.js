/**
 * Middleware to verify Firebase ID tokens.
 * This intercepts incoming requests to protected routes, checks for an Authorization header,
 * and verifies the token using the Firebase Admin SDK.
 */
const { adminAuth } = require('../config/firebaseAdmin');

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    // Verify the token using Firebase Admin
    const decodedToken = await adminAuth.verifyIdToken(idToken);
    
    // Attach the decoded token (which includes the user's uid) to the request object
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying token:', error);
    return res.status(403).json({ error: 'Unauthorized: Invalid or expired token' });
  }
};

module.exports = { verifyToken };
