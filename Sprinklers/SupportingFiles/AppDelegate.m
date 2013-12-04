//
//  AppDelegate.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/16/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "AppDelegate.h"
//#import "SprinklerListViewController_iPhone.h"
//#import "SprinklerListViewController_iPad.h"
#import "SPSprinklerListViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "SPConstants.h"

@implementation AppDelegate

#pragma mark - Init

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        SprinklerListViewController_iPhone *sprinklerController = [[SprinklerListViewController_iPhone alloc] init];
//        UINavigationController *navSprinkler = [[UINavigationController alloc] initWithRootViewController:sprinklerController];
//        navSprinkler.navigationBar.barStyle = UIBarStyleBlackOpaque;
//        self.window.rootViewController = navSprinkler;
//    }
//    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        SprinklerListViewController_iPad *sprinklerController = [[SprinklerListViewController_iPad alloc] init];
//        UINavigationController *navSprinkler = [[UINavigationController alloc] initWithRootViewController:sprinklerController];
//        navSprinkler.navigationBar.barStyle = UIBarStyleBlackOpaque;
//        self.window.rootViewController = navSprinkler;
//    }    

//  UINavigationController *rootNavigationController = (UINavigationController *)self.window.rootViewController;
//  SPSprinklerListViewController *myViewController = (SPSprinklerListViewController *)[rootNavigationController topViewController];
  
  NSString *kTestSprinklerName = @"Test Sprinkler In Cloud";
  Sprinkler *sprinkler = [[StorageManager current] getSprinkler:kTestSprinklerName];
  if (!sprinkler) {
    [[StorageManager current] addSprinkler:kTestSprinklerName ipAddress:SPTestServerURL port:@"443"];
  }
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - UIApplication delegate

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidResignActive" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Saves changes in the application's managed object context before the application terminates.
}

@end
