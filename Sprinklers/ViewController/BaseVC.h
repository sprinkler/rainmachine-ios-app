//
//  BaseVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseVC : UIViewController

@property (strong, nonatomic) UIAlertView *alertView;

- (void)handleServerLoggedOutUser;
- (void)handleSprinklerGeneralError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)handleSprinklerNetworkError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)handleLoggedOutSprinklerError;

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
