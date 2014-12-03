//
//  Login4Response.h
//  Sprinklers
//
//  Created by Fabian Matyas on 13/08/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Login4Response : NSObject

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, assign) int statusCode;

+ (Login4Response*)createFromJson:(NSDictionary*)jsonObj;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)toDictionary;

@end
