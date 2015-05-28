//
//  WateringRestrictions.m
//  Sprinklers
//
//  Created by Adrian Manolache on 16/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "WateringRestrictions.h"
#import "Additions.h"

@implementation WateringRestrictions

+ (WateringRestrictions*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        WateringRestrictions *wateringRestrictions = [[WateringRestrictions alloc] init];
        wateringRestrictions.hotDaysExtraWatering = [jsonObj nullProofedBoolValueForKey:@"hotDaysExtraWatering"];
        wateringRestrictions.freezeProtectEnabled = [jsonObj nullProofedBoolValueForKey:@"freezeProtectEnabled"];
        wateringRestrictions.freezeProtectTemperature = [jsonObj nullProofedDoubleValueForKey:@"freezeProtectTemp"];
        wateringRestrictions.noWaterInMonths = [jsonObj nullProofedStringValueForKey:@"noWaterInMonths"];
        wateringRestrictions.noWaterInWeekDays = [jsonObj nullProofedStringValueForKey:@"noWaterInWeekDays"];
        wateringRestrictions.rainDelayStartTime = [jsonObj nullProofedBoolValueForKey:@"rainDelayStartTime"];
        wateringRestrictions.rainDelayDuration = [jsonObj nullProofedBoolValueForKey:@"rainDelayDuration"];
        return wateringRestrictions;
    }
    return nil;
}

@end
