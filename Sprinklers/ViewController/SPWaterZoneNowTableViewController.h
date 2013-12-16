//
//  SPWaterZoneNowTableViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCommonProtocols.h"

@class SPWaterNowZone;
@class SPServerProxy;
@class SPMainScreenViewController;

@interface SPWaterZoneNowTableViewController : UITableViewController<SPSprinklerResponseProtocol>
{
  NSTimeInterval retryInterval;
}

@property (retain, nonatomic) SPWaterNowZone *waterZone;
@property (strong, nonatomic) SPServerProxy *serverProxy;
@property (strong, nonatomic) SPServerProxy *postServerProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) SPMainScreenViewController *theTabBarController;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
- (IBAction)onUpButton:(id)sender;
- (IBAction)onDownButton:(id)sender;
- (IBAction)onStartButton:(id)sender;

@end
