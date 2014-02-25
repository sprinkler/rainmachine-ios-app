//
//  Program.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Program : NSObject

@property (nonatomic) int active;
@property (nonatomic) int csOn; // cycle/soak flag
@property (nonatomic) int cycles;
@property (nonatomic) int delay;
@property (nonatomic) int delayOn;
@property (nonatomic) int frequency;
@property (nonatomic) int ignoreWeatherData;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int parameter;
@property (nonatomic) int programId;
@property (nonatomic) int soak;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSString *state;
@property (nonatomic) int timeFormat;
@property (nonatomic, strong) NSString *weekdays;
@property (nonatomic, strong) NSMutableArray *wateringTimes;

+ (Program *)createFromJson:(NSDictionary *)jsonObj;

@end
