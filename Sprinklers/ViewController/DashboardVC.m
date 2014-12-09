//
//  DashboardVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DashboardVC.h"
#import "GraphTimeInterval.h"
#import "GraphCell.h"
#import "GraphsManager.h"
#import "Constants.h"

#pragma mark -

@interface DashboardVC ()

@property (nonatomic, strong) UIColor *graphsBlueTintColor;
@property (nonatomic, strong) UIColor *graphsGraySepratorColor;

- (void)initializeConfiguration;
- (void)initializeUserInterface;
- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphsTableView;

@property (nonatomic, strong) NSMutableArray *graphDescriptors;

@end

#pragma mark -

@implementation DashboardVC

#pragma mark - Initialization

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Dashboard";
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphCell" bundle:nil] forCellReuseIdentifier:@"GraphCell"];
    
    [self initializeConfiguration];
    [self initializeUserInterface];
    
    [[GraphsManager sharedGraphsManager] selectAllGraphs];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)initializeConfiguration {
    self.graphsBlueTintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    self.graphsGraySepratorColor = [UIColor colorWithWhite:0.89 alpha:1.0];
}

- (void)initializeUserInterface {
    self.headerSeparatorView.backgroundColor = self.graphsGraySepratorColor;
    [self initializeTimeIntervalsSegmentedControl];
    [self initializeGraphsTableView];
}

- (void)initializeTimeIntervalsSegmentedControl {
    self.timeIntervalsSegmentedControl.tintColor = self.graphsBlueTintColor;
    
    [self.timeIntervalsSegmentedControl removeAllSegments];
    for (GraphTimeInterval *graphTimeInterval in [GraphTimeInterval graphTimeIntervals]) {
        [self.timeIntervalsSegmentedControl insertSegmentWithTitle:graphTimeInterval.name
                                                           atIndex:self.timeIntervalsSegmentedControl.numberOfSegments
                                                          animated:NO];
    }
    
    NSInteger selectedTimeInterval = NSNotFound;
    if (self.graphTimeInterval) selectedTimeInterval = [[GraphTimeInterval graphTimeIntervals] indexOfObject:self.graphTimeInterval];
    if (selectedTimeInterval != NSNotFound) self.timeIntervalsSegmentedControl.selectedSegmentIndex = selectedTimeInterval;
}

- (void)initializeGraphsTableView {
    self.graphsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.graphsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.graphsTableView.contentInset = UIEdgeInsetsMake(3.0, 0.0, 0.0, 0.0);
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [GraphsManager sharedGraphsManager].selectedGraphs.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 164.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *GraphCellIdentifier = @"GraphCell";
    
    GraphCell *graphCell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
    graphCell.graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    
    return graphCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
