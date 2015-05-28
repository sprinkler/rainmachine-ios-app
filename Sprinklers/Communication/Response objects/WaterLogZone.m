//
//  WaterLogZone.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WaterLogZone.h"
#import "WaterLogZoneCycle.h"
#import "Additions.h"

@implementation WaterLogZone

+ (WaterLogZone*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        WaterLogZone *waterLogZone = [WaterLogZone new];
        
        waterLogZone.zoneId = [jsonObj nullProofedIntValueForKey:@"uid"];
        waterLogZone.flag = [jsonObj nullProofedIntValueForKey:@"flag"];
        
        NSMutableArray *cycles = [NSMutableArray new];
        for (NSDictionary *cycleJson in [jsonObj objectForKey:@"cycles"]) {
            [cycles addObject:[WaterLogZoneCycle createFromJson:cycleJson]];
        }
        
        waterLogZone.cycles = cycles;
        
        int realDurationSum = 0;
        int userDurationSum = 0;
        
        for (WaterLogZoneCycle *cycle in waterLogZone.cycles) {
            realDurationSum += cycle.realDuration;
            userDurationSum += cycle.userDuration;
        }
        
        waterLogZone.realDurationSum = realDurationSum;
        waterLogZone.userDurationSum = userDurationSum;
        
        return waterLogZone;
    }
    return nil;
}

@end
