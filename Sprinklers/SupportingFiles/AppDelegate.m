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
#import "DevicesVC.h"
#import "StatsVC.h"
#import "SettingsVC.h"
#import "WaterNowVC.h"
#import "Additions.h"
#import "UpdateManager.h"
#import "RMNavigationController.h"
#import "UpdateManager.h"
#import "NetworkUtilities.h"

@interface AppDelegate()

@end

@implementation AppDelegate

#pragma mark - Init

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [NetworkUtilities clearCookiesFromKeychain]; // Use this line for debug purposes to clear the cookies form th keychain

    // Clear the session-only cookies form keychain
    [NetworkUtilities clearSessionOnlyCookiesFromKeychain];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.updateManager = [[UpdateManager alloc] initWithDelegate:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.window.tintColor = [UIColor whiteColor];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1]];
        [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    }
    
    [self refreshRootViews:nil];
  
//    // TODO: remove this hack in production builds!
//    NSString *kTestSprinklerName = @"Test Sprinkler In Cloud";
//    Sprinkler *sprinkler = [[StorageManager current] getSprinkler:kTestSprinklerName local:@NO];
//    if (!sprinkler) {
//        [[StorageManager current] addRemoteSprinkler:kTestSprinklerName ipAddress:TestServerURL port:TestServerPort];
//    }
    
    if (![[UIDevice currentDevice] iOSGreaterThan:7]) {
        [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)refreshRootViews:(NSString*)unit
{
    DevicesVC *devicesVC = [[DevicesVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:devicesVC];
    
    if ([[StorageManager current] currentSprinkler]) {
        UITabBarItem *tabBarItemDevices = [[UITabBarItem alloc] initWithTitle:@"Devices" image:[UIImage imageNamed:@"icon_devices.png"] tag:2];
        devicesVC.tabBarItem = tabBarItemDevices;

        self.statsVC = [[StatsVC alloc] initWithUnits:unit];
        UINavigationController *navStats = [[UINavigationController alloc] initWithRootViewController:self.statsVC];
        UITabBarItem *tabBarItemStats = [[UITabBarItem alloc] initWithTitle:@"Stats" image:[UIImage imageNamed:@"icon_stats.png"] tag:2];
        self.statsVC.tabBarItem = tabBarItemStats;
        
        WaterNowVC *waterVC = [[WaterNowVC alloc] init];
        UINavigationController *navWater = [[UINavigationController alloc] initWithRootViewController:waterVC];
        UITabBarItem *tabBarItemWaterNow = [[UITabBarItem alloc] initWithTitle:@"Zones" image:[UIImage imageNamed:@"icon_waternow"] tag:2];
        waterVC.tabBarItem = tabBarItemWaterNow;

        SettingsVC *settingsVC = [[SettingsVC alloc] init];
        RMNavigationController *navSettings = [[RMNavigationController alloc] initWithRootViewController:settingsVC];
        UITabBarItem *tabBarItemSettings = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"icon_settings"] tag:2];
        settingsVC.tabBarItem = tabBarItemSettings;
        
        _tabBarController = [[UITabBarController alloc] init];
        _tabBarController.viewControllers = @[navDevices, navStats, navWater, navSettings];
        
        _tabBarController.selectedViewController = navStats;
        self.window.rootViewController = _tabBarController;
    } else {
        self.window.rootViewController = navDevices;
        self.statsVC = nil;
    }
}

#pragma mark - UIApplication delegate

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidResignActive" object:nil];
    [self.updateManager stop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
    [self.updateManager poll];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Saves changes in the application's managed object context before the application terminates.
}

@end
