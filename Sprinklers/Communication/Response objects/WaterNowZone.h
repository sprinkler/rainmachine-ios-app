//
//  SPWaterNowZone.h
//  Sprinklers
//
//  Created by Fabian Matyas on 11/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterNowZone : NSObject

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSNumber *counter;

+ (WaterNowZone *)createFromJson:(NSDictionary *)jsonObj;

@end
