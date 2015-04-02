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

@end

#pragma mark -

@implementation GraphTimeIntervalPart

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _currentDateValueIndex = -1;
    
    return self;
}

- (void)initialize {
    [self createDateValues];
    [self createDateStrings];
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

- (NSArray*)timeIntervalRestrictedValuesForGraphDataSource:(GraphDataSource*)dataSource
                                             prevDateValue:(id*)prevDateValue
                                             nextDateValue:(id*)nextDateValue {

    NSArray *timeIntervalRestrictedValues = [self timeIntervalRestrictedValuesForGraphDataSource:dataSource];
    
    if (prevDateValue) {
        id prevValue = dataSource.values[self.prevDateString];
        if (!prevValue) prevValue = [NSNull null];
        *prevDateValue = prevValue;
    }
    
    if (nextDateValue) {
        id nextValue = dataSource.values[self.nextDateString];
        if (!nextValue) nextValue = [NSNull null];
        *nextDateValue = nextValue;
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
    NSDate *currentDate = [NSDate date];
    
    NSMutableArray *dateValues = [NSMutableArray new];
    NSMutableArray *weekdays = (self.type ==  GraphTimeIntervalPartType_DisplayWeekdays ? [NSMutableArray new] : nil);
    
    NSInteger count = 7;
    double dayIncrementer = (double)(self.length - 1) / (double)(count - 1);
    double dayOffset = 0.0;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    for (NSInteger index = 0; index < count; index++) {
        NSDate *date = [self.startDate dateByAddingDays:(NSInteger)round(dayOffset)];
        
        if (self.type == GraphTimeIntervalPartType_DisplayWeekdays) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%02d",(int)dateComponents.day];
            [dateValues addObject:dateValue];
            
            NSInteger weekday = dateComponents.weekday - calendar.firstWeekday;
            if (weekday < 0) weekday += 7;
            if (weekday < 7) [weekdays addObject:abbrevWeekdays[weekday]];
            
            if ([date isEqualToDateIgnoringTime:currentDate]) self.currentDateValueIndex = index;
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayDays) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%02d",(int)dateComponents.day];
            [dateValues addObject:dateValue];
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
            NSString *dateValue = abbrevMonthsOfYear[dateComponents.month - 1];
            [dateValues addObject:dateValue];
        }
        
        dayOffset += dayIncrementer;
    }
    
    self.dateValues = dateValues;
    self.weekdays = weekdays;
}

- (void)createDateStrings {
    NSMutableArray *dateStrings = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSMutableArray *monthValues = [NSMutableArray new];
    NSMutableArray *yearValues = [NSMutableArray new];
    
    for (NSInteger index = 0; index < self.length; index++) {
        NSDate *date = [self.startDate dateByAddingDays:index];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year, (int)dateComponents.month, (int)dateComponents.day];
        
        [dateStrings addObject:dateString];
        
        if (self.type == GraphTimeIntervalPartType_DisplayWeekdays) {
            [monthValues addObject:abbrevMonthsOfYear[dateComponents.month - 1]];
            [yearValues addObject:[NSString stringWithFormat:@"%d",(int)dateComponents.year]];
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayDays) {
            [monthValues addObject:abbrevMonthsOfYear[dateComponents.month - 1]];
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
            [yearValues addObject:[NSString stringWithFormat:@"%d",(int)dateComponents.year]];
        }
    }
    
    self.monthValues = monthValues;
    self.yearValues = yearValues;
    
    NSDate *prevDate = [self.startDate dateBySubtractingDays:1];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:prevDate];
    NSString *prevDateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year, (int)dateComponents.month, (int)dateComponents.day];
    
    NSDate *nextDate = [self.startDate dateByAddingDays:self.length];
    dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:nextDate];
    NSString *nextDateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year, (int)dateComponents.month, (int)dateComponents.day];
    
    self.prevDateString = prevDateString;
    self.nextDateString = nextDateString;
    self.dateStrings = dateStrings;
}

@end
