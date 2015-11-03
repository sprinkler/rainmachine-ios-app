//
//  DailyStatsDetailProgram.h
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DailyStatsDetailProgram : NSObject

@property (nonatomic, assign) int programId;
@property (nonatomic, strong) NSArray *zones;

+ (DailyStatsDetailProgram*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) double percentageAverage;

@end
