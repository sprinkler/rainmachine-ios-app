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
#import "DailyStatsDetail.h"
#import "WeatherData.h"
#import "Utils.h"
#import "Additions.h"

#pragma mark -

@interface GraphDataSourceWaterConsume ()

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues;
- (NSDictionary*)conditionValuesFromMixerDailyValues:(NSArray*)mixerDailyValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues;
- (NSDictionary*)percentageValuesFromWateringLogSimulatedValues:(NSArray*)wateringLogSimulatedValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues;
- (NSDictionary*)maxTempValuesFromWeatherData3Values:(NSArray*)weatherDataValues;
- (NSDictionary*)iconValuesFromWeatherData3Values:(NSArray*)weatherDataValues;
- (NSDictionary*)percentageValuesFromWeatherData3Values:(NSArray*)weatherDataValues;

@end

#pragma mark -

@implementation GraphDataSourceWaterConsume

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"mixerData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"wateringLogSimulatedDetailsData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"weatherData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"dailyStatsDetails" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"mixerData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"wateringLogSimulatedDetailsData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"weatherData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"dailyStatsDetails"];
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
        id dataPast = [GraphsManager sharedGraphsManager].wateringLogSimulatedDetailsData;
        id dataFuture = [GraphsManager sharedGraphsManager].dailyStatsDetails;
        if (![dataPast isKindOfClass:[NSArray class]]) return nil;
        if (![dataFuture isKindOfClass:[NSArray class]]) return nil;
        return [self percentageValuesFromWateringLogSimulatedValues:dataPast dailyStatsDetailsValues:dataFuture];
    }
    else if ([ServerProxy usesAPI3]) {
        id data = [GraphsManager sharedGraphsManager].weatherData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self percentageValuesFromWeatherData3Values:(NSArray*)data];
    }
    return nil;
}

- (NSDictionary*)topValuesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id dataPast = [GraphsManager sharedGraphsManager].mixerData;
        id dataFuture = [GraphsManager sharedGraphsManager].dailyStatsDetails;
        if (![dataPast isKindOfClass:[NSArray class]]) return nil;
        if (![dataFuture isKindOfClass:[NSArray class]]) return nil;
        return [self maxTempValuesFromMixerDailyValues:dataPast dailyStatsDetailsValues:dataFuture];
    }
    else if ([ServerProxy usesAPI3]) {
        id data = [GraphsManager sharedGraphsManager].weatherData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self maxTempValuesFromWeatherData3Values:(NSArray*)data];
    }
    return nil;
}

- (NSDictionary*)iconImageIndexesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id dataPast = [GraphsManager sharedGraphsManager].mixerData;
        id dataFuture = [GraphsManager sharedGraphsManager].dailyStatsDetails;
        if (![dataPast isKindOfClass:[NSArray class]]) return nil;
        if (![dataFuture isKindOfClass:[NSArray class]]) return nil;
        return [self conditionValuesFromMixerDailyValues:dataPast dailyStatsDetailsValues:dataFuture];
    }
    else if ([ServerProxy usesAPI3]) {
        id data = [GraphsManager sharedGraphsManager].weatherData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self iconValuesFromWeatherData3Values:(NSArray*)data];
    }
    return nil;
}

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableArray *values = [NSMutableArray new];
    
    if ([ServerProxy usesAPI4]) {
        NSMutableSet *futureDaysSet = [NSMutableSet set];
        
        for (DailyStatsDetail *dailyStatsDetail in [GraphsManager sharedGraphsManager].dailyStatsDetails) {
            [values addObject:@{@"date" : dailyStatsDetail.day,
                                @"percentage" : @(dailyStatsDetail.simulatedProgramsPercentageAverage / 100.0)}];
            [futureDaysSet addObject:dailyStatsDetail.day];
        }
        
        for (WaterLogDay *waterLogDay in [GraphsManager sharedGraphsManager].wateringLogSimulatedDetailsData) {
            if ([futureDaysSet containsObject:waterLogDay.date]) continue;
            [values addObject:@{@"date" : waterLogDay.date,
                                @"percentage" : @(waterLogDay.durationPercentage)}];
        }
        
    }
    else if ([ServerProxy usesAPI3]) {
        for (WeatherData *weatherDataValue in [GraphsManager sharedGraphsManager].weatherData) {
            [values addObject:@{@"date" : [[NSDate sharedDateFormatterAPI4] stringFromDate:[[NSDate date] dateByAddingDays:weatherDataValue.id.intValue]],
                                @"percentage" : weatherDataValue.percentage}];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [values sortUsingDescriptors:@[sortDescriptor]];
    
    return values;
}

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSString *units = [Utils sprinklerTemperatureUnits];
    BOOL isFahrenheit = [units isEqualToString:@"F"];
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        double maxTemp = mixerDailyValue.maxTemp;
        if (isFahrenheit) maxTemp = maxTemp * 1.8 + 32;
        
        values[day] = @(maxTemp);
    }
    
    for (DailyStatsDetail *dailyStatsDetail in dailyStatsDetailsValues) {
        NSString *day = dailyStatsDetail.day;
        if (!day.length) continue;
        
        double maxTemp = dailyStatsDetail.maxt;
        if (isFahrenheit) maxTemp = maxTemp * 1.8 + 32;
        
        values[day] = @(maxTemp);
    }
    
    return values;
}

- (NSDictionary*)conditionValuesFromMixerDailyValues:(NSArray*)mixerDailyValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        values[day] = @(mixerDailyValue.condition);
    }
    
    for (DailyStatsDetail *dailyStatsDetail in dailyStatsDetailsValues) {
        NSString *day = dailyStatsDetail.day;
        if (!day.length) continue;
        values[day] = @(dailyStatsDetail.icon);
    }
    
    return values;
}

- (NSDictionary*)percentageValuesFromWateringLogSimulatedValues:(NSArray*)wateringLogSimulatedValues dailyStatsDetailsValues:(NSArray*)dailyStatsDetailsValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (WaterLogDay *waterLogDay in wateringLogSimulatedValues) {
        NSString *date = waterLogDay.date;
        if (!date.length) continue;
        values[date] = @(waterLogDay.durationPercentage * 100.0);
    }
    
    for (DailyStatsDetail *dailyStatsDetail in dailyStatsDetailsValues) {
        NSString *day = dailyStatsDetail.day;
        if (!day.length) continue;
        values[day] = @(dailyStatsDetail.simulatedProgramsPercentageAverage);
    }
    
    return values;
}

- (NSDictionary*)maxTempValuesFromWeatherData3Values:(NSArray*)weatherDataValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (WeatherData *weatherDataValue in weatherDataValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:[[NSDate date] dateByAddingDays:weatherDataValue.id.intValue]];
        if (!day.length) continue;
        
        if (weatherDataValue.maxt) values[day] = weatherDataValue.maxt;
    }
    
    return values;
}

- (NSDictionary*)iconValuesFromWeatherData3Values:(NSArray*)weatherDataValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (WeatherData *weatherDataValue in weatherDataValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:[[NSDate date] dateByAddingDays:weatherDataValue.id.intValue]];
        if (!day.length) continue;
        
        values[day] = @([Utils codeFromWeatherImageName:weatherDataValue.icon]);
    }
    
    return values;
}

- (NSDictionary*)percentageValuesFromWeatherData3Values:(NSArray*)weatherDataValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (WeatherData *weatherDataValue in weatherDataValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:[[NSDate date] dateByAddingDays:weatherDataValue.id.intValue]];
        if (!day.length) continue;
        
        values[day] = @(weatherDataValue.percentage.doubleValue * 100.0);
    }
    
    return values;
}

@end
