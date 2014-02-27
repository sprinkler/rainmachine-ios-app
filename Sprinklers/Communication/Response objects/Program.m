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
#import "Utils.h"

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

        // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
        if (program.timeFormat == 0) {
            df.dateFormat = @"yyyy/MM/dd H:mm"; // H means hours between [0-23]
        }
        if (program.timeFormat == 1) {
            df.dateFormat = @"yyyy/MM/dd K:mm a"; // K means hours between [0-11]
        }
        
        program.startTime = [df dateFromString:[jsonObj nullProofedStringValueForKey:@"startTime"]];
        
        program.state = [jsonObj nullProofedStringValueForKey:@"state"];
        program.weekdays = [jsonObj nullProofedStringValueForKey:@"weekdays"];
        
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

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];

    [dic setObject:[NSNumber numberWithInt:_active] forKey:@"active"];
    [dic setObject:[NSNumber numberWithInt:_csOn] forKey:@"cs_on"];
    [dic setObject:[NSNumber numberWithInt:_cycles] forKey:@"cycles"];
    [dic setObject:[NSNumber numberWithInt:_delay] forKey:@"delay"];
    [dic setObject:[NSNumber numberWithInt:_delayOn] forKey:@"delay_on"];
    [dic setObject:[NSNumber numberWithInt:_frequency] forKey:@"frequency"];
    [dic setObject:[NSNumber numberWithInt:_ignoreWeatherData] forKey:@"ignoreWeatherData"];

    if (_name) {
        [dic setObject:_name forKey:@"name"];
    } else {
        [dic setObject:@"" forKey:@"name"];
    }
    
    [dic setObject:[NSNumber numberWithInt:_programId] forKey:@"id"];
    [dic setObject:[NSNumber numberWithInt:_soak] forKey:@"soak"];

    [dic setObject:[Utils formattedTime:_startTime forTimeFormat:_timeFormat] forKey:@"programStartTime"];
//    [dic setObject:[NSNumber numberWithDouble:[_startTime timeIntervalSince1970]] forKey:@"startTime"];
    
    if (_state) {
        [dic setObject:_state forKey:@"state"];
    }
    
    [dic setObject:[NSNumber numberWithInt:_timeFormat] forKey:@"timeFormat"];
    [dic setObject:_weekdays forKey:@"weekdays"];
    
    NSMutableArray *wateringTimesArray = [NSMutableArray array];
    for (ProgramWateringTimes *obj in _wateringTimes) {
        [wateringTimesArray addObject:[obj toDictionary]];
    }
    [dic setObject:wateringTimesArray forKey:@"wateringTimes"];
    
    return dic;
}

+ (Program *)program
{
    Program *program = [[Program alloc] init];

    program.programId = -1;
    program.weekdays = @"D";
    program.timeFormat = 0;
    program.active = YES;
    
    // Start time
    program.startTime = [NSDate date];
//    NSCalendar* cal = [NSCalendar currentCalendar];
//    NSDateComponents* dateComp = [cal components:(
//                                                  NSDayCalendarUnit |
//                                                  NSMonthCalendarUnit |
//                                                  NSYearCalendarUnit
//                                                  )
//                                        fromDate:program.startTime];
//    
//    dateComp.hour = 0;
//    dateComp.minute = 0;
//    
//    program.startTime = [cal dateFromComponents:dateComp];
    
    // Watering times
    
    program.wateringTimes = [NSMutableArray array];
    
    for (int i = 0; i < 12; i++) {
        ProgramWateringTimes *wt = [[ProgramWateringTimes alloc] init];
        wt.wtId = i + 1;
        [program.wateringTimes addObject:wt];
    }
    
    return program;
}

@end
