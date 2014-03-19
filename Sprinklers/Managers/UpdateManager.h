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

@property (readonly, nonatomic) int serverAPIMainVersion;
@property (readonly, nonatomic)int serverAPISubVersion;

+ (UpdateManager*)current;

- (void)initUpdaterManager;
- (void)poll;

@end
