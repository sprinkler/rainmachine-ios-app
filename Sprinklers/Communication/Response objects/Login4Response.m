//
//  Login4Response.m
//  Sprinklers
//
//  Created by Fabian Matyas on 13/08/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Login4Response.h"
#import "Additions.h"

@implementation Login4Response

+ (Login4Response*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        Login4Response *loginResponse = [Login4Response new];
        
        loginResponse.accessToken = [jsonObj nullProofedStringValueForKey:@"access_token"];
        loginResponse.checksum = [jsonObj nullProofedStringValueForKey:@"checksum"];
        loginResponse.statusCode = [jsonObj nullProofedIntValueForKey:@"statusCode"];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"EEE, dd LLL yyyy HH:mm:ss O";
        
        loginResponse.expirationDate = [dateFormatter dateFromString:[jsonObj nullProofedStringValueForKey:@"expiration"]];
        
        return loginResponse;
    }
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (!self) return nil;
    
    self.accessToken = [dictionary valueForKey:@"access_token"];
    self.checksum = [dictionary valueForKey:@"checksum"];
    self.expirationDate = [dictionary valueForKey:@"expiration"];
    
    return self;
}

- (NSDictionary*)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setValue:self.accessToken forKey:@"access_token"];
    [dictionary setValue:self.checksum forKey:@"checksum"];
    [dictionary setValue:self.expirationDate forKey:@"expiration"];
    return dictionary;
}

@end

