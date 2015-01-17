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

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return dateFormatter;
}
+ (MixerDailyValue*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        MixerDailyValue *mixerDailyValue = [MixerDailyValue new];
        
        mixerDailyValue.day = [[self dateFormatter] dateFromString:[jsonObj nullProofedStringValueForKey:@"day"]];
        mixerDailyValue.temperature = [jsonObj nullProofedDoubleValueForKey:@"temperature"];
        mixerDailyValue.rh = [jsonObj nullProofedDoubleValueForKey:@"rh"];
        mixerDailyValue.wind = [jsonObj nullProofedDoubleValueForKey:@"wind"];
        mixerDailyValue.solarRad = [jsonObj nullProofedDoubleValueForKey:@"solarRad"];
        mixerDailyValue.skyCover = [jsonObj nullProofedDoubleValueForKey:@"skyCover"];
        mixerDailyValue.rain = [jsonObj nullProofedDoubleValueForKey:@"rain"];
        mixerDailyValue.et0 = [jsonObj nullProofedDoubleValueForKey:@"et0"];
        mixerDailyValue.pop = [jsonObj nullProofedDoubleValueForKey:@"pop"];
        mixerDailyValue.qpf = [jsonObj nullProofedDoubleValueForKey:@"qpf"];
        mixerDailyValue.condition = [jsonObj nullProofedIntValueForKey:@"condition"];
        mixerDailyValue.pressure = [jsonObj nullProofedDoubleValueForKey:@"pressure"];
        mixerDailyValue.dewPoint = [jsonObj nullProofedDoubleValueForKey:@"dewPoint"];
        mixerDailyValue.minTemp = [jsonObj nullProofedDoubleValueForKey:@"minTemp"];
        mixerDailyValue.maxTemp = [jsonObj nullProofedDoubleValueForKey:@"maxTemp"];
        mixerDailyValue.minRH = [jsonObj nullProofedDoubleValueForKey:@"minRH"];
        mixerDailyValue.maxRH = [jsonObj nullProofedDoubleValueForKey:@"maxRH"];
        mixerDailyValue.et0calc = [jsonObj nullProofedDoubleValueForKey:@"et0calc"];
        mixerDailyValue.et0final = [jsonObj nullProofedDoubleValueForKey:@"et0final"];
        
        return mixerDailyValue;
    }
    return nil;
}

@end
