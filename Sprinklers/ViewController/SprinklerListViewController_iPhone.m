//
//  SprinklerListViewController_iPhone.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SprinklerListViewController_iPhone.h"
#import "StorageManager.h"
#import "ServiceManager.h"
#import "DiscoveredSprinklers.h"
#import "UIStrokeLabel.h"
#import "WebPageViewController.h"
#import "SprinklerStaticListViewController_iPhone.h"
#import "SPConstants.h"

@implementation SprinklerListViewController_iPhone

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Sprinkler Discovery";
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButton)];
        self.navigationItem.leftBarButtonItem = refreshButton;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];    
    discoveredSprinklers = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidResignActive) name:@"ApplicationDidResignActive" object:nil];
    
    //pullToRefreshView = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *)self.tableView];
    //pullToRefreshView.delegate = self;
    //[self.tableView addSubview:pullToRefreshView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
    if (!sprinklerWebDisplayed) {
        [self performSelector:@selector(shouldStartBroadcast) withObject:nil afterDelay:0.2];
    } else {
        silentTimer = [NSTimer scheduledTimerWithTimeInterval:refreshTimeout target:self selector:@selector(shouldStartSilentBroadcast) userInfo:nil repeats:YES];
    }
    sprinklerWebDisplayed = NO;
    [_tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[ServiceManager current] stopBroadcast];
    if (silentTimer)
        [silentTimer invalidate];
}

#pragma mark - Actions

- (void)appDidBecomeActive {
    if (self.navigationController.visibleViewController == self) {
        [self shouldStartBroadcast];
    }
}

- (void)appDidResignActive {
    [[ServiceManager current] stopBroadcast];
    if (timer)
        [timer invalidate];
    if (silentTimer)
        [silentTimer invalidate];
    [self hideHud];
    if (alertView)
        [alertView dismissWithClickedButtonIndex:4 animated:YES];
}

- (void)shouldStartBroadcast {
    [self startHud:@"Looking for local sprinklers..."];
    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(shouldStopBroadcast) userInfo:nil repeats:NO];
    [[ServiceManager current] startBroadcastForSprinklers:NO];
}

- (void)shouldStopBroadcast {
    [[ServiceManager current] stopBroadcast];
    discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
    [self hideHud];
    
    [_tableView reloadData];
    if (discoveredSprinklers && discoveredSprinklers.count == 1) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"My RainMachines" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backButton;
        sprinklerWebDisplayed = YES;
        DiscoveredSprinklers *sp = discoveredSprinklers[0];
        WebPageViewController *web = [[WebPageViewController alloc] initWithURL:sp.url];
        web.title = sp.sprinklerName;
        [self.navigationController pushViewController:web animated:YES];
    } else if (discoveredSprinklers == nil || discoveredSprinklers.count == 0) {
        alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"No local sprinklers found." delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"View remote sprinklers", @"Add remote sprinkler", nil];
        [alertView show];
    } else if (discoveredSprinklers.count > 1) {
        silentTimer = [NSTimer scheduledTimerWithTimeInterval:refreshTimeout target:self selector:@selector(shouldStartSilentBroadcast) userInfo:nil repeats:YES];
    }
}

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
    loadingOverlay.hidden = NO;
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    loadingOverlay.hidden = YES;
}

- (void)shouldStartSilentBroadcast {
    [[ServiceManager current] startBroadcastForSprinklers:YES];
    [self performSelector:@selector(refreshList) withObject:nil afterDelay:2.0];
}

- (void)refreshList {
     [pullToRefreshView finishedLoading];
     discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
     [_tableView reloadData];
    
    if (pullToRefresh && (discoveredSprinklers == nil || discoveredSprinklers.count == 0)) {
        alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"No local sprinklers found." delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:@"View remote sprinklers", @"Add remote sprinkler", nil];
        [alertView show];
    }
    
    pullToRefresh = NO;
}

#pragma mark - Pull to Refresh

- (void)refreshButton {
    if (silentTimer)
        [silentTimer invalidate];
    [self shouldStartBroadcast];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    pullToRefresh = YES;
    if (silentTimer)
        [silentTimer invalidate];
    [self shouldStartSilentBroadcast];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [self shouldStartBroadcast];
    }
    
    if (buttonIndex == 1) {
        SprinklerStaticListViewController_iPhone *staticList = [[SprinklerStaticListViewController_iPhone alloc] init];
        [UIView animateWithDuration:0.5 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [self.navigationController pushViewController:staticList animated:NO];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:NO];
        }];
    }
    
    if (buttonIndex == 2) {
        SprinklerStaticListViewController_iPhone *staticList = [[SprinklerStaticListViewController_iPhone alloc] init];
        staticList.shouldDisplayAdd = YES;
        [UIView animateWithDuration:0.5 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [self.navigationController pushViewController:staticList animated:NO];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:NO];
        }];
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 1;
    return discoveredSprinklers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return 44.0f;
    return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    if (indexPath.section == 0) {
        static NSString *CellIdentifier1 = @"Cell1";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.textLabel.text = @"Remote Sprinklers";
        return cell;
    }
    
    if (indexPath.section == 1) {
        static NSString *CellIdentifier2 = @"Cell2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    
        DiscoveredSprinklers *spr = discoveredSprinklers[indexPath.row];
        cell.textLabel.text = spr.sprinklerName;
        cell.detailTextLabel.text = spr.host;
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"My RainMachines" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backButton;
        sprinklerWebDisplayed = YES;
        DiscoveredSprinklers *sp = discoveredSprinklers[indexPath.row];
        WebPageViewController *web = [[WebPageViewController alloc] initWithURL:sp.url];
        web.title = sp.sprinklerName;
        [self.navigationController pushViewController:web animated:YES];
    }
    if (indexPath.section == 0) {
        self.navigationItem.backBarButtonItem = nil;
        SprinklerStaticListViewController_iPhone *staticList = [[SprinklerStaticListViewController_iPhone alloc] init];
        
        [UIView animateWithDuration:0.5 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [self.navigationController pushViewController:staticList animated:NO];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:NO];
        }];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setViewLoading:nil];
    loadingOverlay = nil;
    [super viewDidUnload];
}

@end
