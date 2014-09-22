//
//  ProgramWateringTimes.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramWateringTimes4.h"

@implementation ProgramWateringTimes4

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    
    [dic setObject:[NSNumber numberWithInt:_wtId] forKey:@"id"];
    [dic setObject:[NSNumber numberWithInt:_duration / 60] forKey:@"duration"];
    [dic setObject:[NSNumber numberWithBool:_active] forKey:@"active"];

    if (_name) {
        [dic setObject:_name forKey:@"name"];
    } else {
        [dic setObject:@"" forKey:@"name"];
    }

    return dic;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    ProgramWateringTimes4 *pWateringTimes = [(ProgramWateringTimes4 *)[[self class] allocWithZone:zone] init];
    
    pWateringTimes.wtId = self.wtId;
    pWateringTimes.name = [self.name copy];
    pWateringTimes.duration = self.duration;
    pWateringTimes.active = self.active;
    
    return pWateringTimes;
}

- (BOOL)isEqualToProgramWateringTime:(ProgramWateringTimes4*)wt
{
    BOOL isEqual = YES;
    
    isEqual &= (wt.wtId == self.wtId);
    isEqual &= (wt.duration == self.duration);
    isEqual &= (wt.active == self.active);
    isEqual &= ([wt.name isEqualToString:self.name]);
    
    return isEqual;
}

- (int)minutes
{
    return _duration;
}

- (void)setMinutes:(int)m
{
    _duration = m;
}

@end
