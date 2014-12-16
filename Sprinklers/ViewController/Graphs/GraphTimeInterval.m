//
//  GraphTimeInterval.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphTimeInterval.h"
#import "Constants.h"

#pragma mark -

@interface GraphTimeInterval ()

@property (nonatomic, assign) GraphTimeIntervalType type;
@property (nonatomic, strong) NSString *name;

+ (void)registerGraphTimeIntervalWithType:(GraphTimeIntervalType)type name:(NSString*)name;

@property (nonatomic, readonly) NSString *currentMonthString;
@property (nonatomic, readonly) NSString *currentYearString;
@property (nonatomic, readonly) NSArray *monthsOfYear;

- (NSArray*)daysArrayInWeekCurrentDateValueIndex:(NSInteger*)currentDateValueIndex;
- (NSArray*)daysArrayInMonthWithCount:(NSInteger)count currentDateValueIndex:(NSInteger*)currentDateValueIndex;
- (NSArray*)monthsArrayInYearWithCount:(NSInteger)count currentDateValueIndex:(NSInteger*)currentDateValueIndex;

@end

#pragma mark -

@implementation GraphTimeInterval

static NSMutableDictionary *registeredTimeIntervalsDictionary = nil;
static NSMutableArray *registeredTimeIntervals = nil;

+ (void)registerGraphTimeIntervalWithType:(GraphTimeIntervalType)type name:(NSString*)name {
    if (!registeredTimeIntervalsDictionary) registeredTimeIntervalsDictionary = [NSMutableDictionary new];
    if (!registeredTimeIntervals) registeredTimeIntervals = [NSMutableArray new];
    
    if ([registeredTimeIntervalsDictionary objectForKey:@(type)]) return;
    
    GraphTimeInterval *graphTimeInterval = [GraphTimeInterval new];
    graphTimeInterval.type = type;
    graphTimeInterval.name = name;
    
    [registeredTimeIntervalsDictionary setObject:graphTimeInterval forKey:@(type)];
    [registeredTimeIntervals addObject:graphTimeInterval];
}

+ (void)initialize {
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Weekly name:@"Week"];
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Monthly name:@"Month"];
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Yearly name:@"Year"];
}

+ (GraphTimeInterval*)graphTimeIntervalWithType:(GraphTimeIntervalType)type {
    return [registeredTimeIntervalsDictionary objectForKey:@(type)];
}

+ (NSArray*)graphTimeIntervals {
    return registeredTimeIntervals;
}

- (NSString*)timeIntervalValue {
    if (self.type == GraphTimeIntervalType_Weekly) return self.currentMonthString;
    if (self.type == GraphTimeIntervalType_Monthly) return self.currentMonthString;
    if (self.type == GraphTimeIntervalType_Yearly) return self.currentYearString;
    return nil;
}

- (NSArray*)dateValuesForCount:(NSInteger)count currentDateValueIndex:(NSInteger*)currentDateValueIndex {
    if (self.type == GraphTimeIntervalType_Weekly) return [self daysArrayInWeekCurrentDateValueIndex:currentDateValueIndex];
    if (self.type == GraphTimeIntervalType_Monthly) return [self daysArrayInMonthWithCount:count currentDateValueIndex:currentDateValueIndex];
    if (self.type == GraphTimeIntervalType_Yearly) return [self monthsArrayInYearWithCount:count currentDateValueIndex:currentDateValueIndex];
    return nil;
}

#pragma mark - Helper methods

- (NSString*)currentMonthString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"MMM";
    return [[dateFormatter stringFromDate:[NSDate date]] lowercaseString];
}

- (NSString*)currentYearString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yy";
    return [NSString stringWithFormat:@"'%@",[dateFormatter stringFromDate:[NSDate date]]];
}

- (NSArray*)monthsOfYear {
    return [NSArray arrayWithObjects:abbrevMonthsOfYear count:12];
}

- (NSArray*)daysArrayInWeekCurrentDateValueIndex:(NSInteger*)currentDateValueIndex {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:date];
    NSRange daysRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
    
    NSInteger firstDay = dateComponents.day - 3;
    NSInteger lastDay = dateComponents.day + 3;
    NSInteger currentDayIndex = 3;
    
    if (firstDay < 1) {
        currentDayIndex += (1 - firstDay);
        lastDay += (1 - firstDay);
        firstDay = 1;
    }
    
    if (lastDay > daysRange.length) {
        currentDayIndex -= (lastDay - daysRange.length);
        firstDay -= (lastDay - daysRange.length);
        lastDay = daysRange.length;
    }
    
    NSMutableArray *daysArray = [NSMutableArray new];
    
    for (NSInteger index = firstDay; index <= lastDay; index++) {
        [daysArray addObject:[NSString stringWithFormat:@"%02d",(int)index]];
    }
    
    if (currentDateValueIndex) *currentDateValueIndex = currentDayIndex;
    
    return daysArray;
}

- (NSArray*)daysArrayInMonthWithCount:(NSInteger)count currentDateValueIndex:(NSInteger*)currentDateValueIndex {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:date];
    NSRange daysRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
    
    double intervalLength = (daysRange.length - 1) / (count - 1.0);
    double dayIndex = 0.0;
    double oldDayIndex = 0.0;
    
    NSInteger currentDayIndex = -1;
    NSMutableArray *daysArray = [NSMutableArray new];
    
    for (NSInteger index = 0; index < count; index++) {
        NSString *day = [NSString stringWithFormat:@"%02d",(int)(round(dayIndex) + 1)];
        [daysArray addObject:day];
        
        if (round(dayIndex) + 1 < dateComponents.day && dateComponents.day < round(dayIndex) + 1) {
            [daysArray removeLastObject];
            [daysArray addObject:[NSString stringWithFormat:@"%02d",(int)dateComponents.day]];
            currentDayIndex = index;
        } else if (round(dayIndex) + 1 == dateComponents.day) {
            currentDayIndex = index;
        }
        
        dayIndex += intervalLength;
        oldDayIndex = dayIndex;
    }
    
    if (currentDateValueIndex) *currentDateValueIndex = currentDayIndex;
    
    return daysArray;
}

- (NSArray*)monthsArrayInYearWithCount:(NSInteger)count currentDateValueIndex:(NSInteger*)currentDateValueIndex {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:date];
    
    NSArray *monthsOfYear = self.monthsOfYear;
    
    double intervalLength = (monthsOfYear.count - 1) / (count - 1.0);
    double monthIndex = 0.0;
    double oldMonthIndex = 0.0;
    
    NSInteger currentMonthIndex = -1;
    NSMutableArray *monthsArray = [NSMutableArray new];
    
    for (NSInteger index = 0; index < count; index++) {
        if (monthIndex > monthsOfYear.count - 1) monthIndex = monthsOfYear.count - 1;
        
        NSString *month = [[monthsOfYear objectAtIndex:(int)round(monthIndex)] lowercaseString];
        [monthsArray addObject:month];
        
        if (round(oldMonthIndex) + 1 < dateComponents.month && dateComponents.month < round(monthIndex) + 1) {
            [monthsArray removeLastObject];
            [monthsArray addObject:[[monthsOfYear objectAtIndex:dateComponents.month - 1] lowercaseString]];
            currentMonthIndex = index;
        } else if (round(monthIndex) + 1 == dateComponents.month) {
            currentMonthIndex = index;
        }
        
        monthIndex += intervalLength;
        oldMonthIndex = monthIndex;
    }
    
    if (*currentDateValueIndex) *currentDateValueIndex = currentMonthIndex;
    
    return monthsArray;
}

@end
