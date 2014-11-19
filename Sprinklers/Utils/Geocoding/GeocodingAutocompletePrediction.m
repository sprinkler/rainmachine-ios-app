//
//  GeocodingAutocompletePrediction.m
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingAutocompletePrediction.h"

@implementation GeocodingAutocompletePrediction

+ (instancetype)autocompletePredictionWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    [self setupWithDictionary:dictionary];
    
    return self;
}

- (void)setupWithDictionary:(NSDictionary*)dictionary {
    self.placeDescription = [dictionary valueForKey:@"description"];
    self.id = [dictionary valueForKey:@"id"];
    self.placeId = [dictionary valueForKey:@"place_id"];
}

@end
