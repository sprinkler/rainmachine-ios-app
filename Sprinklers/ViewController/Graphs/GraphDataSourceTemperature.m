//
//  GraphDataSourceTemperature.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceTemperature.h"
#import "GraphDataFormatterTemperature.h"
#import "GraphsManager.h"
#import "ServerProxy.h"
#import "MixerDailyValue.h"
#import "WeatherData.h"
#import "WeatherData4.h"
#import "Additions.h"
#import "Utils.h"

#pragma mark -

@interface GraphDataSourceTemperature ()

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
- (NSDictionary*)maxTempValuesFromWeatherData3Values:(NSArray*)weatherDataValues;
    
@end

#pragma mark -

@implementation GraphDataSourceTemperature

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"mixerData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"weatherData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"mixerData"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"weatherData"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self reloadGraphDataSource];
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatterTemperature class];
}

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    if ([ServerProxy usesAPI4]) {
        id data = [GraphsManager sharedGraphsManager].mixerData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self maxTempValuesFromMixerDailyValues:(NSArray*)data];
    }
    else if ([ServerProxy usesAPI3]) {
        id data = [GraphsManager sharedGraphsManager].weatherData;
        if (![data isKindOfClass:[NSArray class]]) return nil;
        return [self maxTempValuesFromWeatherData3Values:(NSArray*)data];
    }
    return nil;
}

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableArray *values = [NSMutableArray new];
    
    if ([ServerProxy usesAPI4]) {
        NSString *units = [Utils sprinklerTemperatureUnits];
        BOOL isFahrenheit = [units isEqualToString:@"F"];
        
        for (MixerDailyValue *mixerDailyValue in [GraphsManager sharedGraphsManager].mixerData) {
            [values addObject:@{@"date" : mixerDailyValue.day,
                                @"maxt" : @(isFahrenheit ? mixerDailyValue.maxTemp * 1.8 + 32 : mixerDailyValue.maxTemp),
                                @"mint" : @(isFahrenheit ? mixerDailyValue.minTemp * 1.8 + 32 : mixerDailyValue.minTemp)}];
        }
    }
    else if ([ServerProxy usesAPI3]) {
        for (WeatherData *weatherDataValue in [GraphsManager sharedGraphsManager].weatherData) {
            [values addObject:@{@"date" : [[NSDate date] dateByAddingDays:weatherDataValue.id.intValue],
                                @"maxt" : weatherDataValue.maxt,
                                @"mint" : weatherDataValue.mint}];
        }
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

- (NSDictionary*)maxTempValuesFromWeatherData3Values:(NSArray*)weatherDataValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    for (WeatherData *weatherDataValue in weatherDataValues) {
        NSString *day = [dateFormatter stringFromDate:[[NSDate date] dateByAddingDays:weatherDataValue.id.intValue]];
        if (!day.length) continue;
        
        if (weatherDataValue.maxt) values[day] = weatherDataValue.maxt;
    }
    
    return values;
}

@end
