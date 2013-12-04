//
//  SPCommonProtocols.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SPSprinklerResponseProtocol <NSObject>

- (void)loginSucceeded;
- (void)loggedOut;
- (void)serverErrorReceived:(NSError*)error;
- (void)serverResponseReceived:(id)data;

@end
