//
//  ProvisionDateAndTimeManualVCTableViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "DiscoveredSprinklers.h"
#import "LocationSetupVC.h"
#import "ProvisionNameSetupVC.h"
#import "BaseModalProvisionVC.h"

@interface ProvisionDateAndTimeManualVC : UITableViewController<SprinklerResponseProtocol>

@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (nonatomic, weak) LocationSetupVC *locationSetupVC;
//@property (nonatomic, weak) BaseNetworkHandlingVC *delegate;
@property (strong, nonatomic) NSString *timeZoneName;
@property (strong, nonatomic) BaseModalProvisionVC *errorHandlingHelper;

- (void)timeZoneSelected:(NSString*)timezone;

@end
