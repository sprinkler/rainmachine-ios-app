//
//  BaseVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "BaseNetworkHandlingVC.h"
#import "StorageManager.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "NetworkUtilities.h"
#import "Utils.h"

@implementation BaseNetworkHandlingVC

#pragma mark - Error handling

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sprinklerNetworkError:) name:kSprinklerNetworkError object:nil];
}

- (void)handleServerLoggedOutUser {
//    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [StorageManager current].currentSprinkler = nil;
    [[StorageManager current] saveData];
}

- (void)handleSprinklerError:(NSString *)errorMessage title:(NSString*)titleMessage showErrorMessage:(BOOL)showErrorMessage tag:(int)tag
{
    //    [StorageManager current].currentSprinkler.lastError = errorMessage;
    //    [[StorageManager current] saveData];

    if ((errorMessage) && (showErrorMessage)) {
        if ((!self.alertView) || (self.alertView.tag != kAlertView_Error)) {
            self.alertView = [[UIAlertView alloc] initWithTitle:titleMessage message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = tag;
            [self.alertView show];
        }
    }
}

- (void)handleSprinklerGeneralError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [self handleSprinklerError:errorMessage title:@"Sprinkler error" showErrorMessage:showErrorMessage tag:kAlertView_Error];
}

- (void)sprinklerNetworkError:(NSNotification*)notif
{
    // Error received through NSNotification(Ex: UpdateManager
    NSDictionary *dict = (NSDictionary *)[notif object];
    NSError *error = [dict objectForKey:@"error"];
    AFHTTPRequestOperation *operation = [dict objectForKey:@"operation"];
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)handleSprinklerNetworkError:(NSError *)error operation:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage
{
    // Don't show error type: 5xx Internal Server Error
    if (![Utils hasOperationInternalServerErrorStatusCode:operation]) {
        // Don't show error cases of malformed JSON: Error Domain=NSCocoaErrorDomain Code=3840 "The operation couldn’t be completed. (Cocoa error 3840.)" (JSON text did not start with array or object and option to allow fragments not set.) UserInfo=0xad9b5a0 {NSDebugDescription=JSON text did not start with array or object and option to allow fragments not set.}
        BOOL malformedJSON = ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSPropertyListReadCorruptError);
        if (!malformedJSON) {
            int tag = kAlertView_Error;
            
            [self handleSprinklerError:[error localizedDescription] title:@"Network error" showErrorMessage:showErrorMessage tag:tag];
        }
    }
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
    
    [Utils invalidateLoginForCurrentSprinkler];
    
    if ((!self.alertView) || (self.alertView.tag != kAlertView_LoggedOut)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kAlertView_LoggedOut;
        [self.alertView show];
    }
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_LoggedOut) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews:nil];
    }
    
    self.alertView = nil;
}

@end
