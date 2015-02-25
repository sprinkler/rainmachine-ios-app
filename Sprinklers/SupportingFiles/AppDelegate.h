//
//  AppDelegate.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/16/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DashboardVC;
@class UpdateManager;
@class GlobalsManager;
@class DevicesVC;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) DashboardVC *dashboardVC;
@property (nonatomic, strong) DevicesVC *devicesVC;
@property (strong, nonatomic) UpdateManager *updateManager;
@property (strong, nonatomic) GlobalsManager *globalsManager;

- (void)refreshRootViews:(NSString*)unit;

@end
