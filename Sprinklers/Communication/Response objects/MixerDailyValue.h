//
//  MixerDailyValue.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MixerDailyValue : NSObject

@property (nonatomic, strong) NSDate *day;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign) double rh;
@property (nonatomic, assign) double wind;
@property (nonatomic, assign) double solarRad;
@property (nonatomic, assign) double skyCover;
@property (nonatomic, assign) double rain;
@property (nonatomic, assign) double et0;
@property (nonatomic, assign) double pop;
@property (nonatomic, assign) double qpf;
@property (nonatomic, assign) int condition;
@property (nonatomic, assign) double pressure;
@property (nonatomic, assign) double dewPoint;
@property (nonatomic, assign) double minTemp;
@property (nonatomic, assign) double maxTemp;
@property (nonatomic, assign) double minRH;
@property (nonatomic, assign) double maxRH;
@property (nonatomic, assign) double et0calc;
@property (nonatomic, assign) double et0final;

+ (MixerDailyValue*)createFromJson:(NSDictionary*)jsonObj;

@end
