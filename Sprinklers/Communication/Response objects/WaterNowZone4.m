//
//  SPWaterNowZone.m
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "WaterNowZone4.h"
#import "ServerProxy.h"

@implementation WaterNowZone4

+ (WaterNowZone4 *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        WaterNowZone4 *zone = [[WaterNowZone4 alloc] init];

        zone.uid = [jsonObj objectForKey:@"uid"];
        zone.name = [jsonObj objectForKey:@"name"];
        zone.state = [jsonObj objectForKey:@"state"];
        zone.userDuration = [jsonObj objectForKey:@"userDuration"];
        zone.machineDuration = [jsonObj objectForKey:@"machineDuration"];
        zone.remaining = [jsonObj objectForKey:@"remaining"];
        zone.cycle = [jsonObj objectForKey:@"cycle"];
        zone.noOfCycles = [jsonObj objectForKey:@"noOfCycles"];
        zone.restriction = [jsonObj objectForKey:@"restriction"];

        zone.type = [jsonObj objectForKey:@"type"];
        zone.master = [jsonObj objectForKey:@"master"];

        return zone;
    }
    return nil;
}

- (NSNumber*)id
{
    return self.uid;
}

- (NSNumber*)counter
{
    return self.remaining;
}

- (void)setCounter:(NSNumber*)counter
{
    self.remaining = counter;
}

- (void)setState:(NSNumber *)stateParam
{
    if ([stateParam isKindOfClass:[NSNumber class]]) {
        _state = stateParam;
    } else {
        NSString *stateString = (NSString*)stateParam;
        if ((stateString.length == 0) || ([stateString isEqualToString:@"Idle"])) {
            _state = [NSNumber numberWithInt:kAPI4ZoneState_Idle];
        } else {
            if ([stateString isEqualToString:@"Watering"]) {
                _state = [NSNumber numberWithInt:kAPI4ZoneState_Watering];
            } else {
                _state = [NSNumber numberWithInt:kAPI4ZoneState_Pending];
            }
        }
    }
}

@end
