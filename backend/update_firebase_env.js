/**
 * Firebase .env Configuration Helper
 * This script helps you update your .env file with real Firebase credentials
 */

const fs = require('fs');
const path = require('path');

console.log('🔥 Firebase Configuration Helper');
console.log('================================');
console.log('');
console.log('📝 Instructions:');
console.log('1. Download your Firebase service account JSON file');
console.log('2. Replace the variables below with your actual values');
console.log('3. Run this script to update your .env file');
console.log('');

// TODO: Replace these with your actual Firebase credentials
const FIREBASE_CONFIG = {
  PROJECT_ID: 'new-flutter-ai',
  PRIVATE_KEY_ID: '1b45a8a7096da8c508ece45895a4a83ef7001697',
  PRIVATE_KEY: '"-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDk3pAQeYlzAUol\\nx7B++KLlkHelLYiZKhnkb0Ncl40+UiCWlaflkUJbZunDh8rn7xyCfPrv06ILoY+u\\njAn0ntndXZcooA2ejHBhkSQuC+FsVAGiCulmp3PFT/cH7TQOMe1EOfvpzFYpeWnj\\nwSI4G7/BQRz5VZGJUCMRO/SWpwrLQ4aEJ4X5mlApkCh47xuzFo2KvQ/rBtrng8m8\\nYNUUvPryuqP3wPvlf6fLPQgPXFexcU8wRq7qPUVGivMoMD1IEhLRom0RUaagourS\\ntyw4+IakNgL60SQ07x66jKi/S6kXKrSxqtcFxOPa038cp29yHVhWCmh7GNmBDP9H\\nzD8P/XHfAgMBAAECggEAcRo3sZyOO2JAxUjYxPaUccQiDGPjJGX047nEXUaby1eE\\nuUX98eoGE+tYzIMX1+SHf0jKLai1ZPATdFvKM7Qo0EeHAtGNyXN3ug+jBIpkfUdK\\ng0zHKS7JfJHW73jeh8FOkq/g+Ro83kQc+yufgIDeE1/dNK5/vI74tXSem7CzGd02\\npCrLxoSYJjqhuLPXj2B7usFADuT/wtAMMIkiW982LH6Y3WASYRmOQHwMNfoFEIA1\\nXeRV2B7Oz2ncgQnBvvo06s/Tlf5LSRbXpy4piI+nZ3y0JmDdKr5gbV5L3GK6CG78\\n0nYE0v+fYiZl3ZeSjcksei7heoMpxINcvDGoVptnwQKBgQD00RkZwB1+S0DAy52w\\nFsjwEdHx2ISf8wlJFujkzMol75hh7qYcE5Rfq0hSSkfZP+pqk7KkExSNk77q/DeI\\niEouV6aG4H0U7VliJfK3Xi0N07xxfdoRjdRfHeyqZzfdkkOnF1L2/mCu55olG9c4\\nrYdbCDUBPEotK3fspP5RHs9FYQKBgQDvUvmOOhHQBSl86dyBE8Ma+gNqxof2tbgT\\n7K9FMKxpTyLxWwLMpoQ4p9SMpqNryviVSD+gGIPzZg5DerSKR+cpxDFMVz8oaR6D\\nIjp0qMQvMQzQgF0pb7TDtVQT6u27Yo7IWU6b4H+Lj3rlEMLOkbcdYJaCt8uEYU2z\\nsxusSTi/PwKBgFXJc8c/N9aKni0w7JfI1C6zv+LEYWz/KBDRk1ihnnB+reIbU1/h\\nSIvhpF0ZpGWvbQBdsyqleP1HeY40RW11fLESi8sVnR8ZMMogzBWPTbBbstv+Is0l\\n6vZNsSHhO4VL/KLvnGXqq4x+odhBEkDNJfIzRQeizcdYRRTKmEdqyWzhAoGAfa+D\\n5A/XHvo3CaT/6sHoKxi2BrNw4D4bCEu62IlxYnTvEvYLCFNDCUYKuDsjhA66chvZ\\nXkjBs2gbgZDFlAGjAypIAaGoR569KX0mWfHv5iDKbA2d348MzeNC3pr4cvqVpd5R\\nDEfgc/jMP9SHmlioZEM/iDLiLQm09vTPSbHCnZ0CgYAXd5GcCxXOWVdnef/AAg2G\\nlxsVqcWKiuCTH2Oi+rJW3dHrpATOMtDhAE+bk9eoT+jr68CpRQiSmKwi6V6igQaA\\nwP/kxPaf8CyAHN0ujN2lX7MItSztrYuZf8V9Wa5bdg4uiGHD8BwRpxVdgHtfI8eF\\nNme1DXlBrr3WYjpc3oIkNA==\\n-----END PRIVATE KEY-----\\n"',
  CLIENT_EMAIL: 'firebase-adminsdk-fbsvc@new-flutter-ai.iam.gserviceaccount.com',
  CLIENT_ID: '104529828763350599299',
  DATABASE_URL: 'https://new-flutter-ai-default-rtdb.firebaseio.com/',
  STORAGE_BUCKET: 'new-flutter-ai.appspot.com'
};

function updateEnvFile() {
  try {
    const envPath = path.join(__dirname, '.env');
    let envContent = fs.readFileSync(envPath, 'utf8');
    
    // Check if user has updated the config
    if (FIREBASE_CONFIG.PROJECT_ID === 'your-actual-project-id') {
      console.log('❌ Please update the FIREBASE_CONFIG object in this script with your actual Firebase credentials first!');
      console.log('');
      console.log('📋 Steps to get your credentials:');
      console.log('1. Go to https://console.firebase.google.com/');
      console.log('2. Select your project');
      console.log('3. Go to Project Settings > Service accounts');
      console.log('4. Click "Generate new private key"');
      console.log('5. Download the JSON file');
      console.log('6. Update the FIREBASE_CONFIG object above with values from the JSON');
      console.log('7. Run this script again');
      return;
    }
    
    // Update Firebase credentials
    envContent = envContent.replace(/FIREBASE_PROJECT_ID=.*/, `FIREBASE_PROJECT_ID=${FIREBASE_CONFIG.PROJECT_ID}`);
    envContent = envContent.replace(/FIREBASE_PRIVATE_KEY_ID=.*/, `FIREBASE_PRIVATE_KEY_ID=${FIREBASE_CONFIG.PRIVATE_KEY_ID}`);
    envContent = envContent.replace(/FIREBASE_PRIVATE_KEY=.*/, `FIREBASE_PRIVATE_KEY=${FIREBASE_CONFIG.PRIVATE_KEY}`);
    envContent = envContent.replace(/FIREBASE_CLIENT_EMAIL=.*/, `FIREBASE_CLIENT_EMAIL=${FIREBASE_CONFIG.CLIENT_EMAIL}`);
    envContent = envContent.replace(/FIREBASE_CLIENT_ID=.*/, `FIREBASE_CLIENT_ID=${FIREBASE_CONFIG.CLIENT_ID}`);
    envContent = envContent.replace(/FIREBASE_DATABASE_URL=.*/, `FIREBASE_DATABASE_URL=${FIREBASE_CONFIG.DATABASE_URL}`);
    envContent = envContent.replace(/FIREBASE_STORAGE_BUCKET=.*/, `FIREBASE_STORAGE_BUCKET=${FIREBASE_CONFIG.STORAGE_BUCKET}`);
    
    // Write back to .env file
    fs.writeFileSync(envPath, envContent);
    
    console.log('✅ Firebase credentials updated successfully in .env file!');
    console.log('');
    console.log('🚀 Next steps:');
    console.log('1. Make sure Realtime Database is enabled in Firebase Console');
    console.log('2. Start your server: node index.js');
    console.log('3. Check the logs for "✅ Firebase Admin SDK initialized successfully"');
    
  } catch (error) {
    console.error('❌ Error updating .env file:', error.message);
  }
}

// Uncomment the line below and run this script after updating FIREBASE_CONFIG
updateEnvFile();

console.log('');
console.log('⚠️  To use this script:');
console.log('1. Update the FIREBASE_CONFIG object above with your real credentials');
console.log('2. Uncomment the last line: updateEnvFile();');
console.log('3. Run: node update_firebase_env.js');
console.log('');

module.exports = { updateEnvFile };