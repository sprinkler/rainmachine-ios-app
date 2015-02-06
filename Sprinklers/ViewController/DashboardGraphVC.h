//
//  DashboardGraphVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 05/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"

@class GraphDescriptor;
@class GraphTimeInterval;
@class DashboardVC;

@interface DashboardGraphVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;
@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;
@property (nonatomic, weak) DashboardVC *parent;

@property (nonatomic, strong) IBOutlet UIView *headerContainerView;
@property (nonatomic, weak) IBOutlet UIView *graphContainerView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *timeIntervalsSegmentedControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)onChangeTimeInterval:(id)sender;

@end
