//
//  ProvisionTimezonesListVC.h
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProvisionDateAndTimeManualVC.h"
#import "Protocols.h"

@interface ProvisionTimezonesListVC : UITableViewController <UISearchBarDelegate, SprinklerResponseProtocol>

@property (nonatomic, weak) id<TimeZoneSelectorDelegate> delegate;
@property (assign, nonatomic) BOOL isPartOfWizard;

@end
