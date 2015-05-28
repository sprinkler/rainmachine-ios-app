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
        
        int realDurationSum = 0;
        int userDurationSum = 0;
        
        for (WaterLogProgram *program in waterLogDay.programs) {
            realDurationSum += program.realDurationSum;
            userDurationSum += program.userDurationSum;
        }
        
        waterLogDay.realDurationSum = realDurationSum;
        waterLogDay.userDurationSum = userDurationSum;
        
        return waterLogDay;
    }
    return nil;
}

- (double)durationPercentage {
    if (self.userDurationSum == 0) return 0.0;
    return (double)self.realDurationSum / (double)self.userDurationSum;
}

- (WaterLogProgram*)waterLogProgramForProgramId:(int)programId {
    for (WaterLogProgram *program in self.programs) {
        if (program.programId == programId) return program;
    }
    return nil;
}

@end
