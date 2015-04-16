//
//  Program.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Program.h"
#import "Frequency4.h"

@interface Program4 : NSObject<NSCopying>
@property (nonatomic) int programId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL active;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *nextRun;
@property (nonatomic) int cycles;
@property (nonatomic) int soak;
@property (nonatomic) int soakMinutes;
@property (nonatomic) BOOL csOn; // cycle/soak flag
@property (nonatomic) int delay;
@property (nonatomic) int delayMinutes;
@property (nonatomic) BOOL delayOn;
@property (nonatomic) int status;
@property (nonatomic) Frequency4 *frequency;
@property (nonatomic) float coef;
@property (nonatomic) int ignoreWeatherData;
@property (nonatomic) int futureField1;
@property (nonatomic) int freq_modified;
@property (nonatomic) int useWaterSense;
@property (nonatomic, strong) NSMutableArray *wateringTimes;

+ (Program4 *)createFromJson:(NSDictionary *)jsonObj;
+ (Program4 *)program;

- (BOOL)isEqualToProgram:(Program*)program;
- (NSDictionary*)toDictionary;

- (void)setWeekdays:(NSString *)weekdays;
- (NSString*)weekdays;

- (void)setState:(NSString*)state;
- (NSString*)state;

- (void)setTimeFormat:(int)tf;
- (int)timeFormat;

@end
