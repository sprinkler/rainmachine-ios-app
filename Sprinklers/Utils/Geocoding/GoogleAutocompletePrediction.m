//
//  GoogleAutocompletePrediction.m
//  Sprinklers
//
//  Created by Istvan Sipos on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleAutocompletePrediction.h"

@implementation GoogleAutocompletePrediction

+ (instancetype)autocompletePredictionWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    [self setupWithDictionary:dictionary];
    
    return self;
}

- (void)setupWithDictionary:(NSDictionary*)dictionary {
    self.placeDescription = [dictionary valueForKey:@"description"];
    self.id = [dictionary valueForKey:@"id"];
    self.placeId = [dictionary valueForKey:@"place_id"];
    
    NSArray *matchedSubstrings = [dictionary valueForKey:@"matched_substrings"];
    NSMutableArray *matchedRanges = [NSMutableArray new];
    
    for (NSDictionary *matchingDictionary in matchedSubstrings) {
        NSInteger offset = [[matchingDictionary valueForKey:@"offset"] integerValue];
        NSInteger length = [[matchingDictionary valueForKey:@"length"] integerValue];
        
        NSRange matchedRange = NSMakeRange(offset, length);
        [matchedRanges addObject:[NSValue valueWithRange:matchedRange]];
    }
    
    self.matchedRanges = matchedRanges;
}

@end
