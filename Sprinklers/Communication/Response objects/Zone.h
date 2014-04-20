//
//  Zone.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Zone : NSObject<NSCopying>

@property (nonatomic) int zoneId;
@property (nonatomic) int masterValve;
@property (nonatomic) int before;
@property (nonatomic) int after;
@property (nonatomic) int active;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int vegetation;
@property (nonatomic) int forecastData;
@property (nonatomic) int historicalAverage;

+ (Zone *)createFromJson:(NSDictionary *)jsonObj;
- (BOOL)isEqualToZone:(Zone*)program;

@end
