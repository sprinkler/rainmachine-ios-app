//
//  GraphDataSourceTemperature.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceTemperature.h"
#import "ServerProxy.h"
#import "MixerDailyValue.h"
#import "Additions.h"

#pragma mark -

@interface GraphDataSourceTemperature ()

- (NSDictionary*)maxTempValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;
    
@end

#pragma mark -

@implementation GraphDataSourceTemperature

- (void)requestData {
    NSDate *startDate = [NSDate dateWithDaysBeforeNow:self.totalDays - self.futureDays];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:startDate];

    NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
    
    [self.serverProxy requestMixerDataFromDate:dateString daysCount:self.totalDays];
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self maxTempValuesFromMixerDailyValues:(NSArray*)data];
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

@end
