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
#import "GraphScrollableCell.h"
#import "GraphsManager.h"
#import "GraphDescriptor.h"
#import "Constants.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface DashboardVC ()

@property (nonatomic, strong) UIColor *graphsBlueTintColor;
@property (nonatomic, strong) UIColor *graphsGraySepratorColor;

- (void)initializeConfiguration;
- (void)initializeUserInterface;
- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphsTableView;

@property (nonatomic, strong) MBProgressHUD *hud;

- (void)startHud:(NSString*)text;
- (void)scrollGraphsToCurrentDateAnimated:(BOOL)animate;

@property (nonatomic, assign) CGPoint globalContentOffset;
@property (nonatomic, assign) BOOL globalContentOffsetSet;

- (void)resetGlobalContentOffset;

@property (nonatomic, assign) BOOL reorderingInProgress;
@property (nonatomic, strong) GraphScrollableCell *emptyGraphScrollableCell;

@end

#pragma mark -

@implementation DashboardVC

#pragma mark - Initialization

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Dashboard";
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"selectedGraphs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"reloadingGraphs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"firstGraphsReloadFinished" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"selectedGraphs"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"reloadingGraphs"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"firstGraphsReloadFinished"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
        if (![GraphsManager sharedGraphsManager].reloadingGraphs) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.hud = nil;
            [self.graphsTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
        }
        if ([keyPath isEqualToString:@"firstGraphsReloadFinished"] && [GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
            [self.graphsTableView reloadData];
            [self performSelector:@selector(scrollToCurrentDateAfterDelay) withObject:nil afterDelay:0.0];
        }
    }
}

- (void)scrollToCurrentDateAfterDelay {
    [self scrollGraphsToCurrentDateAnimated:NO];
    [self resetGlobalContentOffset];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellWeek" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellWeek"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellMonth" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellMonth"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellYear" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellYear"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellEmpty" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellEmpty"];
    
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [GraphsManager sharedGraphsManager].presentationViewController = self;
    [[GraphsManager sharedGraphsManager] reloadAllSelectedGraphs];
    [self startHud:nil];
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
    else self.timeIntervalsSegmentedControl.selectedSegmentIndex = 0;
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

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)scrollGraphsToCurrentDateAnimated:(BOOL)animate {
    for (GraphScrollableCell *cell in self.graphsTableView.visibleCells) {
        [cell scrollToCurrentDateAnimated:animate];
    }
}

- (void)resetGlobalContentOffset {
    GraphScrollableCell *firstCell = self.graphsTableView.visibleCells.firstObject;
    if (firstCell) {
        self.globalContentOffset = firstCell.graphCollectionView.contentOffset;
        self.globalContentOffsetSet = YES;
    }
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return ([GraphsManager sharedGraphsManager].firstGraphsReloadFinished ? [GraphsManager sharedGraphsManager].selectedGraphs.count : 0);
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    GraphDescriptor *graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    return graphDescriptor.totalGraphHeight;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *GraphScrollableCellIdentifierWeek = @"GraphScrollableCellWeek";
    static NSString *GraphScrollableCellIdentifierMonth = @"GraphScrollableCellMonth";
    static NSString *GraphScrollableCellIdentifierYear = @"GraphScrollableCellYear";
    static NSString *GraphScrollableCellIdentifierEmpty = @"GraphScrollableCellEmpty";
    
    GraphDescriptor *graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    GraphScrollableCell *graphScrollableCell = nil;
    
    if ([graphDescriptor isKindOfClass:[EmptyGraphDescriptor class]]) {
        graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierEmpty];
    } else {
        if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 0) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierWeek];
        else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 1) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierMonth];
        else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 2) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierYear];
    }
    
    graphScrollableCell.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, graphDescriptor.totalGraphHeight);
    graphScrollableCell.graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    graphScrollableCell.graphScrollableCellDelegate = self;
    
    if (self.globalContentOffsetSet) {
        [graphScrollableCell scrollToContentOffset:self.globalContentOffset animated:NO];
    }
    
    return graphScrollableCell;
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

- (void)startReordering {
    self.reorderingInProgress = YES;
}

- (void)finishedReordering {
    self.reorderingInProgress = NO;
}

#pragma mark - Graph scrollable cell delegate

- (void)graphScrollableCell:(GraphScrollableCell*)graphScrollableCell didScrollToContentOffset:(CGPoint)contentOffset {
    if (self.reorderingInProgress) return;
    if (contentOffset.x == 0.0) return;
    
    for (GraphScrollableCell *cell in self.graphsTableView.visibleCells) {
        if (cell == graphScrollableCell) continue;
        [cell scrollToContentOffset:contentOffset animated:NO];
        
        self.globalContentOffset = contentOffset;
        self.globalContentOffsetSet = YES;
    }
}

#pragma mark - Actions

- (IBAction)onChangeTimeInterval:(id)sender {
    [self setEditing:NO animated:YES];
    [self.graphsTableView setEditing:NO animated:YES];
    
    self.graphsTableView.canReorder = NO;
    [self.graphsTableView setContentOffset:self.graphsTableView.contentOffset animated:NO];
    
    for (GraphScrollableCell *cell in self.graphsTableView.visibleCells) {
        [cell stopScrolling];
    }
    
    GraphTimeInterval *graphTimeInterval = [GraphTimeInterval graphTimeIntervals][self.timeIntervalsSegmentedControl.selectedSegmentIndex];
    for (GraphDescriptor *graphDescriptor in [GraphsManager sharedGraphsManager].selectedGraphs) {
        graphDescriptor.graphTimeInterval = graphTimeInterval;
    }
    
    [self.graphsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self performSelector:@selector(scrollToCurrentDateAfterDelay) withObject:nil afterDelay:0.1];
}

- (IBAction)onEditGraphsTable:(id)sender {
    BOOL editing = !self.editing;
    
    [self setEditing:editing animated:YES];
    [self.graphsTableView setEditing:editing animated:YES];
    
    self.graphsTableView.canReorder = editing;
}

@end
