import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";

// Interface for user activity data
interface UserActivity {
  userId: string;
  timestamp: FirebaseFirestore.Timestamp;
  action: string;
  targetType?: string;
  targetId?: string;
  metadata?: Record<string, any>;
}

// Interface for user engagement metrics
interface UserEngagementMetrics {
  lastActive: FirebaseFirestore.Timestamp;
  activityCount: number;
  eventEngagementCount: number;
  spaceEngagementCount: number;
  socialEngagementCount: number;
  contentEngagementCount: number;
  engagementScore: number;
  streak: number;
  lastStreakUpdate: FirebaseFirestore.Timestamp;
}

/**
 * Tracks a user activity and updates engagement metrics
 */
export const trackUserActivity = functions.firestore
  .onDocumentCreated("user_activities/{activityId}",
    async (snapshot) => {
      try {
        const activity = snapshot.data() as UserActivity;

        if (!activity || !activity.userId) {
          logger.warn("Invalid activity data", {activityId: snapshot.id});
          return null;
        }

        logger.info("Processing user activity", {
          userId: activity.userId,
          action: activity.action,
          targetType: activity.targetType,
        });

        // Get current engagement metrics or initialize if not present
        const db = admin.firestore();
        const metricsRef = db.collection("user_engagement_metrics")
          .doc(activity.userId);

        const metricsDoc = await metricsRef.get();
        const metrics: UserEngagementMetrics = metricsDoc.exists ?
          (metricsDoc.data() as UserEngagementMetrics) :
          {
            lastActive: activity.timestamp,
            activityCount: 0,
            eventEngagementCount: 0,
            spaceEngagementCount: 0,
            socialEngagementCount: 0,
            contentEngagementCount: 0,
            engagementScore: 0,
            streak: 0,
            lastStreakUpdate: activity.timestamp,
          };

        // Update activity counts based on activity type
        metrics.activityCount += 1;
        metrics.lastActive = activity.timestamp;

        // Update specific engagement counters based on target type
        switch (activity.targetType) {
        case "event":
          metrics.eventEngagementCount += 1;
          break;
        case "space":
        case "club":
          metrics.spaceEngagementCount += 1;
          break;
        case "post":
        case "comment":
          metrics.contentEngagementCount += 1;
          break;
        case "user":
        case "friend_request":
        case "message":
          metrics.socialEngagementCount += 1;
          break;
        }

        // Update user streak (consecutive days of activity)
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayTimestamp = admin.firestore.Timestamp.fromDate(today);

        const lastUpdateDate = metrics.lastStreakUpdate.toDate();
        lastUpdateDate.setHours(0, 0, 0, 0);
        const lastUpdateTimestamp = admin.firestore.Timestamp.fromDate(lastUpdateDate);

        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayTimestamp = admin.firestore.Timestamp.fromDate(yesterday);

        // If last activity was yesterday, increment streak
        if (lastUpdateTimestamp.isEqual(yesterdayTimestamp)) {
          metrics.streak += 1;
        }
        // If last activity was today, keep streak the same
        else if (lastUpdateTimestamp.isEqual(todayTimestamp)) {
          // No change to streak, already logged in today
        }
        // If last activity was before yesterday, reset streak
        else if (lastUpdateTimestamp.seconds < yesterdayTimestamp.seconds) {
          metrics.streak = 1; // Start a new streak
        }

        metrics.lastStreakUpdate = todayTimestamp;

        // Calculate engagement score (weighted formula)
        metrics.engagementScore = calculateEngagementScore(metrics);

        // Update the metrics document
        await metricsRef.set(metrics, {merge: true});

        // Update user_profiles engagement summary
        await db.collection("user_profiles")
          .doc(activity.userId)
          .update({
            lastActive: activity.timestamp,
            engagementScore: metrics.engagementScore,
            streak: metrics.streak,
          });

        logger.info("Updated user engagement metrics", {
          userId: activity.userId,
          engagementScore: metrics.engagementScore,
          streak: metrics.streak,
        });

        // Check for streak milestone achievements
        await checkStreakAchievements(activity.userId, metrics.streak);

        return null;
      } catch (error) {
        logger.error("Error tracking user activity", error);
        return null;
      }
    });

/**
 * Calculate weighted engagement score based on various metrics
 */
function calculateEngagementScore(metrics: UserEngagementMetrics): number {
  // Calculate days since last activity
  const lastActiveDate = metrics.lastActive.toDate();
  const now = new Date();
  const daysSinceActive = Math.floor((now.getTime() - lastActiveDate.getTime()) /
    (1000 * 60 * 60 * 24));

  // Calculate recency factor (diminishes with inactivity)
  const recencyFactor = Math.max(0, 1 - (daysSinceActive / 30));

  // Calculate weighted score (customize weights based on business priorities)
  const score = (
    (metrics.eventEngagementCount * 1.2) +
    (metrics.spaceEngagementCount * 1.0) +
    (metrics.socialEngagementCount * 1.5) +
    (metrics.contentEngagementCount * 0.8) +
    (metrics.streak * 5)
  ) * recencyFactor;

  return Math.round(score * 10) / 10; // Round to 1 decimal place
}

/**
 * Check for streak-based achievements
 */
async function checkStreakAchievements(userId: string, streak: number): Promise<void> {
  try {
    // Define streak milestones
    const streakMilestones = [3, 7, 14, 30, 60, 90, 180, 365];

    // Check if the current streak hits any milestone
    const milestone = streakMilestones.find((m) => m === streak);
    if (!milestone) {
      return; // No milestone reached
    }

    logger.info(`User ${userId} reached streak milestone: ${milestone} days`);

    // Create achievement entry
    const db = admin.firestore();
    await db.collection("user_achievements").add({
      userId,
      type: "streak",
      milestone,
      achievedAt: admin.firestore.FieldValue.serverTimestamp(),
      title: `${milestone}-Day Streak`,
      description: `Stayed active on HIVE for ${milestone} consecutive days`,
      rewardPoints: calculateRewardPoints(milestone),
    });

    // Send a notification about the achievement
    await db.collection("notifications").add({
      userId,
      type: "achievement",
      title: "Streak Achievement Unlocked!",
      body: `Congratulations! You've been active for ${milestone} consecutive days.`,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.error("Error checking streak achievements", error);
  }
}

/**
 * Calculate reward points based on milestone difficulty
 */
function calculateRewardPoints(milestone: number): number {
  // Exponential reward scaling
  return Math.floor(10 * Math.pow(milestone / 7, 1.2));
}

/**
 * Triggered when a user profile is created, to initialize engagement metrics
 */
export const initializeUserEngagementMetrics = functions.firestore
  .onDocumentCreated("user_profiles/{userId}",
    async (snapshot) => {
      try {
        const userId = snapshot.id;
        const now = admin.firestore.FieldValue.serverTimestamp();

        // Initialize basic metrics
        const initialMetrics: Partial<UserEngagementMetrics> = {
          lastActive: now as any,
          activityCount: 0,
          eventEngagementCount: 0,
          spaceEngagementCount: 0,
          socialEngagementCount: 0,
          contentEngagementCount: 0,
          engagementScore: 0,
          streak: 0,
          lastStreakUpdate: now as any,
        };

        // Create the initial metrics document
        await admin.firestore()
          .collection("user_engagement_metrics")
          .doc(userId)
          .set(initialMetrics);

        logger.info("Initialized user engagement metrics", {userId});

        // Log user's first activity
        await admin.firestore().collection("user_activities").add({
          userId,
          timestamp: now,
          action: "account_created",
          targetType: "profile",
          targetId: userId,
          metadata: {
            isInitialActivity: true,
          },
        });

        return null;
      } catch (error) {
        logger.error("Error initializing user engagement metrics", error);
        return null;
      }
    });

/**
 * Daily scheduled function to reset streaks for inactive users
 */
export const updateUserStreaks = functions.pubsub
  .schedule("0 0 * * *") // Run at midnight every day
  .timeZone("America/New_York")
  .onRun(async () => {
    try {
      const db = admin.firestore();
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      // Get users whose lastStreakUpdate is before yesterday
      const metricsSnapshot = await db.collection("user_engagement_metrics")
        .where("lastStreakUpdate", "<", yesterday)
        .limit(500) // Process in batches to avoid timeout
        .get();

      if (metricsSnapshot.empty) {
        logger.info("No streaks to reset");
        return null;
      }

      // Update user streaks in batches
      const batch = db.batch();
      let updateCount = 0;

      metricsSnapshot.forEach((doc) => {
        const metrics = doc.data() as UserEngagementMetrics;

        // Reset streak if user was inactive yesterday
        if (metrics.streak > 0) {
          batch.update(doc.ref, {
            streak: 0,
            lastStreakUpdate: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Also update the user profile
          batch.update(db.collection("user_profiles").doc(doc.id), {
            streak: 0,
          });

          updateCount++;
        }
      });

      if (updateCount > 0) {
        await batch.commit();
        logger.info(`Reset streaks for ${updateCount} inactive users`);
      }

      return null;
    } catch (error) {
      logger.error("Error updating user streaks", error);
      return null;
    }
  });
