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
    GraphTimeIntervalPartType_DisplayDays,
    GraphTimeIntervalPartType_DisplayMonths
} GraphTimeIntervalPartType;

@interface GraphTimeIntervalPart : NSObject

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) NSInteger length;
@property (nonatomic, assign) GraphTimeIntervalPartType type;

@property (nonatomic, strong) NSArray *dateValues;
@property (nonatomic, strong) NSArray *dateStrings;
@property (nonatomic, strong) NSDictionary *randValues;
@property (nonatomic, strong) NSString *timeIntervalPartValue;

- (void)initialize;

- (NSArray*)timeIntervalRestrictedValuesForGraphDataSource:(GraphDataSource*)dataSource;
- (NSArray*)timeIntervalRestrictedTopValuesForGraphDataSource:(GraphDataSource*)dataSource;
- (NSArray*)timeIntervalRestrictedIconImageIndexesForGraphDataSource:(GraphDataSource*)dataSource;

@end
