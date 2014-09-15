//
//  Program.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    API4_ProgramFrequencyType_Daily = 0,
    API4_ProgramFrequencyType_Weekdays = 2,
    API4_ProgramFrequencyType_OddOrEvenDays = 4,
    API4_ProgramFrequencyType_Nth = 5
} API4_ProgramFrequencyType;

@interface Frequency4 : NSObject<NSCopying>

@property (nonatomic) int type;
@property (nonatomic, strong) NSString *param;

+ (Frequency4 *)createFromJson:(NSDictionary *)jsonObj;
+ (Frequency4 *)frequency;
- (BOOL)isEqualToFrequency:(Frequency4*)frequency;
- (NSDictionary*)toDictionary;

@end
