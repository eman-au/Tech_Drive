/**
 * Controller to handle user-related endpoints.
 * This demonstrates an authenticated route fetching data from Firestore.
 */
const { db } = require('../config/firebaseAdmin');

// GET /api/user/profile
exports.getProfile = async (req, res) => {
  try {
    const uid = req.user.uid;
    
    // Fetch the user's document from the 'users' collection in Firestore
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      // If the user hasn't created a profile in Firestore yet, we can just return the uid
      return res.status(200).json({ 
        message: 'No extended profile found',
        profile: { uid: req.user.uid, email: req.user.email } 
      });
    }

    res.status(200).json({
      profile: {
        id: userDoc.id,
        ...userDoc.data()
      }
    });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Internal server error while fetching profile' });
  }
};
