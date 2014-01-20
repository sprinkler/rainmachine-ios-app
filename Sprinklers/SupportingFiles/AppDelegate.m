//
//  AppDelegate.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/16/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "AppDelegate.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "Constants.h"
#import "StatsVC.h"
#import "SettingsVC.h"
#import "WaterNowVC.h"
#import "Additions.h"

@implementation AppDelegate

#pragma mark - Init

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.window.tintColor = [UIColor whiteColor];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1]];
        [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    }
    
    StatsVC *statsVC = [[StatsVC alloc] init];
    UINavigationController *navStats = [[UINavigationController alloc] initWithRootViewController:statsVC];
    UITabBarItem *tabBarItemStats = [[UITabBarItem alloc] initWithTitle:@"Stats" image:[UIImage imageNamed:@"icon_stats.png"] tag:2];
    statsVC.tabBarItem = tabBarItemStats;
    
    WaterNowVC *waterVC = [[WaterNowVC alloc] init];
    UINavigationController *navWater = [[UINavigationController alloc] initWithRootViewController:waterVC];
    UITabBarItem *tabBarItemWaterNow = [[UITabBarItem alloc] initWithTitle:@"Water Now" image:[UIImage imageNamed:@"icon_waternow"] tag:2];
    waterVC.tabBarItem = tabBarItemWaterNow;
    
    SettingsVC *settingsVC = [[SettingsVC alloc] init];
    UINavigationController *navSettings = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    UITabBarItem *tabBarItemSettings = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"icon_settings"] tag:2];
    settingsVC.tabBarItem = tabBarItemSettings;
    
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.viewControllers = @[navStats, navWater, navSettings];
    self.window.rootViewController = _tabBarController;
  
    // TODO: remove this hack in production builds!
    NSString *kTestSprinklerName = @"Test Sprinkler In Cloud";
    Sprinkler *sprinkler = [[StorageManager current] getSprinkler:kTestSprinklerName];
    if (!sprinkler) {
        [[StorageManager current] addSprinkler:kTestSprinklerName ipAddress:TestServerURL port:TestServerPort];
    }
    
    if (![[UIDevice currentDevice] iOSGreaterThan:7]) {
        [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
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
