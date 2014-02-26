//
//  ProgramWateringTimes.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramWateringTimes.h"

@implementation ProgramWateringTimes

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    
    [dic setObject:[NSNumber numberWithInt:_wtId] forKey:@"id"];
    [dic setObject:[NSNumber numberWithInt:_minutes] forKey:@"minutes"];

    if (_name) {
        [dic setObject:_name forKey:@"name"];
    } else {
        [dic setObject:@"" forKey:@"name"];
    }

    return dic;
}

@end
