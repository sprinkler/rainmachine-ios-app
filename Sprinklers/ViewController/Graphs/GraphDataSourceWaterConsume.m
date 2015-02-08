//
//  GraphDataSourceWaterConsume.m
//  Sprinklers
//
//  Created by Istvan Sipos on 31/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceWaterConsume.h"
#import "GraphDataFormatterWaterConsume.h"
#import "GraphsManager.h"
#import "MixerDailyValue.h"
#import "WaterLogDay.h"
#import "Utils.h"

#pragma mark -

@interface GraphDataSourceWaterConsume ()

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
- (NSDictionary*)conditionValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
- (NSDictionary*)percentageValuesFromWateringLogSimulatedValues:(NSArray*)wateringLogSimulatedValues;

@end

#pragma mark -

@implementation GraphDataSourceWaterConsume

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"mixerData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"wateringLogSimulatedDetailsData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"mixerData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"wateringLogSimulatedDetailsData"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self reloadGraphDataSource];
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatterWaterConsume class];
}

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id data = [GraphsManager sharedGraphsManager].wateringLogSimulatedDetailsData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self percentageValuesFromWateringLogSimulatedValues:data];
    }
    else if ([ServerProxy usesAPI3]) {
        return @{};
    }
    return nil;
}

- (NSDictionary*)topValuesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id data = [GraphsManager sharedGraphsManager].mixerData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self maxTempValuesFromMixerDailyValues:(NSArray*)data];
    }
    else if ([ServerProxy usesAPI3]) {
        return @{};
    }
    return nil;
}

- (NSDictionary*)iconImageIndexesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id data = [GraphsManager sharedGraphsManager].mixerData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self conditionValuesFromMixerDailyValues:(NSArray*)data];
    }
    else if ([ServerProxy usesAPI3]) {
        return @{};
    }
    return nil;
}

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableArray *values = [NSMutableArray new];
    
    if ([ServerProxy usesAPI4]) {
        for (WaterLogDay *waterLogDay in [GraphsManager sharedGraphsManager].wateringLogSimulatedDetailsData) {
            [values addObject:@{@"date" : waterLogDay.date,
                                @"simulatedUserDurationSum" : @(waterLogDay.simulatedUserDurationSum),
                                @"simulatedRealDurationSum" : @(waterLogDay.simulatedRealDurationSum)}];
        }
    }
    else if ([ServerProxy usesAPI3]) {
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [values sortUsingDescriptors:@[sortDescriptor]];
    
    return values;
}

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    NSString *units = [Utils sprinklerTemperatureUnits];
    BOOL isFahrenheit = [units isEqualToString:@"F"];
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [dateFormatter stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        double maxTemp = mixerDailyValue.maxTemp;
        if (isFahrenheit) maxTemp = maxTemp * 1.8 + 32;
        
        values[day] = @(maxTemp);
    }
    
    return values;
}

- (NSDictionary*)conditionValuesFromMixerDailyValues:(NSArray*)mixerDailyValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [dateFormatter stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        values[day] = @(mixerDailyValue.condition);
    }
    
    return values;
}

- (NSDictionary*)percentageValuesFromWateringLogSimulatedValues:(NSArray*)wateringLogSimulatedValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    for (WaterLogDay *waterLogDay in wateringLogSimulatedValues) {
        NSString *date = waterLogDay.date;
        if (!date.length) continue;
        values[date] = @(waterLogDay.simulatedDurationPercentage * 100.0);
    }
    
    return values;
}

@end
