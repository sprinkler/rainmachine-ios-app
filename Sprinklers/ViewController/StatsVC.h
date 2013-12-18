//
//  StatsVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "SPCommonProtocols.h"

@class SPServerProxy;
@class MBProgressHUD;


@interface StatsVC : BaseViewController<UITableViewDataSource, UITableViewDelegate, SPSprinklerResponseProtocol>

@property (strong, nonatomic) UIImage *waterImage;
@property (strong, nonatomic) UIImage *waterWavesImage;
@property (strong, nonatomic) SPServerProxy *serverProxy;
@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *dataSourceTableView;

@property (strong, nonatomic) MBProgressHUD *hud;

@end
