//
//  SelectWiFiSecurityOptionVCTableViewController.h
//  Sprinklers
//
//  Created by Fabian Matyas on 01/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProvisionWiFiVC.h"

@interface ProvisionSelectWiFiSecurityOptionVC : UITableViewController

@property (nonatomic, strong) NSIndexPath *selectedIndex;

- (id)initWithDelegate:(ProvisionWiFiVC*)del;
+ (int)indexForSecurityOption:(NSString*)securityOption;

@end
