//
//  AppDelegate.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/16/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DashboardVC;
@class StatsVC;
@class WaterNowVC;
@class SettingsVC;
@class UpdateManager;
@class GlobalsManager;
@class DevicesVC;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) DashboardVC *dashboardVC;
@property (nonatomic, strong) StatsVC *statsVC;
@property (nonatomic, strong) DevicesVC *devicesVC;
@property (nonatomic, strong) WaterNowVC *waterNowVC;
@property (nonatomic, strong) SettingsVC *settingsVC;
@property (strong, nonatomic) UpdateManager *updateManager;
@property (strong, nonatomic) GlobalsManager *globalsManager;

- (void)refreshRootViews:(NSString*)unit selectSettings:(BOOL)selectSettings;

@end
