//
//  SPServerProxy.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPCommonProtocols.h"

@class AFHTTPRequestOperationManager;

@interface SPServerProxy : NSObject
{
}
- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SPSprinklerResponseProtocol>)del;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;
- (void)requestWeatherData;

@property (nonatomic, weak) id<SPSprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

@end
