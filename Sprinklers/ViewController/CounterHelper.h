//
//  WaterNowCounterBase.h
//  Sprinklers
//
//  Created by Fabian Matyas on 24/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "WaterNowZone.h"

@interface CounterHelper : NSObject

@property (strong, nonatomic) NSTimer *counterTimer;

- (id)initWithDelegate:(id<CounterHelperDelegate>)delegate interval:(int)interval;
- (void)updateCounter;
- (void)stopCounterTimer;

@end
