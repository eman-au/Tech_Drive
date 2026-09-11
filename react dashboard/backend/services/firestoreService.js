/**
 * Service to interact with Cloud Firestore via the Admin SDK.
 */
const { db } = require('../config/firebaseAdmin');

class FirestoreService {
  /**
   * Create a new document in a collection
   * @param {string} collectionName 
   * @param {string} docId 
   * @param {object} data 
   */
  static async createDocument(collectionName, docId, data) {
    try {
      await db.collection(collectionName).doc(docId).set(data);
      return { success: true, id: docId };
    } catch (error) {
      console.error(`Error creating document in ${collectionName}:`, error);
      throw error;
    }
  }

  /**
   * Get a document by ID
   * @param {string} collectionName 
   * @param {string} docId 
   */
  static async getDocument(collectionName, docId) {
    try {
      const doc = await db.collection(collectionName).doc(docId).get();
      if (!doc.exists) return null;
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      console.error(`Error getting document from ${collectionName}:`, error);
      throw error;
    }
  }
}

module.exports = FirestoreService;
