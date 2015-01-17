//
//  GraphTimeIntervalPart.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphTimeIntervalPart.h"
#import "GraphDataSource.h"
#import "Additions.h"
#import "Constants.h"

#pragma mark -

@interface GraphTimeIntervalPart ()

- (void)createDateValues;
- (void)createDateStrings;
- (void)createTimeIntervalPartValue;

@end

#pragma mark -

@implementation GraphTimeIntervalPart

- (void)initialize {
    [self createDateValues];
    [self createDateStrings];
    [self createTimeIntervalPartValue];
}

#pragma mark - Values and data sources

- (NSArray*)timeIntervalRestrictedValuesForGraphDataSource:(GraphDataSource*)dataSource {
    NSMutableArray *timeIntervalRestrictedValues = [NSMutableArray new];
    
    for (NSArray *dateString in self.dateStrings) {
        id value = dataSource.values[dateString];
        if (value) [timeIntervalRestrictedValues addObject:value];
        else [timeIntervalRestrictedValues addObject:[NSNull null]];
    }
    
    return timeIntervalRestrictedValues;
}

- (NSArray*)timeIntervalRestrictedTopValuesForGraphDataSource:(GraphDataSource*)dataSource {
    NSMutableArray *timeIntervalRestrictedTopValues = [NSMutableArray new];
    
    for (NSArray *dateString in self.dateStrings) {
        id value = dataSource.topValues[dateString];
        if (value) [timeIntervalRestrictedTopValues addObject:value];
        else [timeIntervalRestrictedTopValues addObject:[NSNull null]];
    }
    
    return timeIntervalRestrictedTopValues;
}

- (NSArray*)timeIntervalRestrictedIconImageIndexesForGraphDataSource:(GraphDataSource*)dataSource {
    NSMutableArray *timeIntervalRestrictedIconImageIndexes = [NSMutableArray new];
    
    for (NSArray *dateString in self.dateStrings) {
        id iconImageIndex = dataSource.iconImageIndexes[dateString];
        if (iconImageIndex) [timeIntervalRestrictedIconImageIndexes addObject:iconImageIndex];
        else [timeIntervalRestrictedIconImageIndexes addObject:[NSNull null]];
    }
    
    return timeIntervalRestrictedIconImageIndexes;
}

#pragma mark - Helper methods

- (void)createDateValues {
    NSMutableArray *dateValues = [NSMutableArray new];
    
    NSInteger count = 7;
    double dayIncrementer = (double)self.length / (double)count;
    double dayOffset = 0.0;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    for (NSInteger index = 0; index < count; index++) {
        NSDate *date = [self.startDate dateByAddingDays:(NSInteger)round(dayOffset)];
        
        if (self.type == GraphTimeIntervalPartType_DisplayDays) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%02d",(int)dateComponents.day];
            [dateValues addObject:dateValue];
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%@",[abbrevMonthsOfYear[dateComponents.month - 1] lowercaseString]];
            [dateValues addObject:dateValue];
        }
        
        dayOffset += dayIncrementer;
    }
    
    self.dateValues = dateValues;
}

- (void)createDateStrings {
    NSMutableArray *dateStrings = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    for (NSInteger index = 0; index < self.length; index++) {
        NSDate *date = [self.startDate dateByAddingDays:index];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year, (int)dateComponents.month, (int)dateComponents.day];
        
        [dateStrings addObject:dateString];
    }
    
    self.dateStrings = dateStrings;
}

- (void)createTimeIntervalPartValue {
    if (self.type == GraphTimeIntervalPartType_DisplayDays) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"MMM";
        self.timeIntervalPartValue = [[dateFormatter stringFromDate:self.startDate] lowercaseString];
    }
    else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yy";
        self.timeIntervalPartValue = [NSString stringWithFormat:@"'%@",[dateFormatter stringFromDate:self.startDate]];
    }
}

@end
