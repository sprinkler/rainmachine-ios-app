//
//  ZoneAdvancedProperties.m
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ZoneAdvancedProperties.h"

@implementation ZoneAdvancedProperties

+ (ZoneAdvancedProperties*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        ZoneAdvancedProperties *properties = [[ZoneAdvancedProperties alloc] init];
        
        properties.maxAllowedDepletion = [jsonObj objectForKey:@"maxAllowedDepletion"];
        properties.precipitationRate = [jsonObj objectForKey:@"precipitationRate"];
        properties.appEfficiency = [jsonObj objectForKey:@"appEfficiency"];
        properties.allowedSurfaceAcc = [jsonObj objectForKey:@"allowedSurfaceAcc"];
        properties.rootDepth = [jsonObj objectForKey:@"rootDepth"];
        properties.isTallPlant = [jsonObj objectForKey:@"isTallPlant"];
        properties.soilIntakeRate = [jsonObj objectForKey:@"soilIntakeRate"];
        properties.permWilting = [jsonObj objectForKey:@"permWilting"];
        properties.fieldCapacity = [jsonObj objectForKey:@"fieldCapacity"];
        properties.detailedMonthsKc = [jsonObj objectForKey:@"detailedMonthsKc"];
        
        return properties;
    }
    return nil;
}

- (NSDictionary*)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    dictionary[@"maxAllowedDepletion"] = self.maxAllowedDepletion;
    dictionary[@"precipitationRate"] = self.precipitationRate;
    dictionary[@"appEfficiency"] = self.appEfficiency;
    dictionary[@"allowedSurfaceAcc"] = self.allowedSurfaceAcc;
    dictionary[@"rootDepth"] = self.rootDepth;
    dictionary[@"isTallPlant"] = self.isTallPlant;
    dictionary[@"soilIntakeRate"] = self.soilIntakeRate;
    dictionary[@"permWilting"] = self.permWilting;
    dictionary[@"fieldCapacity"] = self.fieldCapacity;
    dictionary[@"detailedMonthsKc"] = self.detailedMonthsKc;
    
    return dictionary;
}

- (id)copyWithZone:(NSZone *)copyZone {
    ZoneAdvancedProperties *properties = [(ZoneAdvancedProperties *)[[self class] allocWithZone:copyZone] init];
    
    properties.maxAllowedDepletion = self.maxAllowedDepletion;
    properties.precipitationRate = self.precipitationRate;
    properties.appEfficiency = self.appEfficiency;
    properties.allowedSurfaceAcc = self.allowedSurfaceAcc;
    properties.rootDepth = self.rootDepth;
    properties.isTallPlant = self.isTallPlant;
    properties.soilIntakeRate = self.soilIntakeRate;
    properties.permWilting = self.permWilting;
    properties.fieldCapacity = self.fieldCapacity;
    properties.detailedMonthsKc = self.detailedMonthsKc;
    
    return properties;
}

- (BOOL)isEqualToZoneAdvancedProperties:(ZoneAdvancedProperties*)zoneAdvancedProperties {
    BOOL isEqual = YES;
    
    isEqual &= ([zoneAdvancedProperties.maxAllowedDepletion isEqual:self.maxAllowedDepletion]);
    isEqual &= ([zoneAdvancedProperties.precipitationRate isEqual:self.precipitationRate]);
    isEqual &= ([zoneAdvancedProperties.appEfficiency isEqual:self.appEfficiency]);
    isEqual &= ([zoneAdvancedProperties.allowedSurfaceAcc isEqual:self.allowedSurfaceAcc]);
    isEqual &= ([zoneAdvancedProperties.rootDepth isEqual:self.rootDepth]);
    isEqual &= ([zoneAdvancedProperties.isTallPlant isEqual:self.isTallPlant]);
    isEqual &= ([zoneAdvancedProperties.soilIntakeRate isEqual:self.soilIntakeRate]);
    isEqual &= ([zoneAdvancedProperties.permWilting isEqual:self.permWilting]);
    isEqual &= ([zoneAdvancedProperties.fieldCapacity isEqual:self.fieldCapacity]);
    isEqual &= ([zoneAdvancedProperties.detailedMonthsKc isEqual:self.detailedMonthsKc]);
    
    return isEqual;
}

@end
