//
//  WaterLogDay.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WaterLogProgram;

@interface WaterLogDay : NSObject

@property (nonatomic, strong) NSString *date;
@property (nonatomic, assign) double dateTimestamp;
@property (nonatomic, strong) NSArray *programs;
@property (nonatomic, strong) NSArray *simulatedPrograms;

+ (WaterLogDay*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) int realDurationSum;
@property (nonatomic, assign) int userDurationSum;
@property (nonatomic, assign) int simulatedRealDurationSum;
@property (nonatomic, assign) int simulatedUserDurationSum;
@property (nonatomic, readonly) double durationPercentage;
@property (nonatomic, readonly) double simulatedDurationPercentage;

- (WaterLogProgram*)waterLogProgramForProgramId:(int)programId;
- (WaterLogProgram*)simulatedWaterLogProgramForProgramId:(int)programId;

@property (nonatomic, readonly) NSDictionary *programIDs;

@end
