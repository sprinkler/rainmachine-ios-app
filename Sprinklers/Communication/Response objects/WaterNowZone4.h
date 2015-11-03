//
//  SPWaterNowZone.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterNowZone4 : NSObject

@property (nonatomic, strong) NSNumber *uid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *state;
@property (nonatomic, strong) NSNumber *userDuration;
@property (nonatomic, strong) NSNumber *machineDuration;
@property (nonatomic, strong) NSNumber *remaining;
@property (nonatomic, strong) NSNumber *cycle;
@property (nonatomic, strong) NSNumber *noOfCycles;
@property (nonatomic, strong) NSNumber *restriction;
@property (nonatomic, strong) NSNumber *waterSense;

// These fields come as a response for GET zone
@property (nonatomic, strong) NSNumber *type; // kVegetationType
@property (nonatomic, strong) NSNumber *master;

+ (WaterNowZone4 *)createFromJson:(NSDictionary *)jsonObj;
- (NSNumber*)id;

@end
