//
//  WaterLogZoneCycle.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WaterLogZoneCycle.h"
#import "Additions.h"

@implementation WaterLogZoneCycle

+ (WaterLogZoneCycle*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        WaterLogZoneCycle *waterLogZoneCycle = [WaterLogZoneCycle new];
        
        waterLogZoneCycle.cycleId = [jsonObj nullProofedIntValueForKey:@"id"];
        waterLogZoneCycle.startTime = [jsonObj nullProofedStringValueForKey:@"startTime"];
        waterLogZoneCycle.startTimestamp = [jsonObj nullProofedDoubleValueForKey:@"startTimestamp"];
        waterLogZoneCycle.userDuration = [jsonObj nullProofedIntValueForKey:@"userDuration"];
        waterLogZoneCycle.machineDuration = [jsonObj nullProofedIntValueForKey:@"machineDuration"];
        waterLogZoneCycle.realDuration = [jsonObj nullProofedIntValueForKey:@"realDuration"];
        
        return waterLogZoneCycle;
    }
    return nil;
}

@end
