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
#import "DashboardVC.h"
#import "StatsVC.h"
#import "SettingsVC.h"
#import "WaterNowVC.h"
#import "Additions.h"
#import "UpdateManager.h"
#import "GlobalsManager.h"
#import "RMNavigationController.h"
#import "UpdateManager.h"
#import "NetworkUtilities.h"
#import "ServerProxy.h"
#import <GoogleMaps/GoogleMaps.h>

@interface AppDelegate()

@end

@implementation AppDelegate

#pragma mark - Init

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    DLog(@"docPath: %@", basePath);
    DLog(@"appPath: %@", [[NSBundle mainBundle] bundlePath]);

    [NetworkUtilities refreshKeychainCookies];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.updateManager = [[UpdateManager alloc] initWithDelegate:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.window.tintColor = [UIColor whiteColor];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1]];
        [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    }
    
    [self refreshRootViews:nil selectSettings:NO];
  
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
    
    [GMSServices provideAPIKey:kGoogleMapsAPIKey];
    
    return YES;
}

- (void)refreshRootViews:(NSString*)unit selectSettings:(BOOL)selectSettings {
    self.devicesVC = [[DevicesVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.devicesVC];
    
    if ([[StorageManager current] currentSprinkler]) {
        [[GlobalsManager current] refresh];
        
        UITabBarItem *tabBarItemDevices = [[UITabBarItem alloc] initWithTitle:@"Devices" image:[UIImage imageNamed:@"icon_devices.png"] tag:2];
        self.devicesVC.tabBarItem = tabBarItemDevices;
        
        UINavigationController *navDashboard = nil;
        
        if ([ServerProxy usesAPI4]) {
            self.dashboardVC = [[DashboardVC alloc] init];
            navDashboard = [[UINavigationController alloc] initWithRootViewController:self.dashboardVC];
            UITabBarItem *tabBarItemDashboard = [[UITabBarItem alloc] initWithTitle:@"Dashboard" image:[UIImage imageNamed:@"icon_stats.png"] tag:2];
            self.dashboardVC.tabBarItem = tabBarItemDashboard;
        } else {
            self.statsVC = [[StatsVC alloc] initWithUnits:unit];
            navDashboard = [[UINavigationController alloc] initWithRootViewController:self.statsVC];
            UITabBarItem *tabBarItemStats = [[UITabBarItem alloc] initWithTitle:@"Stats" image:[UIImage imageNamed:@"icon_stats.png"] tag:2];
            self.statsVC.tabBarItem = tabBarItemStats;
        }
        
        self.waterNowVC = [[WaterNowVC alloc] init];
        RMNavigationController *navWater = [[RMNavigationController alloc] initWithRootViewController:self.waterNowVC];
        UITabBarItem *tabBarItemWaterNow = [[UITabBarItem alloc] initWithTitle:@"Zones" image:[UIImage imageNamed:@"icon_waternow"] tag:2];
        self.waterNowVC.tabBarItem = tabBarItemWaterNow;

        NSArray *settings = nil;
        if ([ServerProxy usesAPI4]) {
            settings = @[kSettingsPrograms,
                         kSettingsWateringHistory,
                         kSettingsSnooze,
                         kSettingsRestrictions,
                         kSettingsWeather,
                         kSettingsSystemSettings,
                         kSettingsAbout,
                         kSettingsSoftwareUpdate];
        } else {
            settings = @[kSettingsPrograms,
                         kSettingsRainDelay,
                         kSettingsSystemSettings,
                         kSettingsAbout,
                         kSettingsSoftwareUpdate];
        }
        
        self.settingsVC = [[SettingsVC alloc] initWithSettings:settings parentSetting:nil];
        RMNavigationController *navSettings = [[RMNavigationController alloc] initWithRootViewController:self.settingsVC];
        UITabBarItem *tabBarItemSettings = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"icon_settings"] tag:2];
        self.settingsVC.tabBarItem = tabBarItemSettings;
        
        _tabBarController = [[UITabBarController alloc] init];
        _tabBarController.viewControllers = @[navDevices, navDashboard, navWater, navSettings];
        _tabBarController.delegate = self;
        
        if (selectSettings) _tabBarController.selectedViewController = navSettings;
        else _tabBarController.selectedViewController = navDashboard;
        
        self.window.rootViewController = _tabBarController;
    } else {
        self.window.rootViewController = navDevices;
        self.dashboardVC = nil;
        self.statsVC = nil;
        self.waterNowVC = nil;
        self.settingsVC = nil;
    }
}

#pragma mark - UITabBarController delegate

- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController {
    if (viewController != self.settingsVC.navigationController && self.settingsVC.navigationController.viewControllers.count > 1) {
        [self.settingsVC.navigationController popToRootViewControllerAnimated:NO];
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
    
    // Clear NSURLCache when waking up, otherwise some requests will return their cached responses even if the Sprinkler is offline
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    [self.devicesVC applicationDidEnterInForeground];
    [self.dashboardVC applicationDidEnterInForeground];
    [self.waterNowVC applicationDidEnterInForeground];
    [self.settingsVC applicationDidEnterInForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Saves changes in the application's managed object context before the application terminates.
}

@end
