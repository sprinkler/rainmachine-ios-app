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
        zone.masterValve = [jsonObj nullProofedIntValueForKey:@"masterValve"];
        zone.before = [jsonObj nullProofedIntValueForKey:@"before"];
        zone.after = [jsonObj nullProofedIntValueForKey:@"after"];
        zone.active = [jsonObj nullProofedIntValueForKey:@"active"];
        zone.name = [jsonObj nullProofedStringValueForKey:@"name"];
        zone.vegetation = [jsonObj nullProofedIntValueForKey:@"vegetation"];
        zone.forecastData = [jsonObj nullProofedIntValueForKey:@"forecastData"];
        zone.historicalAverage = [jsonObj nullProofedIntValueForKey:@"historicalAverage"];
        
        if (zone.before < 0)
            zone.before = 0;
        
        if (zone.after < 0)
            zone.after = 0;
        
        return zone;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)copyZone {
    Zone *zone = [(Zone *)[[self class] allocWithZone:copyZone] init];
    
    zone.zoneId = self.zoneId;
    zone.masterValve = self.masterValve;
    zone.before = self.before;
    zone.after = self.after;
    zone.active = self.active;
    zone.name = [self.name copy];
    zone.vegetation = self.vegetation;
    zone.forecastData = self.forecastData;
    zone.historicalAverage = self.historicalAverage;
    
    return zone;
}

- (BOOL)isEqualToZone:(Zone*)zone
{
    BOOL isEqual = YES;
    
    isEqual &= (zone.zoneId == self.zoneId);
    isEqual &= (zone.masterValve == self.masterValve);
    isEqual &= (zone.before == self.before);
    isEqual &= (zone.after == self.after);
    isEqual &= (zone.active == self.active);
    isEqual &= ([zone.name isEqualToString:self.name]);
    isEqual &= (zone.vegetation == self.vegetation);
    isEqual &= (zone.forecastData == self.forecastData);
    isEqual &= (zone.historicalAverage == self.historicalAverage);

    return isEqual;
}

@end
