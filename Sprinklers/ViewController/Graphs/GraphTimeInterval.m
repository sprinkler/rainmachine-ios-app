//
//  GraphTimeInterval.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphTimeInterval.h"
#import "GraphTimeIntervalPart.h"
#import "GraphDataSource.h"
#import "GraphsManager.h"
#import "Additions.h"
#import "Constants.h"

#pragma mark -

@interface GraphTimeInterval ()

@property (nonatomic, assign) GraphTimeIntervalType type;
@property (nonatomic, strong) NSString *name;

+ (void)registerGraphTimeIntervalWithType:(GraphTimeIntervalType)type name:(NSString*)name;

@property (nonatomic, readonly) NSString *currentMonthString;
@property (nonatomic, readonly) NSString *currentYearString;
@property (nonatomic, readonly) NSArray *monthsOfYear;

@property (nonatomic, readonly) NSArray *allDateStringsInTimeInterval;
@property (nonatomic, readonly) NSArray *allDateStringsInWeek;
@property (nonatomic, readonly) NSArray *allDateStringsInMonth;
@property (nonatomic, readonly) NSArray *allDateStringsInYear;

- (void)createGraphTimeIntervalPartsArray;
- (void)createWeeklyGraphTimeIntervalParts;
- (void)createMonthlyGraphTimeIntervalParts;
- (void)createYearlyGraphTimeIntervalParts;

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
    
    [graphTimeInterval createGraphTimeIntervalPartsArray];
    
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

- (NSInteger)currentDateTimeIntervalPartIndex {
    NSDate *date = [NSDate date];
    for (GraphTimeIntervalPart *timeIntervalPart in self.graphTimeIntervalParts) {
        if ([timeIntervalPart.startDate isEqualToDateIgnoringTime:date] || [timeIntervalPart.endDate isEqualToDateIgnoringTime:date]) return [self.graphTimeIntervalParts indexOfObject:timeIntervalPart];
        if ([timeIntervalPart.startDate isEarlierThanDate:date] && [date isEarlierThanDate:timeIntervalPart.endDate]) return [self.graphTimeIntervalParts indexOfObject:timeIntervalPart];
    }
    return -1;
}

#pragma mark - Graph time interval parts

- (void)createGraphTimeIntervalPartsArray {
    if (self.type == GraphTimeIntervalType_Weekly) [self createWeeklyGraphTimeIntervalParts];
    else if (self.type == GraphTimeIntervalType_Monthly) [self createMonthlyGraphTimeIntervalParts];
    else if (self.type == GraphTimeIntervalType_Yearly) [self createYearlyGraphTimeIntervalParts];
}

- (void)createWeeklyGraphTimeIntervalParts {
    NSMutableArray *graphTimeIntervalParts = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger totalDays = 0;
    NSDate *startDate = [[GraphsManager sharedGraphsManager] startDateForGraphTimeInterval:self];
    
    NSDateComponents *startDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear | NSCalendarUnitHour fromDate:startDate];    
    startDateComponents.weekday = calendar.firstWeekday;
    startDateComponents.hour = 12;
    startDate = [calendar dateFromComponents:startDateComponents];
    
    while (totalDays < [[GraphsManager sharedGraphsManager] totalDaysForGraphTimeInterval:self]) {
        GraphTimeIntervalPart *graphTimeIntervalPart = [GraphTimeIntervalPart new];
        graphTimeIntervalPart.startDate = startDate;
        graphTimeIntervalPart.endDate = [startDate dateByAddingDays:6];
        graphTimeIntervalPart.length = 7;
        graphTimeIntervalPart.type = GraphTimeIntervalPartType_DisplayWeekdays;

        [graphTimeIntervalPart initialize];
        [graphTimeIntervalParts addObject:graphTimeIntervalPart];
        
        totalDays += graphTimeIntervalPart.length;
        startDate = [startDate dateByAddingDays:graphTimeIntervalPart.length];
    }
    
    self.graphTimeIntervalParts = graphTimeIntervalParts;
}

- (void)createMonthlyGraphTimeIntervalParts {
    NSMutableArray *graphTimeIntervalParts = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger totalDays = 0;
    NSDate *startDate = [[GraphsManager sharedGraphsManager] startDateForGraphTimeInterval:self];
    
    NSDateComponents *startDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate:startDate];
    NSInteger startDay = startDateComponents.day;
    
    startDateComponents.day = 1;
    startDateComponents.hour = 12;
    startDate = [calendar dateFromComponents:startDateComponents];
    
    while (totalDays < [[GraphsManager sharedGraphsManager] totalDaysForGraphTimeInterval:self] + startDay - 1) {
        NSRange monthRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:startDate];
        
        GraphTimeIntervalPart *graphTimeIntervalPart = [GraphTimeIntervalPart new];
        graphTimeIntervalPart.startDate = startDate;
        graphTimeIntervalPart.endDate = [startDate dateByAddingDays:monthRange.length - 1];
        graphTimeIntervalPart.length = monthRange.length;
        graphTimeIntervalPart.type = GraphTimeIntervalPartType_DisplayDays;
        
        [graphTimeIntervalPart initialize];
        [graphTimeIntervalParts addObject:graphTimeIntervalPart];
        
        totalDays += graphTimeIntervalPart.length;
        startDate = [startDate dateByAddingDays:graphTimeIntervalPart.length];
    }
    
    self.graphTimeIntervalParts = graphTimeIntervalParts;
}

- (void)createYearlyGraphTimeIntervalParts {
    NSDate *startDate = [[GraphsManager sharedGraphsManager] startDateForGraphTimeInterval:self];
    NSInteger totalDays = [[GraphsManager sharedGraphsManager] totalDaysForGraphTimeInterval:self];
    
    GraphTimeIntervalPart *graphTimeIntervalPart = [GraphTimeIntervalPart new];
    graphTimeIntervalPart.startDate = startDate;
    graphTimeIntervalPart.endDate = [startDate dateByAddingDays:totalDays];
    graphTimeIntervalPart.length = totalDays;
    graphTimeIntervalPart.type = GraphTimeIntervalPartType_DisplayMonths;
    
    [graphTimeIntervalPart initialize];
    
    self.graphTimeIntervalParts = @[graphTimeIntervalPart];
}

@end
