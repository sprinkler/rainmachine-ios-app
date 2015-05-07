//
//  DailyStatsDetail.h
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DailyStatsDetailProgram;

@interface DailyStatsDetail : NSObject

@property (nonatomic, strong) NSString *day;
@property (nonatomic, assign) double dayTimestamp;
@property (nonatomic, strong) NSNumber *mint;
@property (nonatomic, strong) NSNumber *maxt;
@property (nonatomic, strong) NSNumber *icon;
@property (nonatomic, strong) NSArray *programs;
@property (nonatomic, strong) NSArray *simulatedPrograms;

+ (DailyStatsDetail*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) double programsPercentageAverage;
@property (nonatomic, assign) double simulatedProgramsPercentageAverage;

- (DailyStatsDetailProgram*)dailyStatsDetailProgramForProgramId:(int)programId;
- (DailyStatsDetailProgram*)dailyStatsDetailSimulatedProgramForProgramId:(int)programId;

@end
