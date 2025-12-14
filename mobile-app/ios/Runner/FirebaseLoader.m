/// FirebaseLoader.m
/// 
/// This Objective-C class uses the +load method to configure Firebase at the 
/// earliest possible point in the app lifecycle - before main() is called.
/// This prevents the "[FirebaseCore][I-COR000003] The default Firebase app has 
/// not yet been configured" error that occurs when Flutter plugins try to 
/// access Firebase before AppDelegate runs.

#import <Foundation/Foundation.h>
@import FirebaseCore;

@interface FirebaseLoader : NSObject
@end

@implementation FirebaseLoader

/// +load is called very early, before main() runs, when the class is loaded into memory.
/// This is the earliest point we can configure Firebase.
+ (void)load {
    NSLog(@"🔥 [FirebaseLoader +load] Configuring Firebase...");
    
    // Check if Firebase is already configured (shouldn't be at this point)
    if ([FIRApp defaultApp] != nil) {
        NSLog(@"ℹ️ [FirebaseLoader +load] Firebase already configured, skipping");
        return;
    }
    
    // Verify GoogleService-Info.plist exists
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (plistPath == nil) {
        NSLog(@"❌ [FirebaseLoader +load] GoogleService-Info.plist NOT FOUND in bundle!");
        NSLog(@"   Bundle path: %@", [[NSBundle mainBundle] bundlePath]);
        return;
    }
    
    NSLog(@"✅ [FirebaseLoader +load] GoogleService-Info.plist found at: %@", plistPath);
    
    // Log some details from the plist for debugging
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (plistData) {
        NSLog(@"   PROJECT_ID: %@", plistData[@"PROJECT_ID"]);
        NSLog(@"   GOOGLE_APP_ID: %@", plistData[@"GOOGLE_APP_ID"]);
        NSLog(@"   BUNDLE_ID: %@", plistData[@"BUNDLE_ID"]);
    }
    
    // Configure Firebase
    [FIRApp configure];
    
    // Verify configuration succeeded
    if ([FIRApp defaultApp] != nil) {
        NSLog(@"✅ [FirebaseLoader +load] Firebase configured successfully!");
        NSLog(@"   App name: %@", [FIRApp defaultApp].name);
        NSLog(@"   Project ID: %@", [FIRApp defaultApp].options.projectID);
    } else {
        NSLog(@"❌ [FirebaseLoader +load] Firebase configuration FAILED!");
    }
}

@end
