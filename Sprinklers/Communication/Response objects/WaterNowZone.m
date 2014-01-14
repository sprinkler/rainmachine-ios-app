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
        id theId = [jsonObj objectForKey:@"id"];
        if ([theId isKindOfClass:[NSString class]]) {
            zone.id = [NSNumber numberWithInt:[theId intValue]];
        } else {
            zone.id = theId;
        }

        zone.name = [jsonObj objectForKey:@"name"];
        zone.type = [jsonObj objectForKey:@"type"];
        zone.state = [jsonObj objectForKey:@"state"];
        zone.counter = [jsonObj objectForKey:@"counter"];

        return zone;
    }
    return nil;
}

@end
