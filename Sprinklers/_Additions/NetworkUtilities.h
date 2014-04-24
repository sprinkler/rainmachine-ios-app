//
//  NetworkUtilities.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkUtilities : NSObject

+ (NSString *)broadcastAddressForAddress:(NSString *)ipAddress withMask:(NSString *)netmask;
+ (NSString *)ipAddressForInterface:(NSString *)ifName;
+ (NSString *)ipAddressForWifi;
+ (NSString *)netmaskForInterface:(NSString *)ifName;
+ (NSString *)netmaskForWifi;
+ (BOOL)isLoginCookieActiveForBaseUrl:(NSString*)baseUrl;
+ (void)invalidateLoginForBaseUrl:(NSString*)baseUrl;

@end
