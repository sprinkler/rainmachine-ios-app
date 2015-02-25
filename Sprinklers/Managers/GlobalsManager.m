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

@interface GlobalsManager ()

@property (strong, nonatomic) ServerProxy *serverProxy;

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
    ServerProxy *getProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [getProvisionServerProxy requestProvision];
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
}

- (void)loggedOut
{
}

@end
