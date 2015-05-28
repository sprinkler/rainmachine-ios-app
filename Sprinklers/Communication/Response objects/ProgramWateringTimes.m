//
//  ProgramWateringTimes.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramWateringTimes.h"

@implementation ProgramWateringTimes

- (ProgramWateringTimes*)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    
    [dic setObject:[NSNumber numberWithInt:_wtId] forKey:@"id"];
    [dic setObject:[NSNumber numberWithInt:_minutes] forKey:@"minutes"];

    if (_name) {
        [dic setObject:_name forKey:@"name"];
    } else {
        [dic setObject:@"" forKey:@"name"];
    }

    return dic;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    ProgramWateringTimes *pWateringTimes = [(ProgramWateringTimes *)[[self class] allocWithZone:zone] init];
    
    pWateringTimes.wtId = self.wtId;
    pWateringTimes.name = [self.name copy];
    pWateringTimes.minutes = self.minutes;
    
    return pWateringTimes;
}

- (BOOL)isEqualToProgramWateringTime:(ProgramWateringTimes*)wt
{
    BOOL isEqual = YES;
    
    isEqual &= (wt.wtId == self.wtId);
    isEqual &= (wt.minutes == self.minutes);
    isEqual &= ([wt.name isEqualToString:self.name]);
    
    return isEqual;
}

- (int)duration {
    return _minutes * 60;
}

@end
