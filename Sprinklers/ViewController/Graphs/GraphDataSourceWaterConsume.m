//
//  GraphDataSourceWaterConsume.m
//  Sprinklers
//
//  Created by Istvan Sipos on 31/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceWaterConsume.h"
#import "GraphsManager.h"
#import "MixerDailyValue.h"
#import "WaterLogDay.h"

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

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    id data = [GraphsManager sharedGraphsManager].wateringLogSimulatedDetailsData;
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self percentageValuesFromWateringLogSimulatedValues:data];
}

- (NSDictionary*)topValuesFromLoadedData {
    id data = [GraphsManager sharedGraphsManager].mixerData;
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self maxTempValuesFromMixerDailyValues:(NSArray*)data];
}

- (NSDictionary*)iconImageIndexesFromLoadedData {
    id data = [GraphsManager sharedGraphsManager].mixerData;
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self conditionValuesFromMixerDailyValues:(NSArray*)data];
}

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [dateFormatter stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        values[day] = @(mixerDailyValue.maxTemp);
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
