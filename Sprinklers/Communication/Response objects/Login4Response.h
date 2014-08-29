//
//  Login4Response.h
//  Sprinklers
//
//  Created by Fabian Matyas on 13/08/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Login4Response : NSObject

@property (nonatomic, strong) NSString *access_token;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSString *expiration;
@property (nonatomic, strong) NSNumber *statusCode;

@end
