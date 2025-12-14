/// FirebaseLoader.m
/// 
/// This Objective-C class uses multiple mechanisms to configure Firebase at the 
/// earliest possible point in the app lifecycle - before main() is called.
/// This prevents the "[FirebaseCore][I-COR000003] The default Firebase app has 
/// not yet been configured" error that occurs when Flutter plugins try to 
/// access Firebase before AppDelegate runs.
///
/// Initialization order:
/// 1. __attribute__((constructor)) - C-level, runs before ObjC runtime is fully up
/// 2. +load - ObjC class load, runs when class is loaded into runtime
/// 3. +initialize - ObjC class init, runs before first method call

#import <Foundation/Foundation.h>

// Use traditional import instead of @import for better compatibility
// This header is provided by the Firebase CocoaPod
#if __has_include(<FirebaseCore/FirebaseCore.h>)
#import <FirebaseCore/FirebaseCore.h>
#define FIREBASE_AVAILABLE 1
#elif __has_include("FirebaseCore/FirebaseCore.h")
#import "FirebaseCore/FirebaseCore.h"
#define FIREBASE_AVAILABLE 1
#elif __has_include(<Firebase/Firebase.h>)
#import <Firebase/Firebase.h>
#define FIREBASE_AVAILABLE 1
#else
#define FIREBASE_AVAILABLE 0
#warning "FirebaseCore headers not found - Firebase will not be configured in +load"
#endif

// Forward declaration for the configure function
static void configureFirebaseIfNeeded(const char *caller);

/// C-level constructor - runs before main() and before ObjC +load methods
/// This is the absolute earliest point we can run code
__attribute__((constructor))
static void FirebaseLoaderConstructor(void) {
    // Note: At this point, ObjC runtime may not be fully initialized
    // We need to be careful about what we call here
    fprintf(stderr, "🔥 [FirebaseLoader constructor] Running before main()...\n");
    
    // Dispatch to main queue to ensure ObjC runtime is ready
    // This will still run before most app code
    dispatch_async(dispatch_get_main_queue(), ^{
        configureFirebaseIfNeeded("constructor-dispatch");
    });
}

/// Static helper function to configure Firebase with detailed logging
static void configureFirebaseIfNeeded(const char *caller) {
#if FIREBASE_AVAILABLE
    // Check if Firebase is already configured
    if ([FIRApp defaultApp] != nil) {
        NSLog(@"ℹ️ [FirebaseLoader %s] Firebase already configured", caller);
        return;
    }
    
    NSLog(@"🔥 [FirebaseLoader %s] Configuring Firebase...", caller);
    
    // Verify GoogleService-Info.plist exists
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (plistPath == nil) {
        NSLog(@"❌ [FirebaseLoader %s] GoogleService-Info.plist NOT FOUND!", caller);
        NSLog(@"   Bundle: %@", [[NSBundle mainBundle] bundlePath]);
        return;
    }
    
    NSLog(@"✅ [FirebaseLoader %s] GoogleService-Info.plist found", caller);
    
    // Log plist details
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (plistData) {
        NSLog(@"   PROJECT_ID: %@", plistData[@"PROJECT_ID"]);
        NSLog(@"   BUNDLE_ID: %@", plistData[@"BUNDLE_ID"]);
        
        // Check bundle ID match
        NSString *appBundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSString *plistBundleId = plistData[@"BUNDLE_ID"];
        if (![appBundleId isEqualToString:plistBundleId]) {
            NSLog(@"⚠️ Bundle ID mismatch! App: %@, Plist: %@", appBundleId, plistBundleId);
        }
    }
    
    // Configure Firebase
    @try {
        [FIRApp configure];
        
        if ([FIRApp defaultApp] != nil) {
            NSLog(@"✅ [FirebaseLoader %s] Firebase configured: %@", caller, [FIRApp defaultApp].options.projectID);
        } else {
            NSLog(@"❌ [FirebaseLoader %s] Firebase configure returned nil!", caller);
        }
    } @catch (NSException *exception) {
        NSLog(@"❌ [FirebaseLoader %s] Exception: %@", caller, exception);
    }
#else
    NSLog(@"❌ [FirebaseLoader %s] Firebase headers not available!", caller);
#endif
}

@interface FirebaseLoader : NSObject
@end

@implementation FirebaseLoader

/// +load is called very early, before main() runs, when the class is loaded into memory.
+ (void)load {
    NSLog(@"🔥 [FirebaseLoader +load] Class loaded");
    configureFirebaseIfNeeded("+load");
}

/// Called when the class is initialized (after +load, but still early)
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"🔥 [FirebaseLoader +initialize] Class initialized");
        configureFirebaseIfNeeded("+initialize");
    });
}

@end
