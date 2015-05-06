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
#import "ServerProxy.h"

static UIAlertView *alertView;

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
        if (tag == kAlertView_CouldNotConnectToServer) {
            if ((!alertView) || (alertView.tag != kAlertView_CouldNotConnectToServer)) {
                alertView  = [[UIAlertView alloc] initWithTitle:titleMessage message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = kAlertView_CouldNotConnectToServer;
                [alertView show];
            }
        } else {
            if ((!alertView) || (alertView.tag != kAlertView_Error)) {
                alertView = [[UIAlertView alloc] initWithTitle:titleMessage message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alertView.tag = tag;
                [alertView show];
            }
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

- (BOOL)handleSprinklerErrorMessageBodyResponse:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage tag:(int)tag
{
    id responseObject = [operation responseObject];
    if (responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSArray *allKeys = [responseObject allKeys];
            if (allKeys.count == 2) {
                if ((([allKeys[0] isEqualToString:@"message"]) && ([allKeys[1] isEqualToString:@"statusCode"])) ||
                    (([allKeys[1] isEqualToString:@"message"]) && ([allKeys[0] isEqualToString:@"statusCode"]))) {
                    NSNumber *statusCode = [responseObject objectForKey:@"statusCode"];
                    if ([statusCode intValue] != API4StatusCode_Success) {
                        NSString *message = [responseObject objectForKey:@"message"];
                        [self handleSprinklerError:message title:@"Sprinkler error" showErrorMessage:showErrorMessage tag:tag];
                        
                        return YES;
                    }
                }
            }
        }
    }
    
    return NO;
}

- (void)handleSprinklerNetworkError:(NSError *)error operation:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage
{
    if ((error) || (operation)) {
        // Don't show error type: 5xx Internal Server Error
        if (![Utils hasOperationInternalServerErrorStatusCode:operation]) {
            // Don't show error cases of malformed JSON: Error Domain=NSCocoaErrorDomain Code=3840 "The operation couldn’t be completed. (Cocoa error 3840.)" (JSON text did not start with array or object and option to allow fragments not set.) UserInfo=0xad9b5a0 {NSDebugDescription=JSON text did not start with array or object and option to allow fragments not set.}
            BOOL malformedJSON = ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSPropertyListReadCorruptError);
            if (!malformedJSON) {
                int tag = kAlertView_Error;
                if (![self handleSprinklerErrorMessageBodyResponse:operation showErrorMessage:showErrorMessage tag:tag]) {
                    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCannotConnectToHost) {
                        tag = kAlertView_CouldNotConnectToServer;
                        [self handleCouldNotConnectToServerError];
                    }
                    [self handleSprinklerError:[error localizedDescription] title:[error.domain isEqualToString:@"Sprinkler"] ? @"Sprinkler error" : @"Network error" showErrorMessage:showErrorMessage tag:tag];
                }
            }
        }
    }
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
    
    [Utils invalidateLoginForCurrentSprinkler];
    
    if ((!alertView) || (alertView.tag != kAlertView_LoggedOut)) {
        alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = kAlertView_LoggedOut;
        [alertView show];
    }
}

- (void)handleCouldNotConnectToServerError {
    
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_LoggedOut) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews:nil];
    }
    else if (theAlertView.tag == kAlertView_CouldNotConnectToServer) {
        [StorageManager current].currentSprinkler = nil;
        [[StorageManager current] saveData];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews:nil];
    }
    
    alertView = nil;
}

@end
