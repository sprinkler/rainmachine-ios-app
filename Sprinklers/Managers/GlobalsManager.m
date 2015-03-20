//
//  GlobalsManager.m
//  Sprinklers
//
//  Created by Fabian Matyas on 25/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GlobalsManager.h"
#import "ServerProxy.h"
#import "Utils.h"
#import "Constants.h"

@interface GlobalsManager ()

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) NSTimer *pollCloudSettingsTimer;

- (void)requestProvision;
- (void)requestCloudSettings;

@end

static GlobalsManager *current = nil;

@implementation GlobalsManager

+ (GlobalsManager*)current {
    @synchronized(self) {
        if (current == nil)
            current = [[super allocWithZone:NULL] init];
    }
    return current;
}

- (void)refresh
{
    if ([ServerProxy usesAPI4]) {
        [self requestProvision];
        [self requestCloudSettings];
    }
}

#pragma mark - Requests

- (void)requestProvision {
    ServerProxy *getProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [getProvisionServerProxy requestProvision];
}

- (void)requestCloudSettings {
    ServerProxy *requestCloudSettingsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [requestCloudSettingsServerProxy requestCloudSettings];
}

#pragma mark - Cloud settings

- (void)startPollingCloudSettings {
    if (self.pollCloudSettingsTimer) return;
    [self.pollCloudSettingsTimer invalidate];
    self.pollCloudSettingsTimer = [NSTimer scheduledTimerWithTimeInterval:kCloudSettings_PollTimeInterval
                                                                   target:self
                                                                 selector:@selector(pollCloudSettings:)
                                                                 userInfo:nil
                                                                  repeats:YES];
}

- (void)stopPollingCloudSettings {
    if (!self.pollCloudSettingsTimer) return;
    [self.pollCloudSettingsTimer invalidate];
    self.pollCloudSettingsTimer = nil;
}

- (void)pollCloudSettings:(NSTimer*)timer {
    [self requestCloudSettings];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo
{

}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    if ([data isKindOfClass:[Provision class]]) {
        self.provision = (Provision*)data;
    }
    else if ([data isKindOfClass:[CloudSettings class]]) {
        self.cloudSettings = (CloudSettings*)data;
    }
}

- (void)loggedOut
{
}

@end
