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
@property (assign, nonatomic)int serverAPISubVersion;

- (void)initUpdaterManager;
- (void)poll:(id<UpdateManagerDelegate>)delegate;
- (void)startUpdate;

@end
