//
//  ProgramWateringTimes.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgramWateringTimes : NSObject<NSCopying>

@property (nonatomic) int wtId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int minutes;

- (NSDictionary*)toDictionary;
- (BOOL)isEqualToProgramWateringTime:(ProgramWateringTimes*)wt;

@end
