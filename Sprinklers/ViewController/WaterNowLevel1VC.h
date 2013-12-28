//
//  WaterNowLevel1VC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLevel2ViewController.h"
#import "Protocols.h"

@class WaterNowZone;
@class ServerProxy;
@class WaterNowVC;

@interface WaterNowLevel1VC : BaseLevel2ViewController<SprinklerResponseProtocol>
{
    NSTimeInterval retryInterval;
    UIColor *greenColor;
    UIColor *redColor;
}

@property (retain, nonatomic) WaterNowZone *waterZone;
@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) WaterNowVC *parent;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)onUpButton:(id)sender;
- (IBAction)onDownButton:(id)sender;
- (IBAction)onStartButton:(id)sender;

@end
