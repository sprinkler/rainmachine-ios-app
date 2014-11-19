//
//  GeocodingRequestAutocomplete.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequestAutocomplete.h"

@implementation GeocodingRequestAutocomplete

+ (instancetype)autocompleteGeocodingRequestWithInputString:(NSString*)inputString {
    return [[self alloc] initWithInputString:inputString];
}

- (instancetype)initWithInputString:(NSString*)inputString {
    self = [super initWithParameters:[NSDictionary dictionaryWithObjectsAndKeys:inputString,@"input",nil]];
    if (!self) return nil;
    
    return self;
}

- (NSString*)geocodingRequestBaseURL {
    return @"https://maps.googleapis.com/maps/api/place/autocomplete";
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return nil;
}

@end
