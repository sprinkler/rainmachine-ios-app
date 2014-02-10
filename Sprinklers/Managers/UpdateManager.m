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

@interface UpdateManager () {
    int serverAPIMainVersion;
}

@property (strong, nonatomic) ServerProxy *serverProxy;

@end
    
static UpdateManager *current = nil;

@implementation UpdateManager

#pragma mark - Singleton

+ (UpdateManager*)current {
	@synchronized(self) {
		if (current == nil)
			current = [[super alloc] init];
	}
	return current;
}

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

- (void)poll
{
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

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
    [self.serverProxy cancelAllOperations];
    self.serverProxy = nil;
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
    if ([data isKindOfClass:[APIVersion class]]) {
        APIVersion *apiVersion = (APIVersion*)data;
        NSArray *versionComponents = [apiVersion.apiVer componentsSeparatedByString:@"."];
        if ([versionComponents[0] intValue] >= 3) {
            // Firmware update is supported by server
            serverAPIMainVersion = [versionComponents[0] intValue];
            [self.serverProxy requestUpdateCheckForVersion:serverAPIMainVersion];
        }
    }
    else if ([data isKindOfClass:[UpdateInfo class]]) {
        UpdateInfo *updateInfo = (UpdateInfo*)data;
        if ([updateInfo.update boolValue]) {
            NSDate *lastUpdateCheck = [NSDate dateWithTimeIntervalSince1970:[updateInfo.last_update_check longLongValue]];
            NSTimeInterval intervalSinceLastUpdate = -[lastUpdateCheck timeIntervalSinceNow];
            BOOL checkUpdate = (intervalSinceLastUpdate >= kSprinklerUpdateCheckInterval);
            if (checkUpdate) {
                NSString *message = [NSString stringWithFormat:@"Please update your device firmware to version %@.", updateInfo.the_new_version];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Firmware Update Available"
                                                                message:message delegate:self cancelButtonTitle:@"Later"
                                                      otherButtonTitles:@"Update Now", nil];
                [alert show];
            }
        }
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

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != theAlertView.cancelButtonIndex) {
        [self.serverProxy requestUpdateStartForVersion:3];
    }
}

@end
