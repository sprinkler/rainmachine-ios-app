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

@interface WaterNowCounterHelper : NSObject

@property (strong, nonatomic) NSTimer *counterTimer;
@property (strong, nonatomic) NSNumber *counterValue;

- (id)initWithDelegate:(id<WaterNowCounterHelperDelegate>)delegate;
- (void)updateCounter;
- (void)stopCounterTimer;

@end
