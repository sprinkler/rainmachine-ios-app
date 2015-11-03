//
//  GoogleElevation.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleElevation.h"

@implementation GoogleElevation

+ (instancetype)elevationWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    [self setupWithDictionary:dictionary];
    
    return self;
}

- (void)setupWithDictionary:(NSDictionary*)dictionary {
    self.elevation = [dictionary valueForKey:@"elevation"];
    NSDictionary *location = [dictionary valueForKey:@"location"];
    self.location = [[CLLocation alloc] initWithLatitude:[[location valueForKey:@"lat"] doubleValue]
                                               longitude:[[location valueForKey:@"lng"] doubleValue]];
}

@end
