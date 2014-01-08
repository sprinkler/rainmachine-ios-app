//
//  Zone.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Zone : NSObject

@property (nonatomic) int zoneId;
@property (nonatomic) BOOL masterValve;
@property (nonatomic) int before;
@property (nonatomic) int after;
@property (nonatomic) BOOL active;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int vegetation;
@property (nonatomic) BOOL forecastData;
@property (nonatomic) BOOL historicalAverage;

+ (Zone *)createFromJson:(NSDictionary *)jsonObj;

@end
