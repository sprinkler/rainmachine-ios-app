//
//  UpdateManager.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UpdateManager.h"
#import "ServerProxy.h"
#import "APIVersion.h"
#import "UpdateInfo.h"
#import "UpdateStartInfo.h"
#import "Utils.h"
#import "Constants.h"
#import "StorageManager.h"
#import "UpdaterVC.h"
#import "StartStopProgramResponse.h"
#import "Program.h"
#import "AppDelegate.h"

@interface UpdateManager () {
    int serverAPIMainVersion;
    int serverAPISubVersion;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *serverProxyDetect35x;
@property (strong, nonatomic) UIAlertView *alertView;
@property (weak, nonatomic) id<UpdateManagerDelegate> delegate;

@end

static UpdateManager *current = nil;

@implementation UpdateManager

@synthesize serverAPIMainVersion, serverAPISubVersion;

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(poll) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"ApplicationDidResignActive" object:nil];
    
    return self;
}

- (void)initUpdaterManager
{
}

- (void)stop
{
    [self.serverProxy cancelAllOperations];
    self.serverProxy = nil;
}

- (void)poll:(id<UpdateManagerDelegate>)delegate
{
    self.delegate = delegate;
    [self stop];
    
    BOOL checkUpdate = YES;
    
    if ([StorageManager current].currentSprinkler.lastSprinklerVersionRequest) {
        long intervalSinceLastUpdate = -[[StorageManager current].currentSprinkler.lastSprinklerVersionRequest timeIntervalSinceNow];
        checkUpdate = (intervalSinceLastUpdate >= kSprinklerUpdateCheckInterval);
    }
    
    if (checkUpdate) {

        if ([StorageManager current].currentSprinkler) {
            self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
            [self.serverProxy requestAPIVersion];
        }
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    if ([userInfo isEqualToString:@"apiVer"]) {
    
        self.serverProxyDetect35x = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        Program *program = [Program new];
        program.programId = -1;
        [self.serverProxyDetect35x runNowProgram:program];
    }
    else if ([userInfo isEqualToString:@"runNowProgram"]) {
        self.serverProxyDetect35x = nil;
        serverAPIMainVersion = 3;
        serverAPISubVersion = 56; // or 55;
        
        if (!self.delegate) {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Firmware update available"
                                                                message:@"Please go to your Rain Machine console and update to the latest version" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        } else {
            [self.delegate sprinklerVersionReceivedMajor:serverAPIMainVersion minor:serverAPISubVersion];
        }
    }
    else
    {
        [self handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
    }
    
    [self.serverProxy cancelAllOperations];
    self.serverProxy = nil;
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self handleSprinklerNetworkError:nil showErrorMessage:YES];
    
    if (([userInfo isEqualToString:@"runNowProgram"]) && ([data isKindOfClass:[StartStopProgramResponse class]])) {
        serverAPIMainVersion = 3;
        StartStopProgramResponse *response = (StartStopProgramResponse*)data;
        if ([response.state isEqualToString:@"err"]) {
            serverAPISubVersion = 57;
        } else {
            serverAPISubVersion = 56;
        }
        
        self.serverProxyDetect35x = nil;
        
        if (!self.delegate) {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Firmware update available"
                            message:@"Please go to your Rain Machine console and update to the latest version" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        } else {
            [self.delegate sprinklerVersionReceivedMajor:serverAPIMainVersion minor:serverAPISubVersion];
        }
    }
    else if ([data isKindOfClass:[APIVersion class]]) {
        APIVersion *apiVersion = (APIVersion*)data;
        NSArray *versionComponents = [apiVersion.apiVer componentsSeparatedByString:@"."];
        if ([versionComponents[0] intValue] >= 3) {
            // Firmware update is supported by server
            serverAPIMainVersion = [versionComponents[0] intValue];
            serverAPISubVersion = [versionComponents[1] intValue];
            [self.delegate sprinklerVersionReceivedMajor:serverAPIMainVersion minor:serverAPISubVersion];
            [self.serverProxy requestUpdateCheckForVersion:serverAPIMainVersion];
        }
    }
    else if ([data isKindOfClass:[UpdateInfo class]]) {
        UpdateInfo *updateInfo = (UpdateInfo*)data;
        if ([updateInfo.update boolValue]) {
            NSDate *lastUpdateCheck = [NSDate dateWithTimeIntervalSince1970:[updateInfo.last_update_check longLongValue]];
            NSTimeInterval intervalSinceLastUpdate = -[lastUpdateCheck timeIntervalSinceNow];
            // When there is a delegate alert it anyway with the update-now notification
            BOOL checkUpdate = (intervalSinceLastUpdate >= kSprinklerUpdateCheckInterval);
            
            if (checkUpdate) {
                if (!self.delegate) {
                    NSString *message = [NSString stringWithFormat:@"Please update your device firmware to version %@.", updateInfo.the_new_version];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware Update Available"
                                                                    message:message delegate:self cancelButtonTitle:@"Later"
                                                          otherButtonTitles:@"Update Now", nil];
                    alert.tag = kAlertView_UpdateNow;
                    [alert show];
                }
            }
        }
        
        [self.delegate updateNowAvailable:[updateInfo.update boolValue] withVersion:updateInfo.the_new_version];
    }
    else if ([data isKindOfClass:[UpdateStartInfo class]]) {
        [self stop];
        UpdateStartInfo *updateInfo = (UpdateStartInfo*)data;
        if ([updateInfo.statusCode intValue] == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFirmwareUpdateNeeded object:[NSNumber numberWithInt:serverAPIMainVersion]];
        }
    }
}

- (void)loggedOut
{
    [self.serverProxy cancelAllOperations];
    self.serverProxy = nil;
}

- (void)startUpdate
{
    [self.serverProxy requestUpdateStartForVersion:serverAPIMainVersion];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_UpdateNow) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            [self startUpdate];
        }
    }
    else if (theAlertView.tag == kAlertView_Error) {
        self.alertView = nil;
    }
}

- (void)handleSprinklerError:(NSString *)errorMessage title:(NSString*)titleMessage showErrorMessage:(BOOL)showErrorMessage{
    if ((errorMessage) && (showErrorMessage)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:titleMessage message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kAlertView_Error;
        [self.alertView show];
    }
}

- (void)handleSprinklerNetworkError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [self handleSprinklerError:errorMessage title:@"Network error" showErrorMessage:showErrorMessage];
}

#pragma mark - Alert view

- (void)handleServerLoggedOutUser {
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [StorageManager current].currentSprinkler = nil;
    [[StorageManager current] saveData];
}

@end
