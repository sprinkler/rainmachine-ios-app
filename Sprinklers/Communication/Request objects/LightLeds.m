//
//  LightLeds.m
//  Sprinklers
//
//  Created by Istvan Sipos on 04/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "LightLeds.h"
#import "ServerProxy.h"

#pragma mark -

@interface LightLeds ()

@property (strong, nonatomic) ServerProxy *enableLightLEDsProxy;

@end

#pragma mark -

@implementation LightLeds

+ (LightLeds*)sharedLightLeds {
    static LightLeds *sharedLightLeds = nil;
    if (!sharedLightLeds) sharedLightLeds = [LightLeds new];
    return sharedLightLeds;
}

- (void)enableLightLeds {
    if (!self.sprinklerURL.length) return;
    self.enableLightLEDsProxy = [[ServerProxy alloc] initWithServerURL:self.sprinklerURL delegate:self jsonRequest:YES];
    [self.enableLightLEDsProxy enableLightLEDs:YES];
}

- (void)disableLightLeds {
    if (!self.sprinklerURL.length) return;
    self.enableLightLEDsProxy = [[ServerProxy alloc] initWithServerURL:self.sprinklerURL delegate:self jsonRequest:YES];
    [self.enableLightLEDsProxy enableLightLEDs:NO];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation*)operation userInfo:(id)userInfo {
    if (serverProxy == self.enableLightLEDsProxy) {
        self.enableLightLEDsProxy = nil;
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.enableLightLEDsProxy) {
        self.enableLightLEDsProxy = nil;
    }
}

- (void)loggedOut {
}

@end
