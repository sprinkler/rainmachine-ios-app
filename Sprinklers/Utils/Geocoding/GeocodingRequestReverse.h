//
//  GeocodingRequestReverse.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequest.h"
#import <CoreLocation/CoreLocation.h>

@interface GeocodingRequestReverse : GeocodingRequest

@property (nonatomic, strong) CLLocation *location;

+ (instancetype)reverseGeocodingRequestWithLocation:(CLLocation*)location;
- (instancetype)initWithLocation:(CLLocation*)location;

@end
