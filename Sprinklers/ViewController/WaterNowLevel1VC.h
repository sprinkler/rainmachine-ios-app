//
//  WaterNowLevel1VC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "SPCommonProtocols.h"

@class SPWaterNowZone;
@class SPServerProxy;
@class WaterNowVC;

@interface WaterNowLevel1VC : BaseLevel2ViewController<SPSprinklerResponseProtocol>
{
    NSTimeInterval retryInterval;
    UIColor *greenColor;
    UIColor *redColor;
}

@property (retain, nonatomic) SPWaterNowZone *waterZone;
@property (strong, nonatomic) SPServerProxy *serverProxy;
@property (strong, nonatomic) SPServerProxy *postServerProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) WaterNowVC *parent;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)onUpButton:(id)sender;
- (IBAction)onDownButton:(id)sender;
- (IBAction)onStartButton:(id)sender;

@end
