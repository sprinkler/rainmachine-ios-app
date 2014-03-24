//
//  WaterNowCounterBase.m
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "WaterNowCounterHelper.h"
#import "Utils.h"

@interface WaterNowCounterHelper()

@property (weak, nonatomic) id<WaterNowCounterHelperDelegate> delegate;

@end

@implementation WaterNowCounterHelper

- (id)initWithDelegate:(id<WaterNowCounterHelperDelegate>)del
{
    self = [super init];
    if (self) {
        self.delegate = del;
    }
    return self;
}

- (void)startCounterTimer
{
    [self stopCounterTimer];
    self.counterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(counterTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)counterTimer:(id)notif
{
    int counter = [self.delegate.wateringZone.counter intValue] - 1;
    int newCounter = MAX(0, counter);
    self.delegate.wateringZone.counter = [NSNumber numberWithInt:newCounter];
    [self.delegate refreshCounterLabel:newCounter];
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
