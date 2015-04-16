//
//  Program.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ProgramFrequency_Daily = 0,
    ProgramFrequency_Weekdays = 2,
    ProgramFrequency_OddDays = 4,
    ProgramFrequency_EvenDays = 5,
    ProgramFrequency_INT = 6
} ProgramFrequency;

typedef enum {
    API4_ProgramStatus_Stopped = 0,
    API4_ProgramStatus_Running
} API4_ProgramStatus;

typedef enum {
    API4_ProgramFrequencyParam_Even = 0,
    API4_ProgramFrequencyParam_Odd = 1
} API4_ProgramFrequencyParam;

@interface Program : NSObject<NSCopying>

@property (nonatomic) int active;
@property (nonatomic) int csOn; // cycle/soak flag
@property (nonatomic) int cycles;
@property (nonatomic) int delay;
@property (nonatomic) int delayMinutes;
@property (nonatomic) int delayOn;
@property (nonatomic) int frequency;
@property (nonatomic) int ignoreWeatherData;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int parameter;
@property (nonatomic) int programId;
@property (nonatomic) int soak;
@property (nonatomic) int soakMinutes;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSString *state;
@property (nonatomic) int timeFormat;
@property (nonatomic, strong) NSString *weekdays;
@property (nonatomic, strong) NSMutableArray *wateringTimes;

+ (Program *)createFromJson:(NSDictionary *)jsonObj;
+ (Program *)program;

- (BOOL)isEqualToProgram:(Program*)program;
- (NSDictionary*)toDictionary;

@end
