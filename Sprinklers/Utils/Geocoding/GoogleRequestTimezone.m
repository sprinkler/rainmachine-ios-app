//
//  GoogleRequestTimezone.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequestTimezone.h"
#import "GoogleTimezone.h"
#import "Constants.h"

@implementation GoogleRequestTimezone

+ (instancetype)timezoneRequestWithLocation:(CLLocation*)location {
    return [[self alloc] initWithLocation:location];
}

- (instancetype)initWithLocation:(CLLocation*)location {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%6f,%6f",location.coordinate.latitude,location.coordinate.longitude],@"location",
                                                                                [NSString stringWithFormat:@"%lf",[[NSDate date] timeIntervalSince1970]],@"timestamp",nil]];
    if (!self) return nil;
    
    _location = location;
    
    return self;
}

- (NSString*)googleRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/timezone";
}

- (NSString*)googleAPIKey {
    return kGoogleMapsAPIKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return [GoogleTimezone timezoneWithDictionary:dictionary];
}

@end
