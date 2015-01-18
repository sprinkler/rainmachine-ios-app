//
//  DashboardVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BVReorderTableView.h"
#import "BaseLevel2ViewController.h"
#import "GraphScrollableCell.h"
#import "Protocols.h"

@class GraphTimeInterval;

@interface DashboardVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate, GraphScrollableCellDelegate, ReorderTableViewDelegate>

@property (nonatomic, strong) GraphTimeInterval *graphTimeInterval;

@property (nonatomic, weak) IBOutlet UISegmentedControl *timeIntervalsSegmentedControl;
@property (nonatomic, weak) IBOutlet UIView *headerSeparatorView;
@property (nonatomic, weak) IBOutlet BVReorderTableView *graphsTableView;

@property (nonatomic, strong) NSString *unitsText;

- (IBAction)onChangeTimeInterval:(id)sender;
- (IBAction)onEditGraphsTable:(id)sender;

@end
