//
//  GoogleRequestPlaceDetails.m
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequestPlaceDetails.h"
#import "GoogleAutocompletePrediction.h"
#import "GoogleAddress.h"
#import "Constants.h"

@implementation GoogleRequestPlaceDetails

+ (instancetype)placeDetailsRequestWithAutocompletePrediction:(GoogleAutocompletePrediction*)autocompletePrediction {
    return [[self alloc] initWithAutocompletePrediction:autocompletePrediction];
}

- (instancetype)initWithAutocompletePrediction:(GoogleAutocompletePrediction*)autocompletePrediction {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:autocompletePrediction.placeId,@"placeid",nil]];
    if (!self) return nil;
    
    _autocompletePrediction = autocompletePrediction;
    
    return self;
}

- (NSString*)googleRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/place/details";
}

- (NSString*)googleAPIKey {
    return kGooglePlacesAPIServerKey;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return [GoogleAddress googleAddressWithDictionary:[dictionary valueForKey:@"result"]];
}

@end
