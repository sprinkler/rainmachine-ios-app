//
//  DailyStatsDetailProgram.m
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DailyStatsDetailProgram.h"
#import "DailyStatsDetailZone.h"
#import "Additions.h"

@implementation DailyStatsDetailProgram

+ (DailyStatsDetailProgram*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        DailyStatsDetailProgram *dailyStatsDetailProgram = [DailyStatsDetailProgram new];
        
        dailyStatsDetailProgram.programId = [jsonObj nullProofedIntValueForKey:@"id"];
        
        NSMutableArray *zones = [NSMutableArray new];
        for (NSDictionary *zoneJson in [jsonObj objectForKey:@"zones"]) {
            [zones addObject:[DailyStatsDetailZone createFromJson:zoneJson]];
        }
        
        dailyStatsDetailProgram.zones = zones;
        
        double percentageAverage = 0.0;
        for (DailyStatsDetailZone *zone in dailyStatsDetailProgram.zones) {
            percentageAverage += zone.percentage;
        }
        dailyStatsDetailProgram.percentageAverage = (dailyStatsDetailProgram.zones.count ? percentageAverage / dailyStatsDetailProgram.zones.count : 0.0);
        
        return dailyStatsDetailProgram;
    }
    return nil;
}

@end
