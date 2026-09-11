/**
 * Service to interact with Firebase Storage via the Admin SDK.
 */
const { storage } = require('../config/firebaseAdmin');

class StorageService {
  /**
   * Generates a signed URL for a file in the bucket.
   * @param {string} filePath - The path to the file in the storage bucket
   * @returns {string} Signed URL valid for 1 hour
   */
  static async getSignedUrl(filePath) {
    try {
      const bucket = storage.bucket();
      const file = bucket.file(filePath);

      const [url] = await file.getSignedUrl({
        version: 'v4',
        action: 'read',
        expires: Date.now() + 60 * 60 * 1000, // 1 hour
      });

      return url;
    } catch (error) {
      console.error('Error generating signed URL:', error);
      throw error;
    }
  }
}

module.exports = StorageService;
