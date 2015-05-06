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
#import "Sprinkler.h"
#import "CloudUtils.h"

NSString *PersistentGlobalsKey      = @"PersistentGlobalsKey";

#pragma mark -

@interface GlobalsManager ()

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) NSTimer *pollCloudSettingsTimer;

- (void)requestProvision;
- (void)requestCloudSettings;

- (NSDictionary*)persistentGlobalsForSprinkler:(Sprinkler*)sprinkler;
- (void)setPersistentGlobals:(NSDictionary*)globals forSprinkler:(Sprinkler*)sprinkler;

@property (strong, nonatomic) NSString *refreshedCloudSprinklerPassword;

@end

#pragma mark - 

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

#pragma mark - Persistency

- (id)persistentGlobalForKey:(NSString*)key {
    NSDictionary *persistentGlobals = [self persistentGlobalsForSprinkler:[Utils currentSprinkler]];
    return [persistentGlobals objectForKey:key];
}

- (void)setPersistentGlobal:(id)value forKey:(NSString*)key {
    NSMutableDictionary *persistentGlobals = [[self persistentGlobalsForSprinkler:[Utils currentSprinkler]] mutableCopy];
    if (!persistentGlobals) persistentGlobals = [NSMutableDictionary new];
    
    [persistentGlobals setObject:value forKey:key];
    [self setPersistentGlobals:persistentGlobals forSprinkler:[Utils currentSprinkler]];
}

- (void)resetPersistentGlobals {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PersistentGlobalsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary*)persistentGlobalsForSprinkler:(Sprinkler*)sprinkler {
    if (!sprinkler.sprinklerId.length) return nil;
    
    NSDictionary *persistentGlobalsDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:PersistentGlobalsKey];
    return [persistentGlobalsDictionary objectForKey:sprinkler.sprinklerId];
}

- (void)setPersistentGlobals:(NSDictionary*)globals forSprinkler:(Sprinkler*)sprinkler {
    if (!sprinkler.sprinklerId.length) return;
    
    NSMutableDictionary *persistentGlobalsDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:PersistentGlobalsKey] mutableCopy];
    if (!persistentGlobalsDictionary) persistentGlobalsDictionary = [NSMutableDictionary new];
    
    [persistentGlobalsDictionary setObject:globals forKey:sprinkler.sprinklerId];
    
    [[NSUserDefaults standardUserDefaults] setObject:persistentGlobalsDictionary forKey:PersistentGlobalsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Cloud support

- (void)shouldRefreshCloudSprinklerWithPassword:(NSString*)password {
    self.refreshedCloudSprinklerPassword = password;
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
        if (self.refreshedCloudSprinklerPassword) {
            NSString *email = self.cloudSettings.pendingEmail;
            if (!email.length) email = self.cloudSettings.email;
            
            if ([CloudUtils existsCloudAccountWithEmail:email]) [CloudUtils updateCloudAccountWithEmail:email newPassword:self.refreshedCloudSprinklerPassword];
            else [CloudUtils addCloudAccountWithEmail:email password:self.refreshedCloudSprinklerPassword];
            
            self.refreshedCloudSprinklerPassword = nil;
        }
    }
}

- (void)loggedOut
{
}

@end
