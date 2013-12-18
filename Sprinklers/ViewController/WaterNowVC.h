//
//  WaterNowVC.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "SPCommonProtocols.h"

@class MBProgressHUD;
@class SPServerProxy;

@interface WaterNowVC : BaseViewController<SPSprinklerResponseProtocol>
{
    UIColor *switchOnOrangeColor;
    UIColor *switchOnGreenColor;
    NSTimeInterval retryInterval;
}

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) SPServerProxy *serverProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) SPServerProxy *postServerProxy;
@property (strong, nonatomic) NSArray *zones;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)toggleWatering:(BOOL)switchValue onZoneWithId:(NSNumber*)theId andCounter:(NSNumber*)counter;

@end
