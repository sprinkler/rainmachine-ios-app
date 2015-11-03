//
//  ZoneAdvancedProperties.h
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZoneAdvancedProperties : NSObject

@property (nonatomic, strong) NSNumber *maxAllowedDepletion;
@property (nonatomic, strong) NSNumber *precipitationRate;
@property (nonatomic, strong) NSNumber *appEfficiency;
@property (nonatomic, strong) NSNumber *allowedSurfaceAcc;
@property (nonatomic, strong) NSNumber *rootDepth;
@property (nonatomic, strong) NSNumber *isTallPlant;
@property (nonatomic, strong) NSNumber *soilIntakeRate;
@property (nonatomic, strong) NSNumber *permWilting;
@property (nonatomic, strong) NSNumber *fieldCapacity;
@property (nonatomic, strong) NSArray *detailedMonthsKc;

+ (ZoneAdvancedProperties*)createFromJson:(NSDictionary*)jsonObj;
- (NSDictionary*)toDictionary;
- (BOOL)isEqualToZoneAdvancedProperties:(ZoneAdvancedProperties*)zoneAdvancedProperties;

@end
