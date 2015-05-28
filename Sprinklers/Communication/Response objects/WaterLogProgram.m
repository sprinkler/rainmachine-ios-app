//
//  WaterLogProgram.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WaterLogProgram.h"
#import "WaterLogZone.h"
#import "Additions.h"

@implementation WaterLogProgram

+ (WaterLogProgram*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        WaterLogProgram *waterLogProgram = [WaterLogProgram new];
        
        waterLogProgram.programId = [jsonObj nullProofedIntValueForKey:@"id"];
        
        NSMutableArray *zones = [NSMutableArray new];
        for (NSDictionary *zoneJson in [jsonObj objectForKey:@"zones"]) {
            [zones addObject:[WaterLogZone createFromJson:zoneJson]];
        }
        
        waterLogProgram.zones = zones;
        
        int realDurationSum = 0;
        int userDurationSum = 0;
        
        for (WaterLogZone *zone in waterLogProgram.zones) {
            realDurationSum += zone.realDurationSum;
            userDurationSum += zone.userDurationSum;
        }
        
        waterLogProgram.realDurationSum = realDurationSum;
        waterLogProgram.userDurationSum = userDurationSum;
        
        return waterLogProgram;
    }
    return nil;
}

- (double)durationPercentage {
    if (self.userDurationSum == 0) return 0.0;
    return (double)self.realDurationSum / (double)self.userDurationSum;
}

@end
