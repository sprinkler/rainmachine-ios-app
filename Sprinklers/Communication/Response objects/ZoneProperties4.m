//
//  ZoneProperties4.m
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "ZoneProperties4.h"
#import "ServerProxy.h"
#import "Additions.h"

@implementation ZoneProperties4

@synthesize vegetation = _vegetation;

+ (ZoneProperties4 *)createFromJson:(NSDictionary *)jsonObj {
    if (jsonObj) {
        ZoneProperties4 *zone = [[ZoneProperties4 alloc] init];
        
        zone.zoneId = [jsonObj nullProofedIntValueForKey:@"uid"];
        zone.masterValve = [jsonObj nullProofedIntValueForKey:@"master"];
        zone.before = [jsonObj nullProofedIntValueForKey:@"before"];
        zone.after = [jsonObj nullProofedIntValueForKey:@"after"];
        zone.active = [jsonObj nullProofedIntValueForKey:@"active"];
        zone.name = [jsonObj nullProofedStringValueForKey:@"name"];
        zone.vegetation = [jsonObj nullProofedIntValueForKey:@"type"];
        zone.valveid = [jsonObj nullProofedIntValueForKey:@"valveid"];
        zone.ETcoef = [jsonObj objectForKey:@"ETcoef"];
        zone.internet = [jsonObj objectForKey:@"internet"];
        zone.savings = [jsonObj objectForKey:@"savings"];
        zone.slope = [jsonObj objectForKey:@"slope"];
        zone.sun = [jsonObj objectForKey:@"sun"];
        zone.soil = [jsonObj objectForKey:@"soil"];
        zone.group_id = [jsonObj objectForKey:@"group_id"];
        zone.history = [jsonObj objectForKey:@"history"];
        
        if (zone.before < 0)
            zone.before = 0;
        
        if (zone.after < 0)
            zone.after = 0;
        
        return zone;
    }
    return nil;
}

//- (int)vegetation
//{
//    switch (_vegetation) {
//        case kAPI4ZoneVegetationType_Lawn:
//            return 2;
//            break;
//        case kAPI4ZoneVegetationType_Fruit_Trees:
//            return 3;
//            break;
//        case kAPI4ZoneVegetationType_Flowers:
//            return 4;
//            break;
//        case kAPI4ZoneVegetationType_Vegetables:
//            return 5;
//            break;
//        case kAPI4ZoneVegetationType_Citrus:
//            return 6;
//            break;
//        case kAPI4ZoneVegetationType_Trees_And_Bushes:
//            return 7;
//            break;
//        case kAPI4ZoneVegetationType_Other:
//            return 8;
//            break;
//            
//        default:
//            return 8;
//    }
//}
//
//- (void)setVegetation:(int)v
//{
//    switch (v) {
//        case 2:
//            _vegetation = kAPI4ZoneVegetationType_Lawn;
//            break;
//        case 3:
//            _vegetation = kAPI4ZoneVegetationType_Fruit_Trees;
//            break;
//        case 4:
//            _vegetation = kAPI4ZoneVegetationType_Flowers;
//            break;
//        case 5:
//            _vegetation = kAPI4ZoneVegetationType_Vegetables;
//            break;
//        case 6:
//            _vegetation = kAPI4ZoneVegetationType_Citrus;
//            break;
//        case 7:
//            _vegetation = kAPI4ZoneVegetationType_Trees_And_Bushes;
//            break;
//        case 8:
//            _vegetation = kAPI4ZoneVegetationType_Other;
//            break;
//            
//        default:
//            _vegetation = kAPI4ZoneVegetationType_Other;
//    }
//}

- (int)historicalAverage
{
    return self.history.intValue;
}

- (int)forecastData
{
    return self.internet.intValue;
}

- (void)setHistoricalAverage:(int)historicalAverage
{
    self.history = @(historicalAverage);
}

- (void)setForecastData:(int)forecastData {
    self.internet = @(forecastData);
}

- (id)copyWithZone:(NSZone *)copyZone {
    ZoneProperties4 *zone = [(ZoneProperties4 *)[[self class] allocWithZone:copyZone] init];
    
    zone.zoneId = self.zoneId;
    zone.masterValve = self.masterValve;
    zone.before = self.before;
    zone.after = self.after;
    zone.active = self.active;
    zone.name = [self.name copy];
    zone.vegetation = self.vegetation;
    zone.valveid = self.valveid;
    zone.ETcoef = [self.ETcoef copy];
    zone.internet = [self.internet copy];
    zone.savings = [self.savings copy];
    zone.slope = [self.slope copy];
    zone.sun = [self.sun copy];
    zone.soil = [self.soil copy];
    zone.group_id = [self.group_id copy];
    zone.history = [self.history copy];

    return zone;
}

- (BOOL)isEqualToZone:(ZoneProperties4*)zone
{
    BOOL isEqual = YES;
    
    isEqual &= (zone.zoneId == self.zoneId);
    isEqual &= (zone.masterValve == self.masterValve);
    isEqual &= (zone.before == self.before);
    isEqual &= (zone.after == self.after);
    isEqual &= (zone.active == self.active);
    isEqual &= ([zone.name isEqualToString:self.name]);
    isEqual &= (zone.vegetation == self.vegetation);
    isEqual &= (zone.valveid == self.valveid);
    isEqual &= ([zone.ETcoef isEqualToNumber:self.ETcoef]);
    isEqual &= ([zone.internet isEqualToNumber:self.internet]);
    isEqual &= ([zone.savings isEqualToNumber:self.savings]);
    isEqual &= ([zone.slope isEqualToNumber:self.slope]);
    isEqual &= ([zone.sun isEqualToNumber:self.sun]);
    isEqual &= ([zone.soil isEqualToNumber:self.soil]);
    isEqual &= ([zone.group_id isEqualToNumber:self.group_id]);
    isEqual &= ([zone.history isEqualToNumber:self.history]);
    
    return isEqual;
}

@end
