//
//  DashboardGraphDetailsVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 05/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DashboardGraphDetailsVC.h"
#import "DashboardGraphAllDataVC.h"
#import "DashboardVC.h"
#import "GraphTimeInterval.h"
#import "GraphDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphScrollableCell.h"
#import "GraphsManager.h"
#import "Additions.h"

#define ROW_DASHBOARDGRAPHDETAILS_SHOWONDASHBOARD      0
#define ROW_DASHBOARDGRAPHDETAILS_SHOWALLDATA          1

#pragma mark -

@interface DashboardGraphDetailsVC ()

@property (nonatomic, strong) GraphScrollableCell *graphScrollableHeaderCell;
@property (nonatomic, strong) UIColor *graphsBlueTintColor;

- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphScrollableHeaderCellAnimated:(BOOL)animate;

@end

#pragma mark -

@implementation DashboardGraphDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.graphDescriptor.titleAreaDescriptor.title;
    self.graphDescriptor.dontShowDisabledState = YES;
    self.originalGraphDescriptor.dontShowDisabledState = YES;
    [self.graphDescriptor updateDisabledState];
    
    [self initializeTimeIntervalsSegmentedControl];
    [self initializeGraphScrollableHeaderCellAnimated:NO];
    
    self.tableView.tableHeaderView = self.headerContainerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.originalGraphDescriptor.dontShowDisabledState = NO;
    [self.originalGraphDescriptor updateDisabledState];
}

#pragma mark - Helper methods

- (void)initializeTimeIntervalsSegmentedControl {
    self.timeIntervalsSegmentedControl.tintColor = self.parent.graphsBlueTintColor;
    
    [self.timeIntervalsSegmentedControl removeAllSegments];
    for (GraphTimeInterval *graphTimeInterval in [GraphTimeInterval graphTimeIntervals]) {
        [self.timeIntervalsSegmentedControl insertSegmentWithTitle:graphTimeInterval.name
                                                           atIndex:self.timeIntervalsSegmentedControl.numberOfSegments
                                                          animated:NO];
    }
    
    NSInteger selectedTimeInterval = NSNotFound;
    if (self.graphTimeInterval) selectedTimeInterval = [[GraphTimeInterval graphTimeIntervals] indexOfObject:self.graphTimeInterval];
    if (selectedTimeInterval != NSNotFound) self.timeIntervalsSegmentedControl.selectedSegmentIndex = selectedTimeInterval;
    else self.timeIntervalsSegmentedControl.selectedSegmentIndex = 0;
}

- (void)initializeGraphScrollableHeaderCellAnimated:(BOOL)animate {
    [self.graphScrollableHeaderCell removeFromSuperview];
    
    NSString *graphScrollableCellIdentifier = nil;
    if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 0) graphScrollableCellIdentifier = @"GraphScrollableCellWeek";
    else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 1) graphScrollableCellIdentifier = @"GraphScrollableCellMonth";
    else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 2) graphScrollableCellIdentifier = @"GraphScrollableCellYear";
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:graphScrollableCellIdentifier owner:self options:nil];
    self.graphScrollableHeaderCell = nib.firstObject;
    self.graphScrollableHeaderCell.translatesAutoresizingMaskIntoConstraints = NO;
    self.graphScrollableHeaderCell.graphDescriptor = self.graphDescriptor;
    
    [self.graphContainerView addSubview:self.graphScrollableHeaderCell];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_graphScrollableHeaderCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_graphScrollableHeaderCell)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_graphScrollableHeaderCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_graphScrollableHeaderCell)]];
    } else {
        [self.graphContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_graphScrollableHeaderCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_graphScrollableHeaderCell)]];
        [self.graphContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_graphScrollableHeaderCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_graphScrollableHeaderCell)]];
    }
    
    if (animate) {
        [UIView animateWithDuration:0.2 animations:^() {
            self.headerContainerView.frame = CGRectMake(0.0, 0.0, self.tableView.frame.size.width, self.timeIntervalsSegmentedControl.frame.size.height + self.graphDescriptor.totalGraphHeight + 24.0);
            self.tableView.tableHeaderView = self.headerContainerView;
        }];
    } else {
        self.headerContainerView.frame = CGRectMake(0.0, 0.0, self.tableView.frame.size.width, self.timeIntervalsSegmentedControl.frame.size.height + self.graphDescriptor.totalGraphHeight + 24.0);
        self.tableView.tableHeaderView = nil;
        self.tableView.tableHeaderView = self.headerContainerView;
    }
    
    [self performSelector:@selector(scrollToCurrentDateAfterDelay)
               withObject:nil
               afterDelay:0.01
                  inModes:@[NSRunLoopCommonModes]];
}

- (void)scrollToCurrentDateAfterDelay {
    [self.graphScrollableHeaderCell scrollToCurrentDateAnimated:NO];
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 54.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *GraphOptionCellIdentifier = @"GraphOptionCellIdentifier";
    
    UITableViewCell *graphOptionCell = [tableView dequeueReusableCellWithIdentifier:GraphOptionCellIdentifier];
    if (!graphOptionCell) graphOptionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GraphOptionCellIdentifier];
    
    if (indexPath.row == ROW_DASHBOARDGRAPHDETAILS_SHOWONDASHBOARD) {
        graphOptionCell.textLabel.text = @"Show on Dashboard";
        graphOptionCell.accessoryView = [UISwitch new];
        graphOptionCell.accessoryType = UITableViewCellAccessoryNone;
        graphOptionCell.selectionStyle = (self.graphDescriptor.canDisable ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
        
        ((UISwitch*)graphOptionCell.accessoryView).on = !self.graphDescriptor.isDisabled;
        [(UISwitch*)graphOptionCell.accessoryView addTarget:self action:@selector(onShowOnDashboard:) forControlEvents:UIControlEventValueChanged];
        
        graphOptionCell.textLabel.textColor = (self.graphDescriptor.canDisable ? [UIColor blackColor] : [UIColor lightGrayColor]);
        ((UISwitch*)graphOptionCell.accessoryView).enabled = self.graphDescriptor.canDisable;
    }
    else if (indexPath.row == ROW_DASHBOARDGRAPHDETAILS_SHOWALLDATA) {
        graphOptionCell.textLabel.text = @"Show all Data";
        graphOptionCell.accessoryView = nil;
        graphOptionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        graphOptionCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    return graphOptionCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == ROW_DASHBOARDGRAPHDETAILS_SHOWONDASHBOARD && self.graphDescriptor.canDisable) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *showOnDashboardSwitch = (UISwitch*)cell.accessoryView;
        showOnDashboardSwitch.on = !showOnDashboardSwitch.isOn;
        [self onShowOnDashboard:showOnDashboardSwitch];
    }
    
    else if (indexPath.row == ROW_DASHBOARDGRAPHDETAILS_SHOWALLDATA) {
        DashboardGraphAllDataVC *dashboardGraphAllDataVC = [[DashboardGraphAllDataVC alloc] init];
        dashboardGraphAllDataVC.graphDescriptor = self.graphDescriptor;
        [self.navigationController pushViewController:dashboardGraphAllDataVC animated:YES];
    }
}

#pragma mark - Actions

- (IBAction)onChangeTimeInterval:(id)sender {
    self.graphTimeInterval = [GraphTimeInterval graphTimeIntervals][self.timeIntervalsSegmentedControl.selectedSegmentIndex];
    self.graphDescriptor.graphTimeInterval = self.graphTimeInterval;
    
    [self initializeGraphScrollableHeaderCellAnimated:YES];
}

- (IBAction)onShowOnDashboard:(id)sender {
    UISwitch *showOnDashboardSwitch = (UISwitch*)sender;
    if (showOnDashboardSwitch.isOn) [[GraphsManager sharedGraphsManager] selectGraph:self.graphDescriptor];
    else [[GraphsManager sharedGraphsManager] deselectGraph:self.graphDescriptor];
}

@end
