//
//  GoogleRequestElevation.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequest.h"
#import <CoreLocation/CoreLocation.h>

@interface GoogleRequestElevation : GoogleRequest

@property (nonatomic, strong) CLLocation *location;

+ (instancetype)elevationRequestWithLocation:(CLLocation*)location;
- (instancetype)initWithLocation:(CLLocation*)location;

@end
