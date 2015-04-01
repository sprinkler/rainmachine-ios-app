//
//  GraphTimeIntervalPart.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphDataSource;

typedef enum {
    GraphTimeIntervalPartType_DisplayWeekdays,
    GraphTimeIntervalPartType_DisplayDays,
    GraphTimeIntervalPartType_DisplayMonths
} GraphTimeIntervalPartType;

@interface GraphTimeIntervalPart : NSObject

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) NSInteger length;
@property (nonatomic, assign) GraphTimeIntervalPartType type;

@property (nonatomic, strong) NSArray *dateValues;
@property (nonatomic, strong) NSArray *monthValues;
@property (nonatomic, strong) NSArray *yearValues;

@property (nonatomic, strong) NSArray *dateStrings;
@property (nonatomic, strong) NSArray *weekdays;
@property (nonatomic, strong) NSString *prevDateString;
@property (nonatomic, strong) NSString *nextDateString;
@property (nonatomic, strong) NSString *timeIntervalPartStartValue;
@property (nonatomic, strong) NSString *timeIntervalPartEndValue;

@property (nonatomic, assign) NSInteger currentDateValueIndex;

- (void)initialize;

- (NSArray*)timeIntervalRestrictedValuesForGraphDataSource:(GraphDataSource*)dataSource;
- (NSArray*)timeIntervalRestrictedValuesForGraphDataSource:(GraphDataSource*)dataSource
                                             prevDateValue:(id*)prevDateValue
                                             nextDateValue:(id*)nextDateValue;
- (NSArray*)timeIntervalRestrictedTopValuesForGraphDataSource:(GraphDataSource*)dataSource;
- (NSArray*)timeIntervalRestrictedIconImageIndexesForGraphDataSource:(GraphDataSource*)dataSource;

@end
