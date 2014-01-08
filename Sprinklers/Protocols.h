//
//  Protocols.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SprinklerResponseProtocol <NSObject>

- (void)loggedOut;
- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy;
- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy;

@optional
- (void)loginSucceeded;
- (void)programDeleted:(int)programId;

@end
