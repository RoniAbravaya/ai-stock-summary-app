/**
 * Authentication Middleware
 * Validates Firebase ID tokens and attaches user info to request
 */

const firebaseService = require('../services/firebaseService');

/**
 * Middleware to verify Firebase ID token
 * Extracts token from Authorization header and validates it
 */
async function authenticateUser(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'No authentication token provided',
        timestamp: new Date().toISOString()
      });
    }

    const idToken = authHeader.split('Bearer ')[1];
    
    if (!idToken) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Invalid authorization header format',
        timestamp: new Date().toISOString()
      });
    }

    // Verify the ID token with Firebase Admin SDK
    try {
      const decodedToken = await firebaseService.admin.auth().verifyIdToken(idToken);
      
      // Attach user info to request
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        name: decodedToken.name,
        picture: decodedToken.picture
      };
      
      console.log(`? Authenticated user: ${req.user.email} (${req.user.uid})`);
      next();
    } catch (error) {
      console.error('? Token verification failed:', error.message);
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Invalid or expired token',
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('? Authentication error:', error.message);
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'Failed to authenticate request',
      timestamp: new Date().toISOString()
    });
  }
}

/**
 * Middleware to check if user is admin
 * Must be used after authenticateUser middleware
 */
async function requireAdmin(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Authentication required',
        timestamp: new Date().toISOString()
      });
    }

    // Get user document from Firestore to check role
    const userDoc = await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'User profile not found',
        timestamp: new Date().toISOString()
      });
    }

    const userData = userDoc.data();
    
    if (userData.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'Admin access required',
        timestamp: new Date().toISOString()
      });
    }

    // Attach user data to request
    req.userData = userData;
    
    console.log(`? Admin access granted: ${req.user.email}`);
    next();
  } catch (error) {
    console.error('? Admin check error:', error.message);
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'Failed to verify admin access',
      timestamp: new Date().toISOString()
    });
  }
}

/**
 * Optional authentication middleware
 * Attaches user info if token is provided, but doesn't require it
 */
async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const idToken = authHeader.split('Bearer ')[1];
      
      try {
        const decodedToken = await firebaseService.admin.auth().verifyIdToken(idToken);
        
        req.user = {
          uid: decodedToken.uid,
          email: decodedToken.email,
          emailVerified: decodedToken.email_verified,
          name: decodedToken.name,
          picture: decodedToken.picture
        };
        
        console.log(`? Optional auth - user: ${req.user.email}`);
      } catch (error) {
        console.warn('?? Optional auth - invalid token:', error.message);
        // Continue without user info
      }
    }
    
    next();
  } catch (error) {
    console.error('? Optional auth error:', error.message);
    next(); // Continue even if there's an error
  }
}

module.exports = {
  authenticateUser,
  requireAdmin,
  optionalAuth
};
