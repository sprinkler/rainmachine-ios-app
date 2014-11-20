//
//  GoogleRequestElevation.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequestElevation.h"
#import "GoogleElevation.h"
#import "Constants.h"

@implementation GoogleRequestElevation

+ (instancetype)elevationRequestWithLocation:(CLLocation*)location {
    return [[self alloc] initWithLocation:location];
}

- (instancetype)initWithLocation:(CLLocation*)location {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%6f,%6f",location.coordinate.latitude,location.coordinate.longitude],@"locations", nil]];
    if (!self) return nil;
    
    _location = location;
    
    return self;
}

- (NSString*)googleRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/elevation";
}

- (NSString*)googleAPIKey {
    return kGoogleMapsAPIKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    NSArray *results = [dictionary valueForKey:@"results"];
    if (!results.count) return nil;
    GoogleElevation *elevation = [GoogleElevation elevationWithDictionary:results[0]];
    elevation.location = self.location;
    return elevation;
}

@end
