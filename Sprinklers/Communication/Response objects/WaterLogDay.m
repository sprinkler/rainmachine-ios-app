//
//  WaterLogDay.m
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WaterLogDay.h"
#import "WaterLogProgram.h"
#import "Additions.h"

@implementation WaterLogDay

+ (WaterLogDay*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        WaterLogDay *waterLogDay = [WaterLogDay new];
        
        waterLogDay.date = [jsonObj nullProofedStringValueForKey:@"date"];
        waterLogDay.dateTimestamp = [jsonObj nullProofedDoubleValueForKey:@"dateTimestamp"];
        
        NSMutableArray *programs = [NSMutableArray new];
        for (NSDictionary *programJson in [jsonObj objectForKey:@"programs"]) {
            [programs addObject:[WaterLogProgram createFromJson:programJson]];
        }
        
        waterLogDay.programs = programs;
        
        NSMutableArray *simulatedPrograms = [NSMutableArray new];
        for (NSDictionary *programJson in [jsonObj objectForKey:@"simulatedPrograms"]) {
            [simulatedPrograms addObject:[WaterLogProgram createFromJson:programJson]];
        }
        
        waterLogDay.simulatedPrograms = simulatedPrograms;
        
        int realDurationSum = 0;
        int userDurationSum = 0;
        
        for (WaterLogProgram *program in waterLogDay.programs) {
            realDurationSum += program.realDurationSum;
            userDurationSum += program.userDurationSum;
        }
        
        waterLogDay.realDurationSum = realDurationSum;
        waterLogDay.userDurationSum = userDurationSum;
        
        int simulatedRealDurationSum = 0;
        int simulatedUserDurationSum = 0;
        
        for (WaterLogProgram *program in waterLogDay.simulatedPrograms) {
            simulatedRealDurationSum += program.realDurationSum;
            simulatedUserDurationSum += program.userDurationSum;
        }
        
        waterLogDay.simulatedRealDurationSum = simulatedRealDurationSum;
        waterLogDay.simulatedUserDurationSum = simulatedUserDurationSum;
        
        return waterLogDay;
    }
    return nil;
}

- (double)durationPercentage {
    if (self.userDurationSum == 0) return 0.0;
    return (double)self.realDurationSum / (double)self.userDurationSum;
}

- (double)simulatedDurationPercentage {
    if (self.simulatedUserDurationSum == 0) return 0.0;
    return (double)self.simulatedRealDurationSum / (double)self.simulatedUserDurationSum;
}

- (WaterLogProgram*)waterLogProgramForProgramId:(int)programId {
    for (WaterLogProgram *program in self.programs) {
        if (program.programId == programId) return program;
    }
    return nil;
}

- (WaterLogProgram*)simulatedWaterLogProgramForProgramId:(int)programId {
    for (WaterLogProgram *program in self.simulatedPrograms) {
        if (program.programId == programId) return program;
    }
    return nil;
}

- (NSDictionary*)programIDs {
    NSMutableDictionary *programIDs = [NSMutableDictionary new];
    for (WaterLogProgram *program in self.programs) {
        [programIDs setObject:@(TRUE) forKey:@(program.programId)];
    }
    return programIDs;
}

@end
