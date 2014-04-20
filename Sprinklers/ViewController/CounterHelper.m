//
//  WaterNowCounterBase.m
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "CounterHelper.h"
#import "Utils.h"

@interface CounterHelper()

@property (weak, nonatomic) id<CounterHelperDelegate> delegate;
@property (assign, nonatomic) int interval;

@end

@implementation CounterHelper

- (id)initWithDelegate:(id<CounterHelperDelegate>)del interval:(int)interval
{
    self = [super init];
    if (self) {
        self.delegate = del;
        self.interval = interval;
    }
    return self;
}

- (void)startCounterTimer
{
    [self stopCounterTimer];
    self.counterTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                         target:self
                                                       selector:@selector(counterTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)counterTimer:(id)notif
{
    int counter = [self.delegate counterValue] - self.interval;
    int newCounter = MAX(0, counter);
    [self.delegate setCounterValue:newCounter];
}

- (void)stopCounterTimer
{
    [self.counterTimer invalidate];
    self.counterTimer = nil;
}

- (void)updateCounter
{
    [self.delegate showCounterLabel];
    
    if (![Utils isZoneWatering:self.delegate.wateringZone]) {
        [self stopCounterTimer];
    } else {
        [self startCounterTimer];
    }
}

@end
