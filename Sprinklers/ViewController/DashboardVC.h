//
//  DashboardVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BVReorderTableView.h"
#import "BaseViewController.h"
#import "GraphScrollableCell.h"
#import "Protocols.h"

@class GraphTimeInterval;

@interface DashboardVC : BaseViewController <UITableViewDataSource, UITableViewDelegate, GraphScrollableCellDelegate, ReorderTableViewDelegate, RainDelayPollerDelegate>

@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;

@property (nonatomic, weak) IBOutlet UISegmentedControl *timeIntervalsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIView *headerSeparatorView;
@property (nonatomic, weak) IBOutlet BVReorderTableView *graphsTableView;
@property (nonatomic, weak) IBOutlet UITableView *statusTableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *statusTableViewHeightLayoutConstraint;

@property (nonatomic, strong) UIColor *graphsBlueTintColor;
@property (nonatomic, strong) UIColor *graphsGraySepratorColor;

@property (nonatomic, strong) NSString *unitsText;

- (void)applicationDidEnterInForeground;

- (IBAction)onChangeTimeInterval:(id)sender;
- (IBAction)onEditGraphsTable:(id)sender;

@end
