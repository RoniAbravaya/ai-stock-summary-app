# Summary API Error Fix

## Issue
Users were getting 500 Internal Server Error when clicking the "Generate Summary" button on the favorites page.

## Root Cause
The summary generation API (`/api/summary/generate`) was failing due to:
1. Lack of proper Firestore availability checks
2. Poor error handling when Firebase/Firestore isn't properly initialized
3. No specific error messages to help diagnose the issue

## Changes Made

### 1. Enhanced Firebase Service (`backend/services/firebaseService.js`)

**Improved Firestore Initialization**:
- Added better logging for named database vs default database
- Added explicit error handling for Firestore connection failures
- Set `_isInitialized` to false and return early if Firestore fails

```javascript
// Initialize Firestore - try named database first, then default
try {
  this._firestore = getFirestore(admin.app(), 'flutter-database');
  console.log('? Connected to named Firestore database: flutter-database');
} catch (e) {
  console.warn('?? Named database not available, using default Firestore:', e?.message || e);
  try {
    this._firestore = admin.firestore();
    console.log('? Connected to default Firestore database');
  } catch (defaultError) {
    console.error('? Failed to connect to Firestore:', defaultError?.message || defaultError);
    this._firestore = null;
    this._isInitialized = false;
    return;
  }
}
```

### 2. Enhanced Summary API (`backend/api/summary.js`)

**Added Firestore Availability Check**:
```javascript
// Check if Firestore is available
if (!firebaseService.firestore) {
  console.error('? Firestore is not initialized');
  return res.status(503).json({
    success: false,
    error: 'Service unavailable',
    message: 'Database service is not available. Please try again later.',
    timestamp: new Date().toISOString()
  });
}
```

**Added Try-Catch for User Document Retrieval**:
```javascript
// Get user data from Firestore to check limits
let userDoc;
try {
  userDoc = await firebaseService.firestore
    .collection('users')
    .doc(userId)
    .get();
} catch (firestoreError) {
  console.error('? Failed to fetch user document:', firestoreError);
  return res.status(503).json({
    success: false,
    error: 'Database error',
    message: 'Failed to retrieve user information. Please try again.',
    details: firestoreError.message,
    timestamp: new Date().toISOString()
  });
}
```

**Improved Error Response**:
```javascript
} catch (error) {
  console.error('? Error in POST /api/summary/generate:', error);
  console.error('Error stack:', error.stack);
  
  // Provide more detailed error messages based on error type
  let errorMessage = error.message;
  let statusCode = 500;
  
  if (error.message.includes('OpenAI')) {
    errorMessage = 'AI service error. Please try again.';
    statusCode = 503;
  } else if (error.message.includes('Firestore') || error.message.includes('Firebase')) {
    errorMessage = 'Database service error. Please try again.';
    statusCode = 503;
  } else if (error.message.includes('quota') || error.message.includes('limit')) {
    errorMessage = 'Service quota exceeded. Please try again later.';
    statusCode = 429;
  }
  
  res.status(statusCode).json({
    success: false,
    error: 'Internal server error',
    message: errorMessage,
    timestamp: new Date().toISOString()
  });
}
```

### 3. Enhanced Health Check (`backend/api/health.js`)

**Added Firebase/Firestore Status**:
```javascript
// Check Firebase/Firestore status
let firebaseStatus = 'not initialized';
let firestoreStatus = 'not initialized';
let firestoreTest = 'not tested';

try {
  if (firebaseService.isInitialized) {
    firebaseStatus = 'initialized';
    
    if (firebaseService.firestore) {
      firestoreStatus = 'connected';
      
      // Test Firestore connection
      try {
        await firebaseService.firestore
          .collection('_health')
          .doc('check')
          .get()
          .catch(() => {});
        firestoreTest = 'ok';
      } catch (testError) {
        firestoreTest = `error: ${testError.message}`;
      }
    } else {
      firestoreStatus = 'not connected';
    }
  }
} catch (fbError) {
  firebaseStatus = `error: ${fbError.message}`;
}

// Added to health response
services: {
  rapidapi: process.env.RAPIDAPI_KEY ? 'configured' : 'not configured',
  openai: process.env.OPENAI_API_KEY ? 'configured' : 'not configured',
  firebase: firebaseStatus,
  firestore: firestoreStatus,
  firestoreTest: firestoreTest
}
```

## How to Verify the Fix

### 1. Check Health Endpoint
```bash
curl https://your-app-url/api/health
```

Look for the `services` section in the response:
```json
{
  "services": {
    "firebase": "initialized",
    "firestore": "connected", 
    "firestoreTest": "ok"
  }
}
```

### 2. Check Server Logs
When the backend starts, you should see:
```
? Connected to named Firestore database: flutter-database
? Firebase Admin SDK initialized successfully
```

Or if using default:
```
?? Named database not available, using default Firestore
? Connected to default Firestore database
? Firebase Admin SDK initialized successfully
```

### 3. Test Summary Generation
- Log in to the app
- Navigate to favorites
- Click "Generate Summary" button
- Should either:
  - Generate successfully ?
  - Show clear error message ? (with proper error code)

## Expected Error Messages

### If Firestore is Down:
```json
{
  "success": false,
  "error": "Service unavailable",
  "message": "Database service is not available. Please try again later."
}
```

### If User Document Fetch Fails:
```json
{
  "success": false,
  "error": "Database error",
  "message": "Failed to retrieve user information. Please try again."
}
```

### If OpenAI Fails:
```json
{
  "success": false,
  "error": "Internal server error",
  "message": "AI service error. Please try again."
}
```

## Environment Variables to Check

Make sure these are set in Cloud Run:

### Required for Firebase:
- `FIREBASE_PROJECT_ID` or auto-detected in Cloud Run
- `FIREBASE_PRIVATE_KEY` (local dev only)
- `FIREBASE_CLIENT_EMAIL` (local dev only)

### Required for Summary Generation:
- `OPENAI_API_KEY` - For AI summary generation
- `RAPIDAPI_KEY` - For stock/news data

## Possible Root Causes

1. **Named Database Not Created**: The backend tries to connect to `flutter-database` but it might not exist
   - **Fix**: Create the named database in Firestore or let it fall back to default

2. **Cloud Run Permissions**: The Cloud Run service account might not have Firestore access
   - **Fix**: Grant Firestore permissions to the service account

3. **Environment Variables Missing**: Required Firebase env vars not set
   - **Fix**: Set them in Cloud Run environment variables

4. **Network/Timeout Issues**: Firestore requests timing out
   - **Fix**: Increase timeout or check network connectivity

## Next Steps

1. **Deploy the changes** to Cloud Run
2. **Check the health endpoint** to verify Firebase/Firestore status
3. **Monitor server logs** for initialization messages
4. **Test summary generation** in the app
5. **Check error responses** for clear messaging

If the issue persists:
- Check Cloud Run logs for the specific error message
- Verify the named database `flutter-database` exists in Firestore
- Verify service account permissions
- Check if default database fallback is working
