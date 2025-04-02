/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export notification functions
export * from "./notifications";

// Re-export events sync functions
export * from "./events_sync";

// Export a simple health check function
export const healthCheck = functions.https.onRequest((request, response) => {
  logger.info("Health check request received");
  response.status(200).send("Firebase Functions for HIVE UI are running");
});
