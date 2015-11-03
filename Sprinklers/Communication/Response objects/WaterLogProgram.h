//
//  WaterLogProgram.h
//  Sprinklers
//
//  Created by Istvan Sipos on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaterLogProgram : NSObject

@property (nonatomic, assign) int programId;
@property (nonatomic, strong) NSArray *zones;

+ (WaterLogProgram*)createFromJson:(NSDictionary*)jsonObj;

@property (nonatomic, assign) int realDurationSum;
@property (nonatomic, assign) int userDurationSum;
@property (nonatomic, readonly) double durationPercentage;

@end
