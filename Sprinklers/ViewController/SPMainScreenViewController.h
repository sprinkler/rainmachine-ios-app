//
//  SPMainScreenViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCommonProtocols.h"

@class SPServerProxy;

@interface SPMainScreenViewController : UITabBarController<SPSprinklerResponseProtocol>

@property (strong, nonatomic) SPServerProxy *serverProxy;

@end
