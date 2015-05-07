//
//  MixerDailyValue.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "MixerDailyValue.h"
#import "Additions.h"

@implementation MixerDailyValue

+ (MixerDailyValue*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        MixerDailyValue *mixerDailyValue = [MixerDailyValue new];
        
        mixerDailyValue.day = [[NSDate sharedDateTimeFormatterAPI4] dateFromString:[jsonObj nullProofedStringValueForKey:@"day"]];
        mixerDailyValue.temperature = [jsonObj nullProofedNumberValueForKey:@"temperature"];
        mixerDailyValue.rh = [jsonObj nullProofedNumberValueForKey:@"rh"];
        mixerDailyValue.wind = [jsonObj nullProofedNumberValueForKey:@"wind"];
        mixerDailyValue.solarRad = [jsonObj nullProofedNumberValueForKey:@"solarRad"];
        mixerDailyValue.skyCover = [jsonObj nullProofedNumberValueForKey:@"skyCover"];
        mixerDailyValue.rain = [jsonObj nullProofedNumberValueForKey:@"rain"];
        mixerDailyValue.et0 = [jsonObj nullProofedNumberValueForKey:@"et0"];
        mixerDailyValue.pop = [jsonObj nullProofedNumberValueForKey:@"pop"];
        mixerDailyValue.qpf = [jsonObj nullProofedNumberValueForKey:@"qpf"];
        mixerDailyValue.condition = [jsonObj nullProofedNumberValueForKey:@"condition"];
        mixerDailyValue.pressure = [jsonObj nullProofedNumberValueForKey:@"pressure"];
        mixerDailyValue.dewPoint = [jsonObj nullProofedNumberValueForKey:@"dewPoint"];
        mixerDailyValue.minTemp = [jsonObj nullProofedNumberValueForKey:@"minTemp"];
        mixerDailyValue.maxTemp = [jsonObj nullProofedNumberValueForKey:@"maxTemp"];
        mixerDailyValue.minRH = [jsonObj nullProofedNumberValueForKey:@"minRH"];
        mixerDailyValue.maxRH = [jsonObj nullProofedNumberValueForKey:@"maxRH"];
        mixerDailyValue.et0calc = [jsonObj nullProofedNumberValueForKey:@"et0calc"];
        mixerDailyValue.et0final = [jsonObj nullProofedNumberValueForKey:@"et0final"];
        
        return mixerDailyValue;
    }
    return nil;
}

@end
