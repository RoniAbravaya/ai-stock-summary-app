/// FirebaseLoader.m
///
/// Configures Firebase at the earliest possible point in the app lifecycle.
/// Uses Objective-C +load method which runs before main().

#import <Foundation/Foundation.h>

#if __has_include(<FirebaseCore/FirebaseCore.h>)
#import <FirebaseCore/FirebaseCore.h>
#define FIREBASE_AVAILABLE 1
#elif __has_include(<Firebase/Firebase.h>)
#import <Firebase/Firebase.h>
#define FIREBASE_AVAILABLE 1
#else
#define FIREBASE_AVAILABLE 0
#warning "Firebase headers not found"
#endif

@interface FirebaseLoader : NSObject
@end

@implementation FirebaseLoader

+ (void)load {
    NSLog(@"🔥 [FirebaseLoader +load] Starting...");
    
#if FIREBASE_AVAILABLE
    // Check if already configured (by another component)
    if ([FIRApp defaultApp] != nil) {
        NSLog(@"ℹ️ [FirebaseLoader +load] Firebase already configured");
        return;
    }
    
    // Check for GoogleService-Info.plist
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (plistPath == nil) {
        NSLog(@"❌ [FirebaseLoader +load] GoogleService-Info.plist NOT FOUND");
        return;
    }
    NSLog(@"✅ [FirebaseLoader +load] GoogleService-Info.plist found");
    
    // Configure Firebase
    @try {
        [FIRApp configure];
        
        if ([FIRApp defaultApp] != nil) {
            NSLog(@"✅ [FirebaseLoader +load] Firebase configured: %@", 
                  [FIRApp defaultApp].options.projectID);
        } else {
            NSLog(@"❌ [FirebaseLoader +load] Firebase configuration failed");
        }
    } @catch (NSException *exception) {
        NSLog(@"❌ [FirebaseLoader +load] Exception: %@", exception);
    }
#else
    NSLog(@"❌ [FirebaseLoader +load] Firebase headers not available");
#endif
}

@end
