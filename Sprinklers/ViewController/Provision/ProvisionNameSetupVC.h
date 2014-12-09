//
//  ProvisionNameSetupVCViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 08/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AvailableWiFisVC.h"
#import "DiscoveredSprinklers.h"
#import "Protocols.h"

@interface ProvisionNameSetupVC : UIViewController<SprinklerResponseProtocol>

@property (nonatomic, weak) AvailableWiFisVC *delegate;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;

@end
