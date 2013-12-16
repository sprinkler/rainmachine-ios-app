//
//  SPWaterNowTableViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCommonProtocols.h"

@class MBProgressHUD;
@class SPServerProxy;

@interface SPWaterNowTableViewController : UITableViewController<SPSprinklerResponseProtocol>
{
  UIColor *switchOnOrangeColor;
  UIColor *switchOnGreenColor;
  NSTimeInterval retryInterval;
}

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) SPServerProxy *serverProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) SPServerProxy *postServerProxy;
@property (strong, nonatomic) NSArray *zones;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;

- (void)toggleWatering:(BOOL)switchValue onZoneWithId:(NSNumber*)theId andCounter:(NSNumber*)counter;

@end
