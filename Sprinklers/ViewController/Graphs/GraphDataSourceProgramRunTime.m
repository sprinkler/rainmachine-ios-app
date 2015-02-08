//
//  GraphDataSourceProgramRunTime.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataSourceProgramRunTime.h"
#import "GraphDataFormatterProgramRuntime.h"
#import "GraphsManager.h"
#import "MixerDailyValue.h"
#import "WaterLogDay.h"
#import "WaterLogProgram.h"
#import "WaterLogZone.h"
#import "Program.h"
#import "Program4.h"

#pragma mark -

@interface GraphDataSourceProgramRunTime ()

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
- (NSDictionary*)conditionValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
- (NSDictionary*)percentageValuesFromWateringLogValues:(NSArray*)wateringLogValues;

@end

#pragma mark -

@implementation GraphDataSourceProgramRunTime

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"mixerData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"wateringLogDetailsData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"mixerData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"wateringLogDetailsData"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self reloadGraphDataSource];
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatterProgramRuntime class];
}

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    id data = [GraphsManager sharedGraphsManager].wateringLogDetailsData;
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self percentageValuesFromWateringLogValues:data];
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

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableDictionary *zoneNamesDictionary = [NSMutableDictionary new];
    for (Zone *zone in [GraphsManager sharedGraphsManager].zones) {
        [zoneNamesDictionary setObject:zone.name forKey:@(zone.zoneId)];
    }
    
    NSMutableArray *values = [NSMutableArray new];
    
    for (WaterLogDay *waterLogDay in [GraphsManager sharedGraphsManager].wateringLogDetailsData) {
        WaterLogProgram *waterLogProgram = [waterLogDay waterLogProgramForProgramId:self.program.programId];
        if (!waterLogProgram) continue;
        
        for (WaterLogZone *zone in waterLogProgram.zones) {
            zone.zoneName = [zoneNamesDictionary objectForKey:@(zone.zoneId)];
        }
        
        [values addObject:@{@"date" : waterLogDay.date,
                            @"userDuration" : @(waterLogProgram.userDurationSum),
                            @"realDuration" : @(waterLogProgram.realDurationSum),
                            @"zones" : waterLogProgram.zones}];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [values sortUsingDescriptors:@[sortDescriptor]];
    
    return values;
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

- (NSDictionary*)percentageValuesFromWateringLogValues:(NSArray*)wateringLogValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    for (WaterLogDay *waterLogDay in wateringLogValues) {
        WaterLogProgram *waterLogProgram = [waterLogDay waterLogProgramForProgramId:self.program.programId];
        
        NSString *date = waterLogDay.date;
        if (!date.length) continue;
        values[date] = @(waterLogProgram.durationPercentage * 100.0);
    }
    
    return values;
}

@end
