//
//  GeocodingRequestPlaceDetails.h
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequest.h"

@class GeocodingAutocompletePrediction;

@interface GeocodingRequestPlaceDetails : GeocodingRequest

@property (nonatomic, strong) GeocodingAutocompletePrediction *autocompletePrediction;

+ (instancetype)placeDetailsGeocodingRequestWithAutocompletePrediction:(GeocodingAutocompletePrediction*)autocompletePrediction;
- (instancetype)initWithAutocompletePrediction:(GeocodingAutocompletePrediction*)autocompletePrediction;

@end
