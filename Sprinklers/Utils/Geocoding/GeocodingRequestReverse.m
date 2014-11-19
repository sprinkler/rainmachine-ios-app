//
//  GeocodingRequestReverse.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequestReverse.h"
#import "GeocodingAddress.h"
#import "Constants.h"

@implementation GeocodingRequestReverse

+ (instancetype)reverseGeocodingRequestWithLocation:(CLLocation*)location {
    return [[self alloc] initWithLocation:location];
}

- (instancetype)initWithLocation:(CLLocation*)location {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%6f,%6f",location.coordinate.latitude,location.coordinate.longitude],@"latlng", nil]];
    if (!self) return nil;
    
    _location = location;
    
    return self;
}

- (NSString*)geocodingRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/geocode";
}

- (NSString*)geocodingAPIKey {
    return kGoogleMapsAPIKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    NSArray *results = [dictionary valueForKey:@"results"];
    if (!results.count) return nil;
    GeocodingAddress *address = [GeocodingAddress geocodingAddressWithDictionary:results[0]];
    address.location = self.location;
    return address;
}

@end
