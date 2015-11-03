//
//  SPWaterNowZone.m
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "WaterNowZone.h"

@implementation WaterNowZone

+ (WaterNowZone *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        WaterNowZone *zone = [[WaterNowZone alloc] init];

        zone.name = [jsonObj objectForKey:@"name"];
        zone.type = [jsonObj objectForKey:@"type"];
        zone.state = [jsonObj objectForKey:@"state"];

        // Workaround for the type mismatching from the server
        id theId = [jsonObj objectForKey:@"id"];
        if ([theId isKindOfClass:[NSString class]]) {
            zone.id = [NSNumber numberWithInt:[theId intValue]];
        } else {
            zone.id = theId;
        }

        // Workaround for the type mismatching from the server
        id theCounter = [jsonObj objectForKey:@"counter"];
        if ([theCounter isKindOfClass:[NSString class]]) {
            zone.counter = [NSNumber numberWithInt:[theCounter intValue]];
        } else {
            zone.counter = theCounter;
        }

        return zone;
    }
    return nil;
}

@end
