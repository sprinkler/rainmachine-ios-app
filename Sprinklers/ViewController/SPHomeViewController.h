//
//  SPHomeViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCommonProtocols.h"

@class SPServerProxy;
@class MBProgressHUD;

@interface SPHomeViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, SPSprinklerResponseProtocol>

@property (strong, nonatomic) UIImage *waterImage;
@property (strong, nonatomic) SPServerProxy *serverProxy;
@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *dataSourceTableView;

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIAlertView *alertView;

@end
