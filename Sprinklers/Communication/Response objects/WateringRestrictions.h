//
//  WateringRestrictions.h
//  Sprinklers
//
//  Created by Adrian Manolache on 16/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WateringRestrictions : NSObject
        
@property (nonatomic, assign) BOOL hotDaysExtraWatering;
@property (nonatomic, assign) BOOL freezeProtectEnabled;
@property (nonatomic, assign) double freezeProtectTemperature;
@property (nonatomic, strong) NSString *noWaterInMonths;
@property (nonatomic, strong) NSString *noWaterInWeekDays;
@property (nonatomic, assign) int rainDelayStartTime;
@property (nonatomic, assign) int rainDelayDuration;

+ (WateringRestrictions*)createFromJson:(NSDictionary*)jsonObj;

@end