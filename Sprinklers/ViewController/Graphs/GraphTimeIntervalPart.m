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

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _currentDateValueIndex = -1;
    
    return self;
}

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
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%02d",(int)dateComponents.day];
            [dateValues addObject:dateValue];
            
            NSInteger weekday = dateComponents.weekday - calendar.firstWeekday;
            if (weekday < 0) weekday += 7;
            if (weekday < 7) [weekdays addObject:abbrevWeekdays[weekday]];
            
            if ([date isEqualToDateIgnoringTime:currentDate]) self.currentDateValueIndex = index;
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayDays) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%02d",(int)dateComponents.day];
            [dateValues addObject:dateValue];
            
            if ([date isEqualToDateIgnoringTime:currentDate]) self.currentDateValueIndex = index;
        }
        else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:date];
            NSString *dateValue = [NSString stringWithFormat:@"%@",abbrevMonthsOfYear[dateComponents.month - 1]];
            [dateValues addObject:dateValue];
            
            if ([date isSameMonthAsDate:currentDate]) self.currentDateValueIndex = index;
        }
        
        dayOffset += dayIncrementer;
    }
    
    self.dateValues = dateValues;
    self.weekdays = weekdays;
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

- (void)createTimeIntervalPartValue {
    if (self.type == GraphTimeIntervalPartType_DisplayWeekdays) {
        static NSDateFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"MMM";
        }
        self.timeIntervalPartStartValue = [dateFormatter stringFromDate:self.startDate];
        self.timeIntervalPartEndValue = [dateFormatter stringFromDate:self.endDate];
    }
    else if (self.type == GraphTimeIntervalPartType_DisplayDays) {
        static NSDateFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"MMM";
        }
        self.timeIntervalPartStartValue = [dateFormatter stringFromDate:self.startDate];
        self.timeIntervalPartEndValue = [dateFormatter stringFromDate:self.endDate];
    }
    else if (self.type == GraphTimeIntervalPartType_DisplayMonths) {
        static NSDateFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"yy";
        }
        self.timeIntervalPartStartValue = [NSString stringWithFormat:@"'%@",[dateFormatter stringFromDate:self.startDate]];
        self.timeIntervalPartEndValue = [NSString stringWithFormat:@"'%@",[dateFormatter stringFromDate:self.endDate]];
    }
}

@end
