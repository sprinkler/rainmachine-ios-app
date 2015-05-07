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
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *rh;
@property (nonatomic, strong) NSNumber *wind;
@property (nonatomic, strong) NSNumber *solarRad;
@property (nonatomic, strong) NSNumber *skyCover;
@property (nonatomic, strong) NSNumber *rain;
@property (nonatomic, strong) NSNumber *et0;
@property (nonatomic, strong) NSNumber *pop;
@property (nonatomic, strong) NSNumber *qpf;
@property (nonatomic, strong) NSNumber *condition;
@property (nonatomic, strong) NSNumber *pressure;
@property (nonatomic, strong) NSNumber *dewPoint;
@property (nonatomic, strong) NSNumber *minTemp;
@property (nonatomic, strong) NSNumber *maxTemp;
@property (nonatomic, strong) NSNumber *minRH;
@property (nonatomic, strong) NSNumber *maxRH;
@property (nonatomic, strong) NSNumber *et0calc;
@property (nonatomic, strong) NSNumber *et0final;

+ (MixerDailyValue*)createFromJson:(NSDictionary*)jsonObj;

@end
