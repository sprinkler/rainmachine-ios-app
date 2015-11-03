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

+ (WaterLogDay*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) int realDurationSum;
@property (nonatomic, assign) int userDurationSum;
@property (nonatomic, readonly) double durationPercentage;

- (WaterLogProgram*)waterLogProgramForProgramId:(int)programId;

@end
