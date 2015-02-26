//
//  HourlyRestriction.m
//  Sprinklers
//
//  Created by Fabian Matyas on 27/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "HourlyRestriction.h"

@implementation HourlyRestriction

+ (HourlyRestriction*)restriction
{
    HourlyRestriction *restriction = [HourlyRestriction new];

    restriction.uid = @1;
    restriction.interval = @"0:1 - 1:1";
    restriction.dayStartMinute = @1;
    restriction.minuteDuration = @60;
    restriction.weekDays = @"1111111";

    return restriction;
    
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HourlyRestriction *restriction = [(HourlyRestriction *)[[self class] allocWithZone:zone] init];
    
    restriction.uid = [self.uid copy];
    restriction.interval = [self.interval copy];
    restriction.dayStartMinute = [self.dayStartMinute copy];
    restriction.minuteDuration = [self.minuteDuration copy];
    restriction.weekDays = [self.weekDays copy];
    
    return restriction;
}

- (BOOL)isEqualToRestriction:(HourlyRestriction*)restriction
{
    BOOL isEqual = YES;
   
    isEqual &= [restriction.uid isEqualToNumber:self.uid];
    isEqual &= [restriction.interval isEqualToString:self.interval];
    isEqual &= [restriction.dayStartMinute isEqualToNumber:self.dayStartMinute];
    isEqual &= [restriction.minuteDuration isEqualToNumber:self.minuteDuration];
    isEqual &= [restriction.weekDays isEqualToString:self.weekDays];

    return isEqual;
}

@end
