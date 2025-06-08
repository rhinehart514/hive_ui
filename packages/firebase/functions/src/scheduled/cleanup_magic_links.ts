import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

/**
 * Scheduled function that runs daily to clean up expired magic links
 * from the Firestore database.
 * 
 * This helps maintain database hygiene and reduces unnecessary storage costs.
 */
export const cleanupExpiredMagicLinks = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    try {
      logger.info('Starting scheduled cleanup of expired magic links');

      // Get the current server timestamp
      const now = admin.firestore.Timestamp.now();

      // Query for expired magic links
      const expiredLinksQuery = admin.firestore()
        .collection('magicLinks')
        .where('expiresAt', '<', now)
        .limit(500); // Process in batches to avoid timeout

      // Get the documents
      const expiredLinksSnapshot = await expiredLinksQuery.get();
      
      if (expiredLinksSnapshot.empty) {
        logger.info('No expired magic links found');
        return null;
      }

      // Delete expired links in a batch
      const batch = admin.firestore().batch();
      let deleteCount = 0;

      expiredLinksSnapshot.forEach(doc => {
        batch.delete(doc.ref);
        deleteCount++;
      });

      // Commit the batch
      await batch.commit();
      
      logger.info(`Successfully deleted ${deleteCount} expired magic links`);

      // If we hit the limit, there might be more expired links to delete
      if (deleteCount >= 500) {
        logger.info('Reached batch limit. More expired links may remain.');
      }

      return null;
    } catch (error) {
      logger.error('Error cleaning up expired magic links:', error);
      // Don't throw - scheduled functions should handle errors gracefully
      return null;
    }
  }); 