//
//  GraphDataSource.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSource.h"
#import "GraphDataFormatter.h"
#import "GraphsManager.h"
#import "ServerProxy.h"
#import "Utils.h"
#import "Additions.h"

#pragma mark -

@interface GraphDataSource ()

- (void)updateMinMaxValuesFromValues:(NSArray*)values;

@end

#pragma mark -

@implementation GraphDataSource

#pragma mark - Initialization

+ (GraphDataSource*)defaultDataSource {
    GraphDataSource *dataSource = [self new];
    return dataSource;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _minValue = -1.0;
    _midValue = 0.0;
    _maxValue = 1.0;
    
    return self;
}

- (void)reloadGraphDataSource {
    NSDictionary *values = [self valuesFromLoadedData];
    
    [self updateMinMaxValuesFromValues:values.allValues];
    if (values) self.values = values;
    
    NSDictionary *topValues = [self topValuesFromLoadedData];
    if (topValues) self.topValues = topValues;
    
    NSDictionary *iconImageIndexes = [self iconImageIndexesFromLoadedData];
    if (iconImageIndexes) self.iconImageIndexes = iconImageIndexes;
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatter class];
}

- (BOOL)shouldRoundMidValue {
    return YES;
}

#pragma mark - Override in subclasses

- (NSDictionary*)valuesFromLoadedData {
    return nil;
}

- (NSDictionary*)topValuesFromLoadedData {
    return nil;
}

- (NSDictionary*)iconImageIndexesFromLoadedData {
    return nil;
}

- (NSArray*)valuesForGraphDataFormatter {
    return nil;
}

#pragma mark - Helper methods

- (NSDictionary*)valuesFromArray:(NSArray*)array key:(NSString*)key {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (id item in array) {
        NSString *day = [item valueForKey:@"day"];
        id value = [item valueForKey:key];
        if (!day.length || !value) continue;
        
        values[day] = value;
    }
    
    return values;
}

- (void)updateMinMaxValuesFromValues:(NSArray*)values {
    if (!values.count) return;
    
    double minValue = 0.0;
    double maxValue = 0.0;
    
    BOOL minValueSet = NO;
    BOOL maxValueSet = NO;
    
    for (id value in values) {
        if (value == [NSNull null]) continue;
        NSNumber *numberValue = (NSNumber*)value;
        
        if (!minValueSet) minValue = floor(numberValue.doubleValue);
        if (!maxValueSet) maxValue = ceil(numberValue.doubleValue);
        minValueSet = maxValueSet = YES;
        
        if (numberValue.doubleValue < minValue) minValue = floor(numberValue.doubleValue);
        if (numberValue.doubleValue > maxValue) maxValue = ceil(numberValue.doubleValue);
    }
    
    if (minValue == maxValue) {
        if (maxValue > 0.0) minValue = 0.0;
        else if (maxValue < 0.0) maxValue = 0.0;
        else {
            maxValue = 1.0;
            minValue = - 1.0;
        }
    }
    
    double midValue = (minValue + maxValue) / 2.0;
    if (self.shouldRoundMidValue && midValue != round(midValue)) {
        minValue = minValue - 1;
        midValue = (minValue + maxValue) / 2.0;
    }
    
    self.minValue = minValue;
    self.maxValue = maxValue;
    self.midValue = midValue;
}

@end
