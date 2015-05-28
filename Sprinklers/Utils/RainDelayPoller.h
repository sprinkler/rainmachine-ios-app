//
//  RainDelayPoller.h
//  Sprinklers
//
//  Created by Fabian Matyas on 20/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@class RainDelay;

@interface RainDelayPoller : NSObject<SprinklerResponseProtocol>

@property (strong, nonatomic) RainDelay *rainDelayData;

- (id)initWithDelegate:(id<RainDelayPollerDelegate>)del;
- (BOOL)rainDelayMode;
- (void)setRainDelay;
- (void)scheduleNextPoll:(int)interval;
- (void)stopPollRequests;
- (void)cancel;

@end
