//
//  SPLoginViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@class Sprinkler;
@class ServerProxy;
@class MBProgressHUD;

@interface LoginViewController : UITableViewController<SprinklerResponseProtocol>

- (IBAction)onLogin:(id)sender;

@end
