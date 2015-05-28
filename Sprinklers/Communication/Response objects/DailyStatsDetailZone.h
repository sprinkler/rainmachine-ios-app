//
//  DailyStatsDetailZone.h
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DailyStatsDetailZone : NSObject

@property (nonatomic, assign) int zoneId;
@property (nonatomic, assign) double scheduledWateringTime;
@property (nonatomic, assign) double computedWateringTime;
@property (nonatomic, assign) double availableWater;
@property (nonatomic, assign) double coefficient;
@property (nonatomic, assign) double percentage;

+ (DailyStatsDetailZone*)createFromJson:(NSDictionary*)jsonObj;

@end
