//
//  FLSAppDelegate.m
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSAppDelegate.h"
#import "FLSGlobalSettings.h"

@implementation FLSAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // TODO: Load from NSUserDefaults
    
    // LOOK
    look_baseColor = GLKVector3Make(0.07f, 0.15f, 0.45f); // RANGE: (0.0f, 0.0f, 0.0f) - (1.0f, 1.0f, 1.0f)
    look_clarity = 0.3f; // RANGE: 0.0f - 1.0f
    look_shimmer = 12.0f; // RANGE: 0.0f, 10.0f - 15.0f
    look_foam = 0.5f; // RANGE: 0.0f - 1.0f
    
    // FEEL
    feel_viscosity = 0.0f; // RANGE: 0.0f - 1.0f
    feel_gravity = 0.5f; // RANGE: 0.0f - 1.0f
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
