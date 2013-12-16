//
//  SPMainScreenViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Sprinkler;

@interface SPMainScreenViewController : UITabBarController<UITabBarControllerDelegate>

@property (strong, nonatomic) Sprinkler *sprinkler;
@property (strong, nonatomic) UIAlertView *alertView;

- (void)handleServerLoggedOutUser;
- (void)handleGeneralSprinklerError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)handleLoggedOutSprinklerError;
- (void)setNavBarColor:(UIColor*)color;

@end