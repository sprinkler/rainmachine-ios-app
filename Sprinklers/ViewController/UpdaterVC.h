//
//  UpdaterVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 30/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface UpdaterVC : UIViewController<SprinklerResponseProtocol>

@property (assign, nonatomic) int serverAPIMainVersion;

@end
