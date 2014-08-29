//
//  UpdateManager.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocols.h"

@interface UpdateManager : NSObject<SprinklerResponseProtocol>

@property (assign, nonatomic) int serverAPIMainVersion;
@property (assign, nonatomic) int serverAPISubVersion;
@property (assign, nonatomic) int serverAPIMinorSubVersion;

- (instancetype)initWithDelegate:(id<UpdateManagerDelegate>)delegate;
- (void)poll;
- (void)stop;
- (void)startUpdate;
- (void)setSprinklerVersionMajor:(int)major minor:(int)minor subMinor:(int)subMinor;

@end
