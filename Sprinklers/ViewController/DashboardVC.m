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
#import "GraphDescriptor.h"
#import "Constants.h"

#pragma mark -

@interface DashboardVC ()

@property (nonatomic, strong) UIColor *graphsBlueTintColor;
@property (nonatomic, strong) UIColor *graphsGraySepratorColor;

- (void)initializeConfiguration;
- (void)initializeUserInterface;
- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphsTableView;

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
    
    [self onChangeTimeInterval:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GraphsManager sharedGraphsManager].presentationViewController = self;
    [[GraphsManager sharedGraphsManager] reloadAllSelectedGraphs];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [GraphsManager sharedGraphsManager].presentationViewController = self;
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
    self.graphsTableView.canReorder = NO;
    self.graphsTableView.draggingViewOpacity = 0.75;
    
    self.graphsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 3.0)];
    self.graphsTableView.tableFooterView.backgroundColor = [UIColor clearColor];
    self.graphsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.graphsTableView.contentInset = UIEdgeInsetsMake(3.0, 0.0, 0.0, 0.0);
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onEditGraphsTable:);
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [GraphsManager sharedGraphsManager].selectedGraphs.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    GraphDescriptor *graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    return graphDescriptor.totalGraphHeight;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *GraphCellIdentifier = @"GraphCell";
    
    GraphCell *graphCell = [tableView dequeueReusableCellWithIdentifier:GraphCellIdentifier];
    graphCell.graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    
    return graphCell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Reorder table view delegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath*)indexPath {
    GraphDescriptor *graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    EmptyGraphDescriptor *emptyGraphDescriptor = [EmptyGraphDescriptor emptyGraphDescriptorWithTotalGraphHeight:graphDescriptor.totalGraphHeight];

    [[GraphsManager sharedGraphsManager] replaceGraphAtIndex:indexPath.row withGraph:emptyGraphDescriptor];
    
    return graphDescriptor;
}

- (void)moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
    [[GraphsManager sharedGraphsManager] moveGraphFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
    [[GraphsManager sharedGraphsManager] replaceGraphAtIndex:indexPath.row withGraph:(GraphDescriptor*)object];
}

#pragma mark - Actions

- (IBAction)onChangeTimeInterval:(id)sender {
    GraphTimeInterval *graphTimeInterval = [GraphTimeInterval graphTimeIntervals][self.timeIntervalsSegmentedControl.selectedSegmentIndex];
    for (GraphDescriptor *graphDescriptor in [GraphsManager sharedGraphsManager].selectedGraphs) {
        graphDescriptor.graphTimeInterval = graphTimeInterval;
    }
}

- (IBAction)onEditGraphsTable:(id)sender {
    BOOL editing = !self.editing;
    
    [self setEditing:editing animated:YES];
    [self.graphsTableView setEditing:editing animated:YES];
    
    self.graphsTableView.canReorder = editing;
}

@end
