import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { UserRecord } from 'firebase-admin/auth';

/**
 * Cloud Function to set default verified=false claim for new users
 * Triggered on user creation
 */
export const setDefaultVerificationStatus = functions.auth.user().onCreate(async (user: UserRecord) => {
  const uid = user.uid;
  
  try {
    // Set default claims with verified=false
    await admin.auth().setCustomUserClaims(uid, {
      verified: false,
      verified_plus: false,
      verificationLevel: 0, // 0=none, 1=verified, 2=verified+
      // Preserve any existing claims like admin, etc.
      ...(user.customClaims || {})
    });

    // Create a document in user_verifications collection for tracking
    await admin.firestore().collection('user_verifications').doc(uid).set({
      userId: uid,
      status: 'unverified',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      email: user.email || '',
      verificationLevel: 0
    });

    console.log(`Set default verification claims for user ${uid}`);
    return { success: true };
  } catch (error) {
    console.error('Error setting default verification claims:', error);
    throw new functions.https.HttpsError('internal', 'Failed to set verification status');
  }
});

/**
 * Cloud Function to update user verification status based on admin action
 * Triggered when a verification request is approved or rejected
 */
export const processVerificationStatusChange = functions.firestore
  .document('verificationRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const requestId = context.params.requestId;

    // Only process if status changed to 'approved' or 'rejected'
    if (beforeData.status === afterData.status) {
      return null; // No relevant change
    }

    // Extract the necessary data
    const { userId, requestedLevel, spaceId = null, approvedBy = null, rejectedBy = null, rejectionReason = null } = afterData;

    try {
      // Update user_verifications collection
      const verificationRef = admin.firestore().collection('user_verifications').doc(userId);
      
      if (afterData.status === 'approved') {
        console.log(`Approving verification request ${requestId} for user ${userId} at level ${requestedLevel}`);
        
        // Update verification status
        await verificationRef.update({
          status: 'verified',
          verificationLevel: requestedLevel,
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: approvedBy,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Create claim update document to trigger claim update
        await admin.firestore().collection('claimUpdates').add({
          userId: userId,
          verificationLevel: requestedLevel,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processedAt: null,
          status: 'pending'
        });
        
        // If this is a Verified+ (level 2) request with a spaceId, add user as a leader
        if (requestedLevel === 2 && spaceId) {
          const spaceRef = admin.firestore().collection('spaces').doc(spaceId);
          await spaceRef.update({
            leaders: admin.firestore.FieldValue.arrayUnion(userId),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        
        // Send approval notification
        await admin.firestore().collection('notifications').add({
          userId: userId,
          type: 'verification_approved',
          title: requestedLevel === 2 ? 'Verified+ Status Approved' : 'Account Verified',
          body: requestedLevel === 2 
            ? 'Your Verified+ status has been approved! You now have access to create Spaces and other exclusive features.'
            : 'Your account has been verified. Welcome to the verified HIVE community!',
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            verificationLevel: requestedLevel,
            requestId: requestId
          }
        });
        
      } else if (afterData.status === 'rejected') {
        console.log(`Rejecting verification request ${requestId} for user ${userId}`);
        
        // Update verification status
        await verificationRef.update({
          status: 'rejected',
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          rejectedBy: rejectedBy,
          rejectionReason: rejectionReason || 'No reason provided',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Send rejection notification
        await admin.firestore().collection('notifications').add({
          userId: userId,
          type: 'verification_rejected',
          title: requestedLevel === 2 ? 'Verified+ Request Denied' : 'Verification Request Denied',
          body: `Your verification request was denied. Reason: ${rejectionReason || 'No reason provided'}`,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            verificationLevel: requestedLevel,
            requestId: requestId,
            rejectionReason: rejectionReason
          }
        });
      }

      return { success: true };
    } catch (error) {
      console.error('Error processing verification status change:', error);
      throw new functions.https.HttpsError('internal', 'Failed to process verification status change');
    }
});

/**
 * Cloud Function to update user's custom claims when a claim update is requested
 * Triggered when a new document is added to the claimUpdates collection
 */
export const updateUserClaims = functions.firestore
  .document('claimUpdates/{updateId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const { userId, verificationLevel } = data;
    
    if (!userId) {
      console.error('Missing userId in claim update request');
      return null;
    }
    
    try {
      // Get the user record
      const user = await admin.auth().getUser(userId);
      
      // Prepare custom claims
      const currentClaims = user.customClaims || {};
      const newClaims = {
        ...currentClaims,
        verified: verificationLevel >= 1,
        verified_plus: verificationLevel >= 2,
        verificationLevel: verificationLevel
      };
      
      // Set the claims
      await admin.auth().setCustomUserClaims(userId, newClaims);
      
      // Update metadata to help force token refresh
      await admin.firestore().collection('user_metadata').doc(userId).set({
        lastClaimUpdate: admin.firestore.FieldValue.serverTimestamp(),
        claims: newClaims
      }, { merge: true });
      
      // Mark the claim update as processed
      await snapshot.ref.update({
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'completed'
      });
      
      console.log(`Updated claims for user ${userId}, new verification level: ${verificationLevel}`);
      return { success: true };
    } catch (error) {
      console.error('Error updating user claims:', error);
      await snapshot.ref.update({
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'error',
        error: error.message
      });
      throw new functions.https.HttpsError('internal', 'Failed to update user claims');
    }
});

/**
 * Callable function for admins to approve a verification request
 */
export const approveVerifiedPlusClaim = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated and has admin role
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const callerUid = context.auth.uid;
  const callerClaims = context.auth.token;
  
  if (!callerClaims.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can approve verification requests');
  }
  
  const { requestId } = data;
  
  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Request ID is required');
  }
  
  try {
    // Get the request
    const requestDoc = await admin.firestore().collection('verificationRequests').doc(requestId).get();
    
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Verification request not found');
    }
    
    const requestData = requestDoc.data();
    
    // Check if request is pending and for level 2 (Verified+)
    if (requestData.status !== 'pending') {
      throw new functions.https.HttpsError('failed-precondition', 'Request is not in pending status');
    }
    
    if (requestData.requestedLevel !== 2) {
      throw new functions.https.HttpsError('failed-precondition', 'Request is not for Verified+ status');
    }
    
    // Update request status to approved
    await requestDoc.ref.update({
      status: 'approved',
      approvedBy: callerUid,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true, message: 'Verified+ request approved successfully.' };
  } catch (error) {
    console.error('Error approving verification request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to approve verification request');
  }
});

/**
 * Callable function for users to request Verified+ status
 */
export const requestVerifiedPlusClaim = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated and has verified role
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const callerUid = context.auth.uid;
  const callerClaims = context.auth.token;
  
  if (!callerClaims.verified) {
    throw new functions.https.HttpsError('permission-denied', 'User must be verified first');
  }
  
  const { spaceId, reason } = data;
  
  if (!reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Reason for verification is required');
  }
  
  try {
    // Check if user already has a pending request
    const existingRequests = await admin.firestore()
      .collection('verificationRequests')
      .where('userId', '==', callerUid)
      .where('status', '==', 'pending')
      .get();
    
    if (!existingRequests.empty) {
      throw new functions.https.HttpsError('already-exists', 'You already have a pending verification request');
    }
    
    // Get user information
    const user = await admin.auth().getUser(callerUid);
    
    // Create the verification request
    const requestRef = await admin.firestore().collection('verificationRequests').add({
      userId: callerUid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      requestedLevel: 2, // Verified+
      spaceId: spaceId || null,
      reason: reason,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { 
      success: true, 
      requestId: requestRef.id, 
      message: 'Verified+ request submitted successfully.' 
    };
  } catch (error) {
    console.error('Error requesting Verified+ status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit Verified+ request');
  }
});

/**
 * Callable function for users to request verification (level 1)
 */
export const requestVerification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const callerUid = context.auth.uid;
  const callerClaims = context.auth.token;
  
  // Check if the user is already verified
  if (callerClaims.verified) {
    throw new functions.https.HttpsError('failed-precondition', 'User is already verified');
  }
  
  const { reason } = data;
  
  if (!reason) {
    throw new functions.https.HttpsError('invalid-argument', 'Reason for verification is required');
  }
  
  try {
    // Check if user already has a pending request
    const existingRequests = await admin.firestore()
      .collection('verificationRequests')
      .where('userId', '==', callerUid)
      .where('status', '==', 'pending')
      .get();
    
    if (!existingRequests.empty) {
      throw new functions.https.HttpsError('already-exists', 'You already have a pending verification request');
    }
    
    // Get user information
    const user = await admin.auth().getUser(callerUid);
    
    // Create the verification request
    const requestRef = await admin.firestore().collection('verificationRequests').add({
      userId: callerUid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      requestedLevel: 1, // Standard verification
      reason: reason,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { 
      success: true, 
      requestId: requestRef.id,
      message: 'Verification request submitted successfully.' 
    };
  } catch (error) {
    console.error('Error requesting verification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to submit verification request');
  }
}); 