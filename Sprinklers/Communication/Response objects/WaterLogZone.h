//
//  WaterLogZone.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterLogZone : NSObject

@property (nonatomic, assign) int zoneId;
@property (nonatomic, strong) NSString *zoneName;
@property (nonatomic, assign) int flag;
@property (nonatomic, strong) NSArray *cycles;

+ (WaterLogZone*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) int realDurationSum;
@property (nonatomic, assign) int userDurationSum;

@end
