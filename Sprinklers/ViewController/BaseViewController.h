//
//  BaseViewController.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@class Sprinkler;

@interface BaseViewController : UIViewController

@property (strong, nonatomic) UIAlertView *alertView;

- (void)handleServerLoggedOutUser;
- (BOOL)handleGeneralSprinklerError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)handleLoggedOutSprinklerError;

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
