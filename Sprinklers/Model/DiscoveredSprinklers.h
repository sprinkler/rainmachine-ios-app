//
//  DiscoveredSprinklers.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiscoveredSprinklers : NSObject

@property (nonatomic, strong) NSString *sprinklerId;
@property (nonatomic, strong) NSString *sprinklerName;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSDate *updated;
@property (nonatomic, strong) NSString *host;
@property (nonatomic) int port;
@property (nonatomic, strong) NSString *apFlag;
@property (nonatomic, strong) NSString *password;

@end
