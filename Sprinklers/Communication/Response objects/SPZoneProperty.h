//
//  SPZoneProperty.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPZoneProperty : NSObject

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSNumber *masterValve;
@property (nonatomic, strong) NSNumber *before;
@property (nonatomic, strong) NSNumber *after;
@property (nonatomic, strong) NSNumber *active;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *vegetation;
@property (nonatomic, strong) NSNumber *forecastData;
@property (nonatomic, strong) NSNumber *historicalAverage;

@end
