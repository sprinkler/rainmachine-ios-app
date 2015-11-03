//
//  DashboardGraphAllDataVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 07/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"

@class GraphDescriptor;

@interface DashboardGraphAllDataVC : BaseLevel2ViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
