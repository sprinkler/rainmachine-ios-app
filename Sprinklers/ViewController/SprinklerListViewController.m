//
//  SPSprinklerListViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SprinklerListViewController.h"
#import "StorageManager.h"
#import "ServiceManager.h"
#import "DiscoveredSprinklers.h"
#import "UIStrokeLabel.h"
#import "Constants.h"
#import "LoginViewController.h"

@implementation SprinklerListViewController
{
    NSMutableArray *savedSprinklers;
    NSMutableArray *discoveredSprinklers;
    IBOutlet UIView *loadingOverlay;
    MBProgressHUD *hud;
    NSTimer *timer;
    NSTimer *silentTimer;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidResignActive) name:@"ApplicationDidResignActive" object:nil];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
    self.navigationItem.leftBarButtonItem = saveButton;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  
//  [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey],
//  (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey],
//  [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion];
    [self createFooter];
}

- (void)viewWillDisappear:(BOOL)animated {
  [[ServiceManager current] stopBroadcast];
  if (silentTimer)
    [silentTimer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  discoveredSprinklers = [NSMutableArray array];
  savedSprinklers = [NSMutableArray arrayWithArray:[[StorageManager current] getSprinklers]];
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
//  if (!sprinklerWebDisplayed) {
//    [self performSelector:@selector(shouldStartBroadcast) withObject:nil afterDelay:0.2];
//  } else {
//    silentTimer = [NSTimer scheduledTimerWithTimeInterval:refreshTimeout target:self selector:@selector(shouldStartSilentBroadcast) userInfo:nil repeats:YES];
//  }
//  [_tableView reloadData];
}

#pragma mark - UI

- (void)createFooter
{
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
  label.text = [NSString stringWithFormat:@"Version: %@", (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey)];
  label.backgroundColor = [UIColor clearColor];
  label.font = [UIFont systemFontOfSize:13];
  label.textColor = [UIColor grayColor];
//  [label sizeToFit];
  label.textAlignment = NSTextAlignmentCenter;
  self.tableView.tableFooterView = label;
}

#pragma mark - Discovery

- (void)onRefresh:(id)notif
{
  [self shouldStartBroadcast];
}

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
}

#pragma mark - Broadcasting

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

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 0)
    return savedSprinklers.count;
  return discoveredSprinklers.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = nil;
  
  if (indexPath.section == 0) {
    NSString *cellID = @"DeviceDescriptionCellID";
    cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    Sprinkler *spr = savedSprinklers[indexPath.row];
    cell.textLabel.text = spr.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", spr.address];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    UILabel *remoteVSLocalLabel = (UILabel*)[cell viewWithTag:10];

    // TODO: decide upon loca/remote type on runtime
    remoteVSLocalLabel.text = @"remote";
  }
  else if (indexPath.section == 1) {
    if (indexPath.row < [discoveredSprinklers count]) {
      NSString *cellID = @"DeviceFoundCellID";
      cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
      DiscoveredSprinklers *spr = discoveredSprinklers[indexPath.row];
      cell.textLabel.text = spr.sprinklerName;
      cell.detailTextLabel.text = spr.host;
    }
    else {
      NSString *cellID = @"DeviceAddCellID";
      cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    }
    
    return cell;
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Dealloc

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
