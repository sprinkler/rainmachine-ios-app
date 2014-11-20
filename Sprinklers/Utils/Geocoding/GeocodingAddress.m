//
//  GeocodingAddress.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingAddress.h"

@implementation GeocodingAddress

+ (instancetype)geocodingAddressWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    [self setupWithDictionary:dictionary];
    
    return self;
}

- (void)setupWithDictionary:(NSDictionary*)dictionary {
    NSArray *addressComponents = [dictionary valueForKey:@"address_components"];
    for (NSDictionary *addressComponent in addressComponents) {
        NSString *longName = [addressComponent valueForKey:@"long_name"];
        NSString *shortName = [addressComponent valueForKey:@"short_name"];
        NSArray *types = [addressComponent valueForKey:@"types"];
        
        if ([types containsObject:@"premise"]) self.premise = longName;
        else if ([types containsObject:@"street_number"]) self.streetNumber = longName;
        else if ([types containsObject:@"route"]) self.route = longName;
        else if ([types containsObject:@"neighborhood"]) self.neighborhood = longName;
        else if ([types containsObject:@"locality"]) self.locality = longName;
        else if ([types containsObject:@"administrative_area_level_1"]) {
            self.administrativeAreaLevel1 = longName;
            self.administrativeAreaLevel1Short = shortName;
        }
        else if ([types containsObject:@"administrative_area_level_2"]) self.administrativeAreaLevel2 = longName;
        else if ([types containsObject:@"country"]) {
            self.country = longName;
            self.countryShort = shortName;
        }
        else if ([types containsObject:@"postal_code"]) self.postalCode = longName;
    }
    
    NSDictionary *geometry = [dictionary valueForKey:@"geometry"];
    NSDictionary *location = [geometry valueForKey:@"location"];
    self.location = [[CLLocation alloc] initWithLatitude:[[location valueForKey:@"lat"] doubleValue]
                                               longitude:[[location valueForKey:@"lng"] doubleValue]];
}

@end
