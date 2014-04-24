//
//  BaseVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "BaseVC.h"
#import "StorageManager.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "NetworkUtilities.h"

@implementation BaseVC

#pragma mark - Error handling

- (void)handleServerLoggedOutUser {
//    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [StorageManager current].currentSprinkler = nil;
    [[StorageManager current] saveData];
}

- (void)handleSprinklerError:(NSString *)errorMessage title:(NSString*)titleMessage showErrorMessage:(BOOL)showErrorMessage{
    //    [StorageManager current].currentSprinkler.lastError = errorMessage;
    //    [[StorageManager current] saveData];

    if ((errorMessage) && (showErrorMessage)) {
        if ((!self.alertView) || (self.alertView.tag != kAlertView_Error)) {
            self.alertView = [[UIAlertView alloc] initWithTitle:titleMessage message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = kAlertView_Error;
            [self.alertView show];
        }
    }
}

- (void)handleSprinklerGeneralError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [self handleSprinklerError:errorMessage title:@"Sprinkler error" showErrorMessage:showErrorMessage];
}

- (void)handleSprinklerNetworkError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [self handleSprinklerError:errorMessage title:@"Network error" showErrorMessage:showErrorMessage];
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
    //    [StorageManager current].currentSprinkler.lastError = errorTitle;
    //    [[StorageManager current] saveData];
    
    [NetworkUtilities invalidateLoginForBaseUrl: [StorageManager current].currentSprinkler.address];
    
    if ((!self.alertView) || (self.alertView.tag != kAlertView_LoggedOut)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kAlertView_LoggedOut;
        [self.alertView show];
    }
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_LoggedOut) {
        [self handleServerLoggedOutUser];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews:nil];
    }
    
    self.alertView = nil;
}

@end
