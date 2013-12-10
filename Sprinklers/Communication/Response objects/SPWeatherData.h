//
//  SPWeatherData.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPWeatherData : NSObject

@property (nonatomic, strong) NSNumber *day;
@property (nonatomic, strong) NSNumber *icon;
@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSNumber *maxt;
@property (nonatomic, strong) NSNumber *mint;
@property (nonatomic, strong) NSNumber *percentage;
@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) NSString *lastupdate;
@property (nonatomic, strong) NSString *location;

@end
