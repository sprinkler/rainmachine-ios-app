//
//  RainDelayPoller.m
//  Sprinklers
//
//  Created by Fabian Matyas on 20/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "Utils.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "Constants.h"

@interface RainDelayPoller()

@property (strong, nonatomic) ServerProxy *rainDelayServerProxy;
@property (strong, nonatomic) ServerProxy *rainDelayPostServerProxy;
@property (strong, nonatomic) NSDate *lastRainDelayPollDate;
@property (assign, nonatomic) id<RainDelayPollerDelegate> delegate;
@end

@implementation RainDelayPoller

- (id)initWithDelegate:(id<RainDelayPollerDelegate>)del {
    self = [super init];
    if (self) {
        self.rainDelayServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        self.rainDelayPostServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
        self.lastRainDelayPollDate = [NSDate date];
        self.delegate = del;
    }
    return self;
}

- (void)scheduleNextPoll:(int)interval
{
    [self scheduleNextPollRequest:interval withServerProxy:self.rainDelayServerProxy referenceDate:self.lastRainDelayPollDate];
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo
{
    [self.delegate hideHUD];
    
    [self.delegate handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.rainDelayPostServerProxy) {
        self.rainDelayData = nil;
        [self updatePollState];
        [self.delegate hideRainDelayActivityIndicator:YES];
    }
    
    [self.delegate refreshStatus];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self.delegate hideHUD];
    
    if (serverProxy == self.rainDelayPostServerProxy) {
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.delegate handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            self.rainDelayData.rainDelay = [userInfo objectForKey:@"rainDelay"];
            if ([self.rainDelayData.rainDelay intValue] == 0)
            {
                self.rainDelayData.rainDelay = @1;
                self.rainDelayData.delayCounter = @-1;
            } else {
                self.rainDelayData.delayCounter = [NSNumber numberWithInt:[[userInfo objectForKey:@"rainDelay"] intValue] * kOneDayInSeconds - 1];
            }
            
            [self updatePollState];
        }
        [self.delegate hideRainDelayActivityIndicator:YES];
    }
    else if (serverProxy == self.rainDelayServerProxy) {
        [self.delegate handleSprinklerNetworkError:nil operation:nil showErrorMessage:YES];
        self.rainDelayData = (RainDelay*)data;
        if ([self.rainDelayData.rainDelay intValue] == 0)
        {
            self.rainDelayData.rainDelay = @1;
            self.rainDelayData.delayCounter = @-1;
        }
        [self updatePollState];
    }
    
    [self.delegate rainDelayResponseReceived];
}

- (void)loggedOut
{
    [self.delegate loggedOut];
}

#pragma mark - Methods

- (void)cancel
{
    [self.rainDelayServerProxy cancelAllOperations];
    [self.rainDelayPostServerProxy cancelAllOperations];
}

- (void)setRainDelay
{
    [self stopPollRequests];
    if ([self rainDelayMode]) {
        [self.rainDelayPostServerProxy setRainDelay:@0];
    } else {
        [self.rainDelayPostServerProxy setRainDelay:_rainDelayData.rainDelay];
    }
}

- (void)stopPollRequests
{
    [self.rainDelayServerProxy cancelAllOperations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)requestStateRefreshWithServerProxy:(ServerProxy*)serverProxy
{
    [serverProxy getRainDelay];
    
    self.lastRainDelayPollDate = [NSDate date];
}

- (void)scheduleNextPollRequest:(NSTimeInterval)scheduleInterval withServerProxy:(ServerProxy*)serverProxy referenceDate:(NSDate*)referenceDate
{
    if (serverProxy == self.rainDelayServerProxy) {
        // Clear previously scheduled pollServerProxy requests
        [self stopPollRequests];
    }
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:referenceDate];
    
    if (t >= scheduleInterval) {
        [self requestStateRefreshWithServerProxy:serverProxy];
    } else {
        [self performSelector:@selector(requestStateRefreshWithServerProxy:) withObject:serverProxy afterDelay:scheduleInterval - t];
    }
}

- (void)updatePollState
{
    if (![self rainDelayMode]) {
        [self stopPollRequests];
    } else {
        [self scheduleNextPollRequest:kRainDelayRefreshTimeInterval withServerProxy:self.rainDelayServerProxy referenceDate:self.lastRainDelayPollDate];
    }
}

- (BOOL)rainDelayMode
{
    return ((self.rainDelayData) && [self.rainDelayData.delayCounter intValue] != -1);
}

@end
