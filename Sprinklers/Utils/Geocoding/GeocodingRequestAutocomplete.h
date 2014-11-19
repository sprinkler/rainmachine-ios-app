//
//  GeocodingRequestAutocomplete.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequest.h"

@interface GeocodingRequestAutocomplete : GeocodingRequest

+ (instancetype)autocompleteGeocodingRequestWithInputString:(NSString*)inputString;
- (instancetype)initWithInputString:(NSString*)inputString;

@end
