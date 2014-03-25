//
//  StatsVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "Protocols.h"

@class ServerProxy;
@class MBProgressHUD;

@interface StatsVC : BaseViewController<UITableViewDataSource, UITableViewDelegate, SprinklerResponseProtocol>

@end
