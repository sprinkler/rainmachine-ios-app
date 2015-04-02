//
//  DailyStatsDetail.m
//  Sprinklers
//
//  Created by Istvan Sipos on 02/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DailyStatsDetail.h"
#import "DailyStatsDetailProgram.h"
#import "DailyStatsDetailZone.h"
#import "Additions.h"

@implementation DailyStatsDetail

+ (DailyStatsDetail*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        DailyStatsDetail *dailyStatsDetail = [DailyStatsDetail new];
        
        dailyStatsDetail.day = [jsonObj nullProofedStringValueForKey:@"day"];
        dailyStatsDetail.dayTimestamp = [jsonObj nullProofedDoubleValueForKey:@"dayTimestamp"];
        dailyStatsDetail.mint = [jsonObj nullProofedDoubleValueForKey:@"mint"];
        dailyStatsDetail.maxt = [jsonObj nullProofedDoubleValueForKey:@"maxt"];
        dailyStatsDetail.icon = [jsonObj nullProofedIntValueForKey:@"icon"];
        
        NSMutableArray *programs = [NSMutableArray new];
        for (NSDictionary *programJson in [jsonObj objectForKey:@"programs"]) {
            [programs addObject:[DailyStatsDetailProgram createFromJson:programJson]];
        }
        dailyStatsDetail.programs = programs;
        
        NSMutableArray *simulatedPrograms = [NSMutableArray new];
        for (NSDictionary *programJson in [jsonObj objectForKey:@"simulatedPrograms"]) {
            [programs addObject:[DailyStatsDetailProgram createFromJson:programJson]];
        }
        dailyStatsDetail.simulatedPrograms = simulatedPrograms;
        
        double programsPercentageAverage = 0.0;
        for (DailyStatsDetailProgram *program in dailyStatsDetail.programs) {
            programsPercentageAverage += program.percentageAverage;
        }
        dailyStatsDetail.programsPercentageAverage = programsPercentageAverage / dailyStatsDetail.programs.count;
        
        double simulatedProgramsPercentageAverage = 0.0;
        for (DailyStatsDetailProgram *simulatedProgram in dailyStatsDetail.simulatedPrograms) {
            simulatedProgramsPercentageAverage += simulatedProgram.percentageAverage;
        }
        dailyStatsDetail.simulatedProgramsPercentageAverage = simulatedProgramsPercentageAverage / dailyStatsDetail.simulatedPrograms.count;
        
        return dailyStatsDetail;
    }
    return nil;
}

- (DailyStatsDetailProgram*)dailyStatsDetailProgramForProgramId:(int)programId {
    for (DailyStatsDetailProgram *program in self.programs) {
        if (program.programId == programId) return program;
    }
    return nil;
}

- (DailyStatsDetailProgram*)dailyStatsDetailSimulatedProgramForProgramId:(int)programId {
    for (DailyStatsDetailProgram *simulatedProgram in self.simulatedPrograms) {
        if (simulatedProgram.programId == programId) return simulatedProgram;
    }
    return nil;
}

@end
