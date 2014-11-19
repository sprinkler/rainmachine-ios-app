//
//  GeocodingRequestReverse.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequestReverse.h"
#import "GeocodingAddress.h"

@implementation GeocodingRequestReverse

+ (instancetype)reverseGeocodingRequestWithLocation:(CLLocation*)location {
    return [[self alloc] initWithLocation:location];
}

- (instancetype)initWithLocation:(CLLocation*)location {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%6f,%6f",location.coordinate.latitude,location.coordinate.longitude],@"latlng", nil]];
    if (!self) return nil;
    
    return self;
}

- (NSString*)geocodingRequestBaseURL {
    return @"http://maps.googleapis.com/maps/api/geocode";
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    NSArray *results = [dictionary valueForKey:@"results"];
    if (!results.count) return nil;
    return [GeocodingAddress geocodingAddressWithDictionary:results[0]];
}

@end
