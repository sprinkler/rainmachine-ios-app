//
//  Program.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Program4.h"
#import "Additions.h"
#import "ProgramWateringTimes4.h"
#import "Utils.h"

@implementation Program4

+ (Program4 *)createFromJson:(NSDictionary *)jsonObj {

    if (jsonObj) {
        
        Program4 *program = [[Program4 alloc] init];
        program.programId = [jsonObj nullProofedIntValueForKey:@"uid"];
        program.name = [jsonObj nullProofedStringValueForKey:@"name"];
        program.active = [jsonObj nullProofedBoolValueForKey:@"active"];
        
        NSDateFormatter *df = [NSDate getDateFormaterFixedFormatParsing];
        // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
        df.dateFormat = @"H:m"; // H means hours between [0-23]
        program.startTime = [df dateFromString:[jsonObj nullProofedStringValueForKey:@"startTime"]];
        program.nextRun = [[NSDate sharedDateFormatterAPI4] dateFromString:[jsonObj nullProofedStringValueForKey:@"nextRun"]];
        
        program.cycles = [jsonObj nullProofedIntValueForKey:@"cycles"];
        program.soak = [jsonObj nullProofedIntValueForKey:@"soak"] / 60;
        program.csOn = [jsonObj nullProofedBoolValueForKey:@"cs_on"];
        program.delay = [jsonObj nullProofedIntValueForKey:@"delay"];
        program.delayOn = [jsonObj nullProofedBoolValueForKey:@"delay_on"];
        program.status = [jsonObj nullProofedIntValueForKey:@"status"];
        program.frequency = [Frequency4 createFromJson:[jsonObj objectForKey:@"frequency"]];
        program.coef = [jsonObj nullProofedIntValueForKey:@"coef"];
        program.ignoreWeatherData = [jsonObj nullProofedBoolValueForKey:@"ignoreInternetWeather"];
        program.futureField1 = [jsonObj nullProofedIntValueForKey:@"futureField1"];
        program.freq_modified = [jsonObj nullProofedIntValueForKey:@"freq_modified"];
        program.useWaterSense = [jsonObj nullProofedIntValueForKey:@"useWaterSense"];
        
        NSArray *times = [jsonObj valueForKey:@"wateringTimes"];
        if (times && [times isKindOfClass:[NSArray class]]) {
            program.wateringTimes = [NSMutableArray array];
            for (id obj in times) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    ProgramWateringTimes4 *wt = [[ProgramWateringTimes4 alloc] init];
                    wt.wtId = [obj nullProofedIntValueForKey:@"id"];
                    wt.duration = [obj nullProofedIntValueForKey:@"duration"];
                    wt.name = [obj nullProofedStringValueForKey:@"name"];                    
                    wt.active = [obj nullProofedBoolValueForKey:@"active"];
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
    // _frequency is based on _weekdays, so just set its value here in order to eliminate the possibility of inconsistencies (#112 related)
    // The reason _frequency is set based on _weekdays and not the other way around, is because until now all calculations in the app used exclusively _weekdays
    if ([weekdays isEqualToString:@"D"]) {
        self.frequency.type = API4_ProgramFrequencyType_Daily;
        self.frequency.param = @"0";
    }
    else if ([weekdays isEqualToString:@"ODD"]) {
        self.frequency.type = API4_ProgramFrequencyType_OddOrEvenDays;
        self.frequency.param = [NSString stringWithFormat:@"%d", API4_ProgramFrequencyParam_Odd];
    }
    else if ([weekdays isEqualToString:@"EVD"]) {
        self.frequency.type = API4_ProgramFrequencyType_OddOrEvenDays;
        self.frequency.param = [NSString stringWithFormat:@"%d", API4_ProgramFrequencyParam_Even];
    }
    else if ([weekdays containsString:@"INT"]) {
        int nrDays;
        sscanf([weekdays UTF8String], "INT %d", &nrDays);
        self.frequency.type = API4_ProgramFrequencyType_Nth;
        self.frequency.param = [NSString stringWithFormat:@"%d", nrDays];
    }
    else if ([weekdays containsString:@","]) {
        self.frequency.type = API4_ProgramFrequencyType_Weekdays;
        
        NSArray *weekdayComponents = [weekdays componentsSeparatedByString:@","];
        NSMutableString *tempWeekdays  = [NSMutableString string];
        for (int i = (int)(weekdayComponents.count - 1); i >= 0; i--) {
            [tempWeekdays appendString:weekdayComponents[i]];
        }
        
        self.frequency.param = [[@"00" stringByAppendingString:tempWeekdays] stringByAppendingString:@"0"];
    }
    else {
        // Default value
        self.frequency.type = ProgramFrequency_Daily;
        self.frequency.param = @"0";
    }
}

- (NSString*)weekdays
{
    switch (self.frequency.type) {
        case API4_ProgramFrequencyType_OddOrEvenDays:
            // @"0" == API4_ProgramFrequencyParam_Even
            return [self.frequency.param isEqualToString:@"0"] ? @"EVD" : @"ODD";
        case API4_ProgramFrequencyType_Nth: {
            NSString *w = [NSString stringWithFormat:@"INT %@", self.frequency.param];
            return w;
        }
        case API4_ProgramFrequencyType_Weekdays: {
            NSMutableString *api3Weekdays = [NSMutableString string];
            for (int i = 8; i >= 2; i--) {
                [api3Weekdays appendString:[self.frequency.param substringWithRange:NSMakeRange(i, 1)]];
                if (i != 2) {
                    [api3Weekdays appendString:@","];
                }
            }
            return api3Weekdays;
        }
        case API4_ProgramFrequencyType_Daily:
        default:
            return @"D";
    }
    
    return @"D";
}

- (NSString*)state
{
    return self.status == API4_ProgramStatus_Stopped ? @"stopped" : @"running";
}

- (void)setState:(NSString*)state
{
    if ([state isEqualToString:@"stopped"]) {
        self.status = API4_ProgramStatus_Stopped;
    } else {
        self.status = API4_ProgramStatus_Running;
    }
}

- (int)timeFormat
{
    return 0;
}

- (void)setTimeFormat:(int)tf
{
    // Do nothing
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];

    if (_name) {
        [dic setObject:_name forKey:@"name"];
    } else {
        [dic setObject:@"" forKey:@"name"];
    }
    
    [dic setObject:[NSNumber numberWithInt:_programId] forKey:@"uid"];
    [dic setObject:[NSNumber numberWithBool:_active] forKey:@"active"];
    [dic setObject:[NSNumber numberWithInt:_cycles] forKey:@"cycles"];
    [dic setObject:[NSNumber numberWithInt:_soak * 60] forKey:@"soak"];
    [dic setObject:[NSNumber numberWithBool:_csOn] forKey:@"cs_on"];
    [dic setObject:[NSNumber numberWithInt:_delay] forKey:@"delay"];
    [dic setObject:[NSNumber numberWithBool:_delayOn] forKey:@"delay_on"];
    [dic setObject:[NSNumber numberWithInt:_status] forKey:@"status"];
    [dic setObject:[_frequency toDictionary] forKey:@"frequency"];
    [dic setObject:[NSNumber numberWithBool:_ignoreWeatherData] forKey:@"ignoreInternetWeather"];
    [dic setObject:[NSNumber numberWithFloat:_coef] forKey:@"coef"];
    [dic setObject:[NSNumber numberWithFloat:_futureField1] forKey:@"futureField1"];
    [dic setObject:[NSNumber numberWithFloat:_freq_modified] forKey:@"freq_modified"];
    [dic setObject:[NSNumber numberWithFloat:_useWaterSense] forKey:@"useWaterSense"];

    if (self.frequency.type == API4_ProgramFrequencyType_Nth) {
        [dic setObject:[[NSDate sharedDateFormatterAPI4] stringFromDate:_nextRun] forKey:@"nextRun"];
    }
    
    // Force "programStartTime" to be encoded with H:m format
    [dic setObject:[Utils formattedTime:_startTime forTimeFormat:0] forKey:@"startTime"];
    // Send the nr. of seconds from epoch time (1970) in "startTime"
//    [dic setObject:[NSNumber numberWithDouble:[_startTime timeIntervalSince1970]] forKey:@"startTime"];
    
    NSMutableArray *wateringTimesArray = [NSMutableArray array];
    for (ProgramWateringTimes4 *obj in _wateringTimes) {
        [wateringTimesArray addObject:[obj toDictionary]];
    }
    [dic setObject:wateringTimesArray forKey:@"wateringTimes"];
    
    return dic;
}

+ (Program4 *)program
{
    Program4 *program = [[Program4 alloc] init];

    program.programId = -1;
    program.name = @"New Program";
    program.frequency = [Frequency4 frequency];
    program.active = YES;
    program.ignoreWeatherData = NO;
    program.cycles = 2;
    program.soak = 30 * 60;
    program.delay = 0;
    program.status = 0;
    program.coef = 0;
    program.futureField1 = 0;
    program.freq_modified = 0;
    program.useWaterSense = 0;
    
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
    program.nextRun = [NSDate date];
    
    return program;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    Program4 *program = [(Program4 *)[[self class] allocWithZone:zone] init];
    
    program.programId = self.programId;
    program.name = [self.name copy];
    program.active = self.active;
    program.startTime = [self.startTime copy];
    program.nextRun = [self.nextRun copy];
    program.cycles = self.cycles;
    program.soak = self.soak;
    program.csOn = self.csOn;
    program.delay = self.delay;
    program.delayOn = self.delayOn;
    program.status = self.status;
    program.frequency = [self.frequency copy];
    program.coef = self.coef;
    program.ignoreWeatherData = self.ignoreWeatherData;
    program.futureField1 = self.futureField1;
    program.freq_modified = self.freq_modified;
    program.useWaterSense = self.useWaterSense;
    program.wateringTimes = [NSMutableArray array];
    for (ProgramWateringTimes4 *wt in self.wateringTimes) {
        [program.wateringTimes addObject:[wt copy]];
    }
    
    return program;
}

- (BOOL)isEqualToProgram:(Program4*)program
{
    BOOL isEqual = YES;

    isEqual &= (program.active == self.active);
    isEqual &= (program.csOn == self.csOn);
    isEqual &= (program.cycles == self.cycles);
    isEqual &= (program.delay == self.delay);
    isEqual &= (program.delayOn == self.delayOn);
    isEqual &= ([program.frequency isEqualToFrequency:self.frequency]);
    isEqual &= (program.ignoreWeatherData == self.ignoreWeatherData);
    isEqual &= (program.useWaterSense == self.useWaterSense);
    isEqual &= ([program.name isEqualToString:self.name]);
    isEqual &= (program.programId == self.programId);
    isEqual &= (program.soak == self.soak);
    isEqual &= (program.status == self.status);
    isEqual &= ([program.startTime isEqualToDate:self.startTime]);
    isEqual &= ([program.nextRun isEqualToDate:self.nextRun]);
    isEqual &= ([program.weekdays isEqualToString:self.weekdays]);
    
    if (self.wateringTimes.count != program.wateringTimes.count) {
        isEqual = NO;
    } else {
        for (int i = 0; i < self.wateringTimes.count; i++) {
            ProgramWateringTimes4 *selfWateringTime = self.wateringTimes[i];
            ProgramWateringTimes4 *otherWateringTime = program.wateringTimes[i];
            isEqual &= ([otherWateringTime isEqualToProgramWateringTime:selfWateringTime]);
        }
    }
    
    return isEqual;
}

@end
