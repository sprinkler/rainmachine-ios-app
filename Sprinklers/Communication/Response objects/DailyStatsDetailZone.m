//
//  DailyStatsDetailZone.m
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DailyStatsDetailZone.h"
#import "Additions.h"

@implementation DailyStatsDetailZone

+ (DailyStatsDetailZone*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        DailyStatsDetailZone *dailyStatsZone = [DailyStatsDetailZone new];
        
        dailyStatsZone.zoneId = [jsonObj nullProofedIntValueForKey:@"id"];
        dailyStatsZone.scheduledWateringTime = [jsonObj nullProofedDoubleValueForKey:@"scheduledWateringTime"];
        dailyStatsZone.computedWateringTime = [jsonObj nullProofedDoubleValueForKey:@"computedWateringTime"];
        dailyStatsZone.availableWater = [jsonObj nullProofedDoubleValueForKey:@"availableWater"];
        dailyStatsZone.coefficient = [jsonObj nullProofedDoubleValueForKey:@"coefficient"];
        dailyStatsZone.percentage = [jsonObj nullProofedDoubleValueForKey:@"percentage"];
        
        return dailyStatsZone;
    }
    return nil;
}

@end
