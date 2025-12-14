/// FirebaseLoader.m
///
/// Configures Firebase at the earliest possible point to prevent
/// "[FirebaseCore][I-COR000003] The default Firebase app has not yet been configured"
///
/// The +load method runs when the class is loaded into memory, before main().
/// We call [FIRApp configure] IMMEDIATELY to minimize race conditions with
/// other Firebase plugin +load methods that might check Firebase status.

#import <Foundation/Foundation.h>

#if __has_include(<FirebaseCore/FirebaseCore.h>)
#import <FirebaseCore/FirebaseCore.h>
#define FIREBASE_AVAILABLE 1
#elif __has_include(<Firebase/Firebase.h>)
#import <Firebase/Firebase.h>
#define FIREBASE_AVAILABLE 1
#else
#define FIREBASE_AVAILABLE 0
#endif

@interface FirebaseLoader : NSObject
@end

@implementation FirebaseLoader

+ (void)load {
#if FIREBASE_AVAILABLE
    // Configure Firebase IMMEDIATELY - no logging first!
    // This minimizes the race window with other +load methods
    @try {
        if ([FIRApp defaultApp] == nil) {
            [FIRApp configure];
        }
    } @catch (NSException *e) {
        // Silently ignore - will be handled by AppDelegate fallback
    }
    
    // Log AFTER configuration is complete
    if ([FIRApp defaultApp] != nil) {
        NSLog(@"✅ [FirebaseLoader] Firebase configured: %@", 
              [FIRApp defaultApp].options.projectID);
    } else {
        NSLog(@"⚠️ [FirebaseLoader] Firebase not configured in +load");
    }
#endif
}

@end
