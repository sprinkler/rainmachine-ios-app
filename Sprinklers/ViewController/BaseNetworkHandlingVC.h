//
//  BaseVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFHTTPRequestOperation.h"

@interface BaseNetworkHandlingVC : UIViewController

- (void)handleServerLoggedOutUser;
- (void)handleSprinklerGeneralError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage;
- (void)handleSprinklerNetworkError:(NSError*)error operation:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage;
- (void)handleLoggedOutSprinklerError;

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
