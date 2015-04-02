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
#import "DailyStatsDetail.h"
#import "DailyStatsDetailProgram.h"
#import "Program.h"
#import "Program4.h"
#import "Additions.h"

#pragma mark -

@interface GraphDataSourceProgramRunTime ()

- (NSDictionary*)percentageValuesFromWateringLogValues:(NSArray*)wateringLogValues dailyStatsValues:(NSArray*)dailyStatsDetailsValues;

@end

#pragma mark -

@implementation GraphDataSourceProgramRunTime

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"wateringLogDetailsData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"dailyStatsDetails" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"wateringLogDetailsData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"dailyStatsDetails"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self reloadGraphDataSource];
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatterProgramRuntime class];
}

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    id dataPast = [GraphsManager sharedGraphsManager].wateringLogDetailsData;
    id dataFuture = [GraphsManager sharedGraphsManager].dailyStatsDetails;
    if (![dataPast isKindOfClass:[NSArray class]]) return nil;
    if (![dataFuture isKindOfClass:[NSArray class]]) return nil;
    return [self percentageValuesFromWateringLogValues:dataPast dailyStatsValues:dataFuture];
}

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableDictionary *zoneNamesDictionary = [NSMutableDictionary new];
    for (Zone *zone in [GraphsManager sharedGraphsManager].zones) {
        [zoneNamesDictionary setObject:zone.name forKey:@(zone.zoneId)];
    }
    
    NSMutableArray *values = [NSMutableArray new];
    NSMutableSet *futureDaysSet = [NSMutableSet set];
    
    for (DailyStatsDetail *dailyStatsDetail in [GraphsManager sharedGraphsManager].dailyStatsDetails) {
        DailyStatsDetailProgram * dailyStatsDetailProgram = [dailyStatsDetail dailyStatsDetailProgramForProgramId:self.program.programId];
        if (!dailyStatsDetailProgram) continue;
        
        [values addObject:@{@"date" : dailyStatsDetail.day,
                            @"percentage" : @(dailyStatsDetailProgram.percentageAverage / 100.0)}];
        [futureDaysSet addObject:dailyStatsDetail.day];
    }
    
    for (WaterLogDay *waterLogDay in [GraphsManager sharedGraphsManager].wateringLogDetailsData) {
        WaterLogProgram *waterLogProgram = [waterLogDay waterLogProgramForProgramId:self.program.programId];
        if (!waterLogProgram) continue;
        
        for (WaterLogZone *zone in waterLogProgram.zones) {
            zone.zoneName = [zoneNamesDictionary objectForKey:@(zone.zoneId)];
        }
        
        [values addObject:@{@"date" : waterLogDay.date,
                            @"percentage" : @(waterLogProgram.durationPercentage)}];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [values sortUsingDescriptors:@[sortDescriptor]];
    
    return values;
}

- (NSDictionary*)percentageValuesFromWateringLogValues:(NSArray*)wateringLogValues dailyStatsValues:(NSArray*)dailyStatsDetailsValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
        
    for (WaterLogDay *waterLogDay in wateringLogValues) {
        NSString *date = waterLogDay.date;
        if (!date.length) continue;
        
        WaterLogProgram *waterLogProgram = [waterLogDay waterLogProgramForProgramId:self.program.programId];
        values[date] = @(waterLogProgram.durationPercentage * 100.0);
    }
    
    for (DailyStatsDetail *dailyStatsDetail in dailyStatsDetailsValues) {
        NSString *day = dailyStatsDetail.day;
        if (!day.length) continue;
        
        DailyStatsDetailProgram * dailyStatsDetailProgram = [dailyStatsDetail dailyStatsDetailProgramForProgramId:self.program.programId];
        values[day] = @(dailyStatsDetailProgram.percentageAverage);
    }
    
    return values;
}

@end
