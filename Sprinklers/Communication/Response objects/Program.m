//
//  Program.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Program.h"
#import "Additions.h"
#import "ProgramWateringTimes.h"

@implementation Program

+ (Program *)createFromJson:(NSDictionary *)jsonObj {

    if (jsonObj) {
        
        Program *program = [[Program alloc] init];
        program.active = [jsonObj nullProofedIntValueForKey:@"active"];
        program.csOn = [jsonObj nullProofedIntValueForKey:@"cs_on"];
        program.cycles = [jsonObj nullProofedIntValueForKey:@"cycles"];
        program.delay = [jsonObj nullProofedIntValueForKey:@"delay"];
        program.delayOn = [jsonObj nullProofedIntValueForKey:@"delay_on"];
        program.frequency = [jsonObj nullProofedIntValueForKey:@"frequency"];
        program.programId = [jsonObj nullProofedIntValueForKey:@"id"];
        program.ignoreWeatherData = [jsonObj nullProofedIntValueForKey:@"ignoreWeatherData"];
        program.name = [jsonObj nullProofedStringValueForKey:@"name"];
        program.parameter = [jsonObj nullProofedIntValueForKey:@"parameter"];
        program.soak = [jsonObj nullProofedIntValueForKey:@"soak"];
        program.timeFormat = [jsonObj nullProofedIntValueForKey:@"time_format"];
        
        //Check API version here for different date formats
        //This one is for API3
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        if (program.timeFormat == 0) {
            df.dateFormat = @"yyyy/M/dd h/m";
        }
        if (program.timeFormat == 1) {
            df.dateFormat = @"yyyy/M/dd h/m aaa";
        }
        program.startTime = [df dateFromString:[jsonObj nullProofedStringValueForKey:@"startTime"]];
        
        program.state = [jsonObj nullProofedStringValueForKey:@"state"];
        
        NSArray *times = [jsonObj valueForKey:@"wateringTimes"];
        if (times && [times isKindOfClass:[NSArray class]]) {
            program.wateringTimes = [NSMutableArray array];
            for (id obj in times) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    ProgramWateringTimes *wt = [[ProgramWateringTimes alloc] init];
                    wt.wtId = [obj nullProofedIntValueForKey:@"id"];
                    wt.minutes = [obj nullProofedIntValueForKey:@"minutes"];
                    wt.name = [obj nullProofedStringValueForKey:@"name"];                    
                    [program.wateringTimes addObject:wt];
                }
            }
        }
        
        return program;
    }

    return nil;
    
}

@end
