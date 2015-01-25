//
//  ProvisionTimezonesListVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProvisionDateAndTimeManualVC.h"

@interface ProvisionTimezonesListVC : UITableViewController<UISearchBarDelegate>

@property (nonatomic, weak) ProvisionDateAndTimeManualVC *delegate;

@end
