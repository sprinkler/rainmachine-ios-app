//
//  SprinklerListViewController_iPhone.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "PullToRefreshView.h"

@interface SprinklerListViewController_iPhone : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, PullToRefreshViewDelegate> {
    NSMutableArray *discoveredSprinklers;
    IBOutlet UIView *loadingOverlay;
    MBProgressHUD *hud;
    NSTimer *timer;
    NSTimer *silentTimer;
    UIAlertView *alertView;
    BOOL sprinklerWebDisplayed;
    BOOL pullToRefresh;
    PullToRefreshView *pullToRefreshView;
}

@property (strong, nonatomic) IBOutlet UIView *viewLoading;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
