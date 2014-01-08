//
//  Zone.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Zone.h"
#import "Additions.h"

@implementation Zone

+ (Zone *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        Zone *zone = [[Zone alloc] init];
        zone.zoneId = [jsonObj nullProofedIntValueForKey:@"id"];
        zone.masterValve = [jsonObj nullProofedBoolValueForKey:@"masterValve"];
        zone.before = [jsonObj nullProofedIntValueForKey:@"before"];
        zone.after = [jsonObj nullProofedIntValueForKey:@"after"];
        zone.active = [jsonObj nullProofedBoolValueForKey:@"active"];
        zone.name = [jsonObj nullProofedStringValueForKey:@"name"];
        zone.vegetation = [jsonObj nullProofedIntValueForKey:@"vegetation"];
        zone.forecastData = [jsonObj nullProofedBoolValueForKey:@"forecastData"];
        zone.historicalAverage = [jsonObj nullProofedBoolValueForKey:@"historicalAverage"];
        return zone;
    }
    return nil;
}

@end
