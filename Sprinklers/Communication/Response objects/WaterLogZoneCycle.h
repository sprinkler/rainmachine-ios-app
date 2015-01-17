//
//  WaterLogZoneCycle.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterLogZoneCycle : NSObject

@property (nonatomic, assign) int cycleId;
@property (nonatomic, strong) NSString *startTime;
@property (nonatomic, assign) double startTimestamp;
@property (nonatomic, assign) int userDuration;
@property (nonatomic, assign) int machineDuration;
@property (nonatomic, assign) int realDuration;

+ (WaterLogZoneCycle*)createFromJson:(NSDictionary*)jsonObj;

@end
