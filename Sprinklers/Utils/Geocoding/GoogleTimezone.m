//
//  GoogleTimezone.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleTimezone.h"

@implementation GoogleTimezone

+ (instancetype)timezoneWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    [self setupWithDictionary:dictionary];
    
    return self;
}

- (void)setupWithDictionary:(NSDictionary*)dictionary {
    self.timeZoneId = [dictionary valueForKey:@"timeZoneId"];
    self.timeZoneName = [dictionary valueForKey:@"timeZoneName"];
}

@end
