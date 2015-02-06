//
//  DashboardGraphVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 05/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DashboardGraphVC.h"
#import "DashboardVC.h"
#import "GraphTimeInterval.h"
#import "GraphDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphScrollableCell.h"
#import "Additions.h"

#pragma mark -

@interface DashboardGraphVC ()

@property (nonatomic, strong) GraphScrollableCell *graphScrollableHeaderCell;
@property (nonatomic, strong) UIColor *graphsBlueTintColor;

- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphScrollableHeaderCell;

@end

#pragma mark -

@implementation DashboardGraphVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.graphDescriptor.titleAreaDescriptor.title;
    
    [self initializeTimeIntervalsSegmentedControl];
    [self initializeGraphScrollableHeaderCell];
    
    self.tableView.tableHeaderView = self.headerContainerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

- (void)initializeGraphScrollableHeaderCell {
    [self.graphScrollableHeaderCell removeFromSuperview];
    
    self.headerContainerView.frame = CGRectMake(0.0, 0.0, self.tableView.frame.size.width, self.timeIntervalsSegmentedControl.frame.size.height + self.graphDescriptor.totalGraphHeight + 24.0);
    
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
    
    self.tableView.tableHeaderView = nil;
    self.tableView.tableHeaderView = self.headerContainerView;
    
    [self performSelector:@selector(scrollToCurrentDateAfterDelay) withObject:nil afterDelay:0.1];
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
    
    if (indexPath.row == 0) {
        graphOptionCell.textLabel.text = @"Show on Dashboard";
        graphOptionCell.accessoryView = [UISwitch new];
        graphOptionCell.accessoryType = UITableViewCellAccessoryNone;
        ((UISwitch*)graphOptionCell.accessoryView).on = YES;
    }
    else if (indexPath.row == 1) {
        graphOptionCell.textLabel.text = @"Show all Data";
        graphOptionCell.accessoryView = nil;
        graphOptionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return graphOptionCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onChangeTimeInterval:(id)sender {
    self.graphTimeInterval = [GraphTimeInterval graphTimeIntervals][self.timeIntervalsSegmentedControl.selectedSegmentIndex];
    self.graphDescriptor.graphTimeInterval = self.graphTimeInterval;
    
    [self initializeGraphScrollableHeaderCell];
}

@end
