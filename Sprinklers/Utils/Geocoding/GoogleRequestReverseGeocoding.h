//
//  GoogleRequestReverseGeocoding.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequest.h"
#import <CoreLocation/CoreLocation.h>

@interface GoogleRequestReverseGeocoding : GoogleRequest

@property (nonatomic, strong) CLLocation *location;

+ (instancetype)reverseGeocodingRequestWithLocation:(CLLocation*)location;
- (instancetype)initWithLocation:(CLLocation*)location;

@end
