//
//  GeocodingRequestPlaceDetails.m
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequestPlaceDetails.h"
#import "GeocodingAutocompletePrediction.h"
#import "GeocodingAddress.h"
#import "Constants.h"

@implementation GeocodingRequestPlaceDetails

+ (instancetype)placeDetailsGeocodingRequestWithAutocompletePrediction:(GeocodingAutocompletePrediction*)autocompletePrediction {
    return [[self alloc] initWithAutocompletePrediction:autocompletePrediction];
}

- (instancetype)initWithAutocompletePrediction:(GeocodingAutocompletePrediction*)autocompletePrediction {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:autocompletePrediction.placeId,@"placeid",nil]];
    if (!self) return nil;
    
    _autocompletePrediction = autocompletePrediction;
    
    return self;
}

- (NSString*)geocodingRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/place/details";
}

- (NSString*)geocodingAPIKey {
    return kGooglePlacesAPIServerKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return [GeocodingAddress geocodingAddressWithDictionary:[dictionary valueForKey:@"result"]];
}

@end
