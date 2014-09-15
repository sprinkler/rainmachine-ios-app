//
//  ZoneProperties4.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZoneProperties4 : NSObject

@property (nonatomic, assign) int zoneId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int valveid;
@property (nonatomic, strong) NSNumber *ETcoef;
@property (nonatomic, assign) int active;
@property (nonatomic, assign) int vegetation;
@property (nonatomic, strong) NSNumber *internet;
@property (nonatomic, strong) NSNumber *savings;
@property (nonatomic, strong) NSNumber *slope;
@property (nonatomic, strong) NSNumber *sun;
@property (nonatomic, strong) NSNumber *soil;
@property (nonatomic, strong) NSNumber *group_id;
@property (nonatomic, strong) NSNumber *history;
@property (nonatomic, assign) int masterValve;
@property (nonatomic, assign) int before;
@property (nonatomic, assign) int after;

+ (ZoneProperties4 *)createFromJson:(NSDictionary *)jsonObj;
- (BOOL)isEqualToZone:(ZoneProperties4*)zone;

@end
