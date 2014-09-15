//
//  ProgramWateringTimes.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgramWateringTimes4 : NSObject<NSCopying>

@property (nonatomic) int wtId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int duration;
@property (nonatomic) BOOL active;

- (NSDictionary*)toDictionary;
- (BOOL)isEqualToProgramWateringTime:(ProgramWateringTimes4*)wt;

- (int)minutes;
- (void)setMinutes:(int)m;

@end
