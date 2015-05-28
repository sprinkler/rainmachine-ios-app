//
//  Program.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 06/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Frequency4.h"
#import "Additions.h"

@implementation Frequency4

+ (Frequency4 *)createFromJson:(NSDictionary *)jsonObj {
    
    if (jsonObj) {
        
        Frequency4 *frequency = [[Frequency4 alloc] init];
        
        frequency.type = [jsonObj nullProofedIntValueForKey:@"type"];
        frequency.param = [jsonObj nullProofedStringValueForKey:@"param"];
        
        return frequency;
    }
    
    return nil;
}

+ (Frequency4 *)frequency
{
    Frequency4 *frequency = [[Frequency4 alloc] init];
    
    frequency.type = API4_ProgramFrequencyType_Daily;
    frequency.param = @"0";
    
    return frequency;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    Frequency4 *frequency = [(Frequency4 *)[[self class] allocWithZone:zone] init];
    
    frequency.type = self.type;
    frequency.param = [self.param copy];
    
    return frequency;
}

- (BOOL)isEqualToFrequency:(Frequency4*)frequency
{
    BOOL isEqual = YES;
    
    isEqual &= (frequency.type == self.type);
    isEqual &= ([frequency.param isEqualToString:self.param]);
    
    return isEqual;
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    
    [dic setObject:[NSNumber numberWithInt:_type] forKey:@"type"];
    [dic setObject:_param forKey:@"param"];
    
    return dic;
}

@end
