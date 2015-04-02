//
//  DashboardVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DashboardVC.h"
#import "DashboardGraphDetailsVC.h"
#import "GraphTimeInterval.h"
#import "GraphCell.h"
#import "GraphScrollableCell.h"
#import "GraphsManager.h"
#import "GraphDescriptor.h"
#import "Constants.h"
#import "Additions.h"
#import "HomeScreenDataSourceCell.h"
#import "StorageManager.h"
#import "UpdateManager.h"
#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "WeatherData.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface DashboardVC ()

- (void)initializeConfiguration;
- (void)initializeUserInterface;
- (void)initializeTimeIntervalsSegmentedControl;
- (void)initializeGraphsTableView;

@property (nonatomic, strong) MBProgressHUD *hud;

- (void)startHud:(NSString*)text;
- (void)scrollGraphsToCurrentDateAnimated:(BOOL)animate;
- (void)scrollToGlobalContentOffsetAnimated:(BOOL)animate;

@property (nonatomic, assign) CGPoint globalContentOffset;
@property (nonatomic, assign) BOOL globalContentOffsetSet;

- (void)resetGlobalContentOffset;

@property (nonatomic, assign) BOOL reorderingInProgress;
@property (nonatomic, strong) GraphScrollableCell *emptyGraphScrollableCell;
@property (nonatomic, strong) RainDelayPoller *rainDelayPoller;

@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL doNotRefreshGraphsWhenBecomesVisible;

- (void)refreshGraphs;

@end

#pragma mark -

@implementation DashboardVC

#pragma mark - Initialization

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.title = @"Dashboard";
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"availableGraphs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"selectedGraphs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"reloadingGraphs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"firstGraphsReloadFinished" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"availableGraphs"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"selectedGraphs"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"reloadingGraphs"];
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"firstGraphsReloadFinished"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if ([GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
        if (![GraphsManager sharedGraphsManager].reloadingGraphs) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.hud = nil;
            [self.statusTableView reloadData];
        }
        if ([keyPath isEqualToString:@"firstGraphsReloadFinished"] && [GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
            [self performSelector:@selector(scrollToCurrentDateAfterDelay) withObject:nil afterDelay:0.0 inModes:@[NSRunLoopCommonModes]];
        }
    }
    [self.graphsTableView reloadData];
}

- (void)scrollToCurrentDateAfterDelay {
    [self scrollGraphsToCurrentDateAnimated:NO];
    [self resetGlobalContentOffset];
}

- (void)scrollToGlobalContentOffsetAfterDelay {
    [self scrollToGlobalContentOffsetAnimated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellWeek" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellWeek"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellMonth" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellMonth"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellYear" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellYear"];
    [self.graphsTableView registerNib:[UINib nibWithNibName:@"GraphScrollableCellEmpty" bundle:nil] forCellReuseIdentifier:@"GraphScrollableCellEmpty"];
    
    [self.statusTableView registerNib:[UINib nibWithNibName:@"HomeDataSourceCell" bundle:nil] forCellReuseIdentifier:@"HomeDataSourceCell"];
    
    [self initializeConfiguration];
    [self initializeUserInterface];
    
    [self onChangeTimeInterval:nil];
    
    self.rainDelayPoller = [[RainDelayPoller alloc] initWithDelegate:self];
    [self refreshStatus];
    
    if ([StorageManager current].currentSprinkler) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.updateManager poll];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotSupported:) name:kDeviceNotSupported object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GraphsManager sharedGraphsManager].presentationViewController = self;
    [self.graphsTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.isVisible = YES;
    
    if (!self.doNotRefreshGraphsWhenBecomesVisible) [self refreshGraphs];
    self.doNotRefreshGraphsWhenBecomesVisible = NO;
    
    [self.rainDelayPoller scheduleNextPoll:0];
    [self refreshStatus];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.isVisible = NO;
    
    [self.rainDelayPoller stopPollRequests];
    [[GraphsManager sharedGraphsManager] cancel];
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

- (void)scrollToGlobalContentOffsetAnimated:(BOOL)animate {
    for (GraphScrollableCell *cell in self.graphsTableView.visibleCells) {
        [cell scrollToContentOffset:self.globalContentOffset animated:animate];
    }
}

- (void)resetGlobalContentOffset {
    GraphScrollableCell *firstCell = self.graphsTableView.visibleCells.firstObject;
    if (firstCell) {
        self.globalContentOffset = firstCell.graphCollectionView.contentOffset;
        self.globalContentOffsetSet = YES;
    }
}

#pragma mark - Rain delay

- (void)deviceNotSupported:(id)object {
    [[GraphsManager sharedGraphsManager] cancel];
    [self.rainDelayPoller stopPollRequests];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)setRainDelay {
    [self hideRainDelayActivityIndicator:NO];
    [self.rainDelayPoller setRainDelay];
}

- (void)hideRainDelayActivityIndicator:(BOOL)hide {
    HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.setRainDelayActivityIndicator.hidden = hide;
}

- (void)rainDelayResponseReceived {
    [self refreshStatus];
}

- (void)hideHUD {
    if (self.hud) return;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)refreshStatus {
    [self setupRainDelayMode:[self.rainDelayPoller rainDelayMode]];
    [self.statusTableView reloadData];
}

- (void)setupRainDelayMode:(BOOL)rainDelayMode {
    self.statusTableViewHeightLayoutConstraint.constant = (rainDelayMode ? 54.0 : 0.0);
    self.statusTableView.hidden = !rainDelayMode;
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_ResumeRainDelay) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            [self setRainDelay];
        }
    } else {
        [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    }
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.statusTableView) return 1;
    if ([GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
        if (!self.editing) return [GraphsManager sharedGraphsManager].selectedGraphs.count;
        return [GraphsManager sharedGraphsManager].availableGraphs.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (tableView == self.statusTableView) return 54.0;

    GraphDescriptor *graphDescriptor = nil;
    if (!self.editing) graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    else graphDescriptor = [GraphsManager sharedGraphsManager].availableGraphs[indexPath.row];
    
    return graphDescriptor.totalGraphHeight;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (tableView == self.statusTableView) {
        static NSString *HomeDataSourceCellIdentifier = @"HomeDataSourceCell";
        
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:HomeDataSourceCellIdentifier forIndexPath:indexPath];
        
        if ([self.rainDelayPoller rainDelayMode]) {
            [cell setRainDelayUITo:YES withValue:[self.rainDelayPoller.rainDelayData.delayCounter intValue]];
        } else {
            [cell setRainDelayUITo:NO withValue:0];
        }
        
        return cell;
    }
    
    static NSString *GraphScrollableCellIdentifierWeek = @"GraphScrollableCellWeek";
    static NSString *GraphScrollableCellIdentifierMonth = @"GraphScrollableCellMonth";
    static NSString *GraphScrollableCellIdentifierYear = @"GraphScrollableCellYear";
    static NSString *GraphScrollableCellIdentifierEmpty = @"GraphScrollableCellEmpty";
    
    GraphDescriptor *graphDescriptor = nil;
    if (!self.editing) graphDescriptor = [GraphsManager sharedGraphsManager].selectedGraphs[indexPath.row];
    else graphDescriptor = [GraphsManager sharedGraphsManager].availableGraphs[indexPath.row];
    
    GraphScrollableCell *graphScrollableCell = nil;
    
    if ([graphDescriptor isKindOfClass:[EmptyGraphDescriptor class]]) {
        graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierEmpty];
    } else {
        if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 0) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierWeek];
        else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 1) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierMonth];
        else if (self.timeIntervalsSegmentedControl.selectedSegmentIndex == 2) graphScrollableCell = [tableView dequeueReusableCellWithIdentifier:GraphScrollableCellIdentifierYear];
    }
    
    graphScrollableCell.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, graphDescriptor.totalGraphHeight);
    graphScrollableCell.graphDescriptor = graphDescriptor;
    graphScrollableCell.graphScrollableCellDelegate = self;
    
    if (self.globalContentOffsetSet) [graphScrollableCell scrollToContentOffsetInLayoutSubviews:self.globalContentOffset];
    
    return graphScrollableCell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.statusTableView) {
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:indexPath];
        if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Resume sprinkler operation?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Resume", nil];
            alertView.tag = kAlertView_ResumeRainDelay;
            [alertView show];
        }
    }
}

#pragma mark - Reorder table view delegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath*)indexPath {
    GraphDescriptor *graphDescriptor = [GraphsManager sharedGraphsManager].availableGraphs[indexPath.row];
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
    [self.graphsTableView reloadData];
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

- (void)graphScrollableCellTapped:(GraphScrollableCell*)graphScrollableCell {
    GraphDescriptor *graphDescriptor = graphScrollableCell.graphDescriptor;
    
    DashboardGraphDetailsVC *dashboardGraphDetailsVC = [[DashboardGraphDetailsVC alloc] init];
    dashboardGraphDetailsVC.graphDescriptor = [graphDescriptor copy];
    dashboardGraphDetailsVC.graphDescriptor.isDisabled = NO;
    dashboardGraphDetailsVC.isGraphDisabledOnDashboard = graphDescriptor.isDisabled;
    dashboardGraphDetailsVC.graphTimeInterval = self.graphTimeInterval;
    dashboardGraphDetailsVC.parent = self;
    
    self.doNotRefreshGraphsWhenBecomesVisible = YES;
    
    [self.navigationController pushViewController:dashboardGraphDetailsVC animated:YES];
}

#pragma mark - Actions

- (void)applicationDidEnterInForeground {
    self.doNotRefreshGraphsWhenBecomesVisible = NO;
    [self refreshGraphs];
}

- (void)refreshGraphs {
    if (!self.isVisible) return;
    if ([GraphsManager sharedGraphsManager].firstGraphsReloadFinished) {
        [GraphsManager sharedGraphsManager].presentationViewController = self;
        [[GraphsManager sharedGraphsManager] reloadAllSelectedGraphs];
        [self startHud:nil];
    } else {
        [self startHud:nil];
    }
}

- (IBAction)onChangeTimeInterval:(id)sender {
    [self setEditing:NO animated:YES];
    [self.graphsTableView setEditing:NO animated:YES];
    
    self.graphsTableView.canReorder = NO;
    [self.graphsTableView setContentOffset:self.graphsTableView.contentOffset animated:NO];
    
    for (GraphScrollableCell *cell in self.graphsTableView.visibleCells) {
        [cell stopScrolling];
    }
    
    self.graphTimeInterval = [GraphTimeInterval graphTimeIntervals][self.timeIntervalsSegmentedControl.selectedSegmentIndex];
    for (GraphDescriptor *graphDescriptor in [GraphsManager sharedGraphsManager].selectedGraphs) {
        graphDescriptor.graphTimeInterval = self.graphTimeInterval;
    }
    
    if (!sender) [self.graphsTableView reloadData];
    else [self.graphsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    [self performSelector:@selector(scrollToCurrentDateAfterDelay) withObject:nil afterDelay:0.1 inModes:@[NSRunLoopCommonModes]];
}

- (IBAction)onEditGraphsTable:(id)sender {
    BOOL editing = !self.editing;
    
    [self setEditing:editing animated:YES];
    [self.graphsTableView setEditing:editing animated:YES];
    
    self.graphsTableView.canReorder = editing;
    
    if ([GraphsManager sharedGraphsManager].selectedGraphs.count == [GraphsManager sharedGraphsManager].availableGraphs.count) {
        [self.graphsTableView reloadData];
    } else {
        [self.graphsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self performSelector:@selector(scrollToGlobalContentOffsetAfterDelay) withObject:nil afterDelay:0.1 inModes:@[NSRunLoopCommonModes]];
}

@end
