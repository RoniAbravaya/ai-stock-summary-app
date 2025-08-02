/**
 * Firebase Cloud Functions for AI Stock Summary App
 * Updated: 2025-06-01 - Fixed compatibility for all notification types
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Process notification document created in admin_notifications collection
 */
exports.processNotification = onDocumentCreated(
  "admin_notifications/{notificationId}",
  async (event) => {
    try {
      // Debug the entire event structure first
      logger.info("🔍 DEBUGGING - Event structure:", {
        eventKeys: Object.keys(event),
        hasData: !!event.data,
        hasParams: !!event.params,
        dataType: typeof event.data,
        paramsType: typeof event.params,
      });

      // Get the document data (Firebase Functions v6 API)
      const snapshot = event.data;
      const notification = snapshot ? snapshot.data() : null;
      const notificationId = event.params ? event.params.notificationId : "unknown";
      
      // Add detailed debugging to see exactly what we receive
      logger.info("🔍 DEBUGGING - Full notification data:", {
        notificationId: notificationId,
        notificationData: notification,
        dataKeys: notification ? Object.keys(notification) : "null",
        typeField: notification?.type,
        targetField: notification?.target, // Check if old field is still present
        titleField: notification?.title,
        messageField: notification?.message,
        snapshotExists: snapshot ? snapshot.exists : false,
      });

      if (!notification) {
        logger.error("❌ No notification data found");
        return;
      }

      const messaging = admin.messaging();

      // Check for both old and new field names for compatibility
      const notificationType = notification.type || notification.target;
      
      if (!notificationType) {
        logger.error("❌ No notification type found. Available fields:", Object.keys(notification));
        return;
      }

      logger.info("📱 Processing notification type:", notificationType);

      switch (notificationType) {
        case "all_users":
          await sendToAllUsers(messaging, notification);
          break;
        case "user_type":
          await sendToUserType(messaging, notification);
          break;
        case "specific_user":
          await sendToSpecificUser(messaging, notification);
          break;
        default:
          logger.error("❌ Unknown notification type:", notificationType);
          return;
      }

      // Update notification status (Firebase v6 API)
      if (snapshot && snapshot.ref) {
        await snapshot.ref.update({
          status: "processed",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          deliveryCount: notification.deliveryCount || 0,
        });
      }

      logger.info("✅ Notification processed successfully");
    } catch (error) {
      logger.error("❌ Error processing notification:", error);

      try {
        // Update error status (Firebase v6 API)
        const snapshot = event.data;
        if (snapshot && snapshot.ref) {
          await snapshot.ref.update({
            status: "failed",
            error: error.message,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (updateError) {
        logger.error("❌ Failed to update document status:", updateError);
      }
    }
  },
);

/**
 * Send notification to all users
 */
async function sendToAllUsers(messaging, notification) {
  logger.info("📤 Sending to all users");

  const usersSnapshot = await admin
      .firestore()
      .collection("users")
      .get();

  const tokens = [];
  const tokenDetails = []; // For debugging
  usersSnapshot.forEach((doc) => {
    const userData = doc.data();
    if (userData.fcmToken) {
      tokens.push(userData.fcmToken);
      tokenDetails.push({
        email: userData.email,
        hasToken: !!userData.fcmToken,
        tokenPrefix: userData.fcmToken ? userData.fcmToken.substring(0, 20) + "..." : "none"
      });
    }
  });

  logger.info("🔍 Token details:", {
    totalUsers: usersSnapshot.docs.length,
    usersWithTokens: tokens.length,
    tokenDetails: tokenDetails
  });

  await sendToTokens(messaging, tokens, notification);
}

/**
 * Send notification to users of specific type
 */
async function sendToUserType(messaging, notification) {
  // Handle both old and new field names for compatibility
  const userType = notification.userType || notification.targetUserType;
  
  logger.info("📤 Sending to user type:", userType);

  if (!userType) {
    logger.error("❌ No user type specified. Available fields:", Object.keys(notification));
    return;
  }

  const usersSnapshot = await admin
      .firestore()
      .collection("users")
      .where("subscriptionType", "==", userType)
      .get();

  const tokens = [];
  usersSnapshot.forEach((doc) => {
    const userData = doc.data();
    if (userData.fcmToken) {
      tokens.push(userData.fcmToken);
    }
  });

  await sendToTokens(messaging, tokens, notification);
}

/**
 * Send notification to specific user by email
 */
async function sendToSpecificUser(messaging, notification) {
  // Handle both old and new field names for compatibility
  const targetEmail = notification.targetEmail || notification.targetUserEmail;
  
  logger.info("📤 Sending to specific user:", targetEmail);

  if (!targetEmail) {
    logger.error("❌ No target email specified. Available fields:", Object.keys(notification));
    return;
  }

  const userSnapshot = await admin
      .firestore()
      .collection("users")
      .where("email", "==", targetEmail)
      .limit(1)
      .get();

  if (userSnapshot.empty) {
    logger.warn("⚠️ User not found:", targetEmail);
    return;
  }

  const userData = userSnapshot.docs[0].data();
  if (!userData.fcmToken) {
    logger.warn("⚠️ No FCM token for user:", targetEmail);
    return;
  }

  await sendToTokens(messaging, [userData.fcmToken], notification);
}

/**
 * Send FCM messages to multiple tokens with batching
 */
async function sendToTokens(messaging, tokens, notification) {
  if (tokens.length === 0) {
    logger.warn("⚠️ No tokens to send to");
    return;
  }

  logger.info(`📤 Sending to ${tokens.length} tokens`);

  const batchSize = 1000;
  let totalDelivered = 0;
  let totalFailed = 0;
  const invalidTokens = []; // Track invalid tokens for cleanup
  const deliveredUsers = []; // Track successful deliveries for history

  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);

    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
        },
        tokens: batch,
      };

      const response = await messaging.sendEachForMulticast(message);

      totalDelivered += response.successCount;
      totalFailed += response.failureCount;

      // Process individual responses
      if (response.responses) {
        const batchResults = await processTokenBatchResults(
          response.responses, 
          batch, 
          invalidTokens
        );
        deliveredUsers.push(...batchResults.deliveredUsers);
      }

      logger.info(`✅ Batch sent: ${response.successCount} success, ${response.failureCount} failed`);
    } catch (error) {
      logger.error("❌ Error sending batch:", error);
      totalFailed += batch.length;
    }
  }

  // Store notification history for successfully delivered notifications
  if (deliveredUsers.length > 0) {
    await storeNotificationHistory(deliveredUsers, notification);
  }

  // Clean up invalid tokens from database
  if (invalidTokens.length > 0) {
    await cleanupInvalidTokens(invalidTokens);
  }

  logger.info(`🎯 Total delivery: ${totalDelivered} delivered, ${totalFailed} failed`);
}

/**
 * Process batch results and identify successful deliveries
 */
async function processTokenBatchResults(responses, tokens, invalidTokens) {
  const deliveredUsers = [];
  
  // Get user mappings for tokens
  const tokenToUserMap = await getTokenToUserMapping(tokens);
  
  responses.forEach((resp, idx) => {
    const token = tokens[idx];
    
    if (resp.success) {
      // Find user for this token
      const userId = tokenToUserMap[token];
      if (userId) {
        deliveredUsers.push(userId);
      }
    } else {
      const error = resp.error;
      
      // Check if this is an invalid token error
      if (error && error.code === 'messaging/registration-token-not-registered') {
        logger.warn(`⚠️ Invalid token detected: ${token.substring(0, 20)}...`);
        invalidTokens.push(token);
      } else {
        logger.warn(`⚠️ Failed to send to token ${idx}:`, resp.error);
      }
    }
  });
  
  return { deliveredUsers };
}

/**
 * Create mapping from FCM tokens to user IDs
 * Optimized to only fetch users with matching FCM tokens
 */
async function getTokenToUserMapping(tokens) {
  const tokenToUserMap = {};
  
  try {
    // Use batched queries to fetch only users with matching tokens
    // This is more efficient than fetching all users
    const batchSize = 10; // Firestore 'in' query limit is 10
    const tokenBatches = [];
    
    // Split tokens into batches of 10
    for (let i = 0; i < tokens.length; i += batchSize) {
      tokenBatches.push(tokens.slice(i, i + batchSize));
    }
    
    // Process each batch
    for (const tokenBatch of tokenBatches) {
      try {
        const usersSnapshot = await admin
            .firestore()
            .collection("users")
            .where("fcmToken", "in", tokenBatch)
            .get();

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();
          if (userData.fcmToken && tokenBatch.includes(userData.fcmToken)) {
            tokenToUserMap[userData.fcmToken] = doc.id;
          }
        });
      } catch (batchError) {
        logger.warn("⚠️ Error processing token batch:", batchError.message);
        // Continue with other batches even if one fails
      }
    }
    
    logger.info(`✅ Created token mapping for ${Object.keys(tokenToUserMap).length}/${tokens.length} tokens`);
  } catch (error) {
    logger.error("❌ Error creating token to user mapping:", error);
  }
  
  return tokenToUserMap;
}

/**
 * Store notification history for delivered notifications
 */
async function storeNotificationHistory(userIds, notification) {
  try {
    logger.info(`📝 Storing notification history for ${userIds.length} users`);
    
    const batch = admin.firestore().batch();
    const notificationType = notification.type || notification.target || 'admin_broadcast';
    
    userIds.forEach((userId) => {
      const notificationRef = admin
          .firestore()
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc();
      
      batch.set(notificationRef, {
        title: notification.title,
        body: notification.message,
        type: notificationType,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        data: {
          sentBy: notification.sentBy || 'admin',
          originalNotificationId: notification.id || 'unknown'
        }
      });
    });
    
    await batch.commit();
    logger.info(`✅ Notification history stored for ${userIds.length} users`);
  } catch (error) {
    logger.error("❌ Error storing notification history:", error);
  }
}

/**
 * Remove invalid FCM tokens from user documents
 */
async function cleanupInvalidTokens(invalidTokens) {
  logger.info(`🧹 Cleaning up ${invalidTokens.length} invalid tokens`);
  
  try {
    const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .get();

    const batch = admin.firestore().batch();
    let cleanedCount = 0;

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken && invalidTokens.includes(userData.fcmToken)) {
        // Remove the invalid token
        batch.update(doc.ref, {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        cleanedCount++;
        logger.info(`🧹 Removing invalid token from user: ${userData.email}`);
      }
    });

    if (cleanedCount > 0) {
      await batch.commit();
      logger.info(`✅ Cleaned ${cleanedCount} invalid tokens from database`);
    }
  } catch (error) {
    logger.error("❌ Error cleaning invalid tokens:", error);
  }
} 