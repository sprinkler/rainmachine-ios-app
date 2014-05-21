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
        NSDateFormatter *df = [NSDate getDateFormaterFixedFormatParsing];

        // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
        if (program.timeFormat == 0) {
            df.dateFormat = @"yyyy/M/d H:m"; // H means hours between [0-23]
        }
        if (program.timeFormat == 1) {
            df.dateFormat = @"yyyy/M/d K:m a"; // K means hours between [0-11]
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

- (void)setWeekdays:(NSString *)weekdays
{
    _weekdays = weekdays;

    // _frequency is based on _weekdays, so just set its value here in order to eliminate the possibility of inconsistencies (#112 related)
    // The reason _frequency is set based on _weekdays and not the other way around, is because until now all calculations in the app used exclusively _weekdays
    if ([_weekdays isEqualToString:@"D"]) {
        self.frequency = ProgramFrequency_Daily;
    }
    else if ([_weekdays isEqualToString:@"ODD"]) {
        self.frequency = ProgramFrequency_OddDays;
    }
    else if ([_weekdays isEqualToString:@"EVD"]) {
        self.frequency = ProgramFrequency_EvenDays;
    }
    else if ([_weekdays containsString:@"INT"]) {
        self.frequency = ProgramFrequency_INT;
    }
    else if ([_weekdays containsString:@","]) {
        self.frequency = ProgramFrequency_Weekdays;
    }
    else {
        // Default value
        self.frequency = ProgramFrequency_Daily;
    }
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
    
    [dic setObject:[NSNumber numberWithInt:_timeFormat] forKey:@"time_format"];
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
    program.name = @"New Program";
    program.weekdays = @"D";
    program.timeFormat = 0;
    program.active = YES;
    program.ignoreWeatherData = NO;
    program.cycles = 2;
    program.soak = 30;
    program.delay = 0;
    
    // Start time
    program.startTime = [NSDate date];
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [cal components:(
                                                  NSDayCalendarUnit |
                                                  NSMonthCalendarUnit |
                                                  NSYearCalendarUnit
                                                  )
                                        fromDate:program.startTime];
    
    dateComp.hour = 6;
    dateComp.minute = 0;
    
    program.startTime = [cal dateFromComponents:dateComp];
    
    // Watering times
    
    program.wateringTimes = [NSMutableArray array];
    
    for (int i = 0; i < 12; i++) {
        ProgramWateringTimes *wt = [[ProgramWateringTimes alloc] init];
        wt.wtId = i + 1;
        [program.wateringTimes addObject:wt];
    }
    
    return program;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    Program *program = [(Program *)[[self class] allocWithZone:zone] init];
    
    program.active = self.active;
    program.csOn = self.csOn;
    program.cycles = self.cycles;
    program.delay = self.delay;
    program.delayOn = self.delayOn;
    program.frequency = self.frequency;
    program.ignoreWeatherData = self.ignoreWeatherData;
    program.name = [self.name copy];
    program.parameter = self.parameter;
    program.programId = self.programId;
    program.soak = self.soak;
    program.startTime = [self.startTime copy];
    program.state = [self.state copy];
    program.timeFormat = self.timeFormat;
    program.weekdays = [self.weekdays copy];
    program.wateringTimes = [NSMutableArray array];
    for (ProgramWateringTimes *wt in self.wateringTimes) {
        [program.wateringTimes addObject:[wt copy]];
    }
    
    return program;
}

- (BOOL)isEqualToProgram:(Program*)program
{
    BOOL isEqual = YES;

    isEqual &= (program.active == self.active);
    isEqual &= (program.csOn == self.csOn);
    isEqual &= (program.cycles == self.cycles);
    isEqual &= (program.delay == self.delay);
    isEqual &= (program.delayOn == self.delayOn);
    isEqual &= (program.frequency == self.frequency);
    isEqual &= (program.ignoreWeatherData == self.ignoreWeatherData);
    isEqual &= ([program.name isEqualToString:self.name]);
    isEqual &= (program.parameter == self.parameter);
    isEqual &= (program.programId == self.programId);
    isEqual &= (program.soak == self.soak);
    isEqual &= ([program.startTime isEqualToDate:self.startTime]);
    isEqual &= ([program.state isEqualToString:self.state]);
    isEqual &= (program.timeFormat == self.timeFormat);
    isEqual &= ([program.weekdays isEqualToString:self.weekdays]);
    
    if (self.wateringTimes.count != program.wateringTimes.count) {
        isEqual = NO;
    } else {
        for (int i = 0; i < self.wateringTimes.count; i++) {
            ProgramWateringTimes *selfWateringTime = self.wateringTimes[i];
            ProgramWateringTimes *otherWateringTime = program.wateringTimes[i];
            isEqual &= ([otherWateringTime isEqualToProgramWateringTime:selfWateringTime]);
        }
    }
    
    return isEqual;
}

@end
