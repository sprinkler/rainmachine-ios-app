//
//  SPWaterNowTableViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPWaterNowTableViewController.h"
#import "SPServerProxy.h"
#import "SPConstants.h"
#import "SPWaterNowZone.h"
#import "SPMainScreenViewController.h"
#import "MBProgressHUD.h"
#import "SPWaterZoneListCell.h"
#import "SPZoneProperty.h"
#import "SPWaterZoneNowTableViewController.h"
#import "SPFormatterHelper.h"
#import "SPStartStopWatering.h"
#import "SPUtils.h"

@interface SPWaterNowTableViewController ()

@end

@implementation SPWaterNowTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    UIEdgeInsets inset = {self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, 0, 0, 0};
    [self.tableView setContentInset:inset];
  }
  
  switchOnGreenColor = [UIColor colorWithRed:70 / 255.0 green:225 / 255.0 blue:96 / 255.0 alpha:1];
  switchOnOrangeColor = [UIColor colorWithRed:255 / 255.0 green:101 / 255.0 blue:0 / 255.0 alpha:1];

  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop All" style:UIBarButtonItemStylePlain target:self action:@selector(stopAll)];
  self.navigationItem.leftBarButtonItem = backButton;

  self.serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:NO];
  self.postServerProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:YES];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  [(SPMainScreenViewController*)self.tabBarController setNavBarColor:[UIColor colorWithRed:kBarBlueColor[0] green:kBarBlueColor[1] blue:kBarBlueColor[2] alpha:1]];
  
  [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:YES]];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
  [(SPMainScreenViewController*)self.tabBarController setNavBarColor:nil];
}

- (void)startHud:(NSString *)text {
  self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  self.hud.labelText = text;
  
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    // Correct hud frame
    CGRect f = self.hud.frame;
    f.origin.y -= self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    self.hud.frame = f;
  }
}

#pragma mark - Requests

- (void)requestListRefreshWithShowingHud:(NSNumber*)showHud
{
  [self.serverProxy requestWaterNowZoneList];
  
  self.lastListRefreshDate = [NSDate date];
  
  if ([showHud boolValue]) {
    [self startHud:@"Receiving data..."];
  }
}

- (void)scheduleNextListRefreshRequest:(NSTimeInterval)scheduleInterval
{
  NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.lastListRefreshDate];
  if (t >= scheduleInterval) {
    [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:NO]];
  } else {
    [self performSelector:@selector(requestListRefreshWithShowingHud:) withObject:[NSNumber numberWithBool:NO] afterDelay:scheduleInterval - t];
  }
}

- (void)stopAll
{
  for (SPWaterNowZone *zone in self.zones) {
    BOOL watering = [zone.state isEqualToString:@"Watering"];
    if (watering) {
      [self toggleWatering:!watering onZoneWithId:zone.id andCounter:zone.counter];
    }
  }
}

#pragma mark - Alert view
- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  self.alertView = nil;
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
  BOOL showErrorMessage = YES;
  if (serverProxy == self.serverProxy) {
    showErrorMessage = NO;
    if (!self.lastScheduleRequestError) {
      retryInterval = 2 * kWaterNowListRefreshTimeInterval;
      showErrorMessage = YES;
    }
    self.lastScheduleRequestError = error;
  }
  
  [MBProgressHUD hideHUDForView:self.view animated:YES];
  
  [(SPMainScreenViewController*)self.tabBarController handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:showErrorMessage];

  [self scheduleNextListRefreshRequest:retryInterval];

  retryInterval *= 2;
  retryInterval = MIN(retryInterval, 8 * kWaterNowListRefreshTimeInterval);
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
  self.lastScheduleRequestError = nil;

  [MBProgressHUD hideHUDForView:self.view animated:YES];
  
  [(SPMainScreenViewController*)self.tabBarController handleGeneralSprinklerError:nil showErrorMessage:YES];
  
  self.zones = [self filteredZones:data];
  [self.tableView reloadData];

  if (serverProxy == self.serverProxy) {
    [self scheduleNextListRefreshRequest:kWaterNowListRefreshTimeInterval];
  }
}

- (void)loggedOut
{
  [MBProgressHUD hideHUDForView:self.view animated:YES];
  
  [(SPMainScreenViewController*)self.tabBarController handleLoggedOutSprinklerError];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.zones count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"WaterZoneListCell";
  SPWaterZoneListCell *cell = (SPWaterZoneListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  
  SPWaterNowZone *waterNowZone = [self.zones objectAtIndex:indexPath.row];
  BOOL pending = [waterNowZone.state isEqualToString:@"Pending"];
  BOOL watering = [waterNowZone.state isEqualToString:@"Watering"];
//  BOOL unkownState = (!pending) && (!watering);
  
  cell.delegate = self;
  cell.id = waterNowZone.id;
  cell.counter = waterNowZone.counter;
  
  cell.zoneNameLabel.text = waterNowZone.name;
  cell.descriptionLabel.text = waterNowZone.type;
  cell.onOffSwitch.on = watering || pending;
  
  cell.onOffSwitch.onTintColor = pending ? switchOnOrangeColor : (watering ? switchOnGreenColor : [UIColor grayColor]);
  cell.timeLabel.textColor = cell.onOffSwitch.onTintColor;
  
  cell.timeLabel.text = [SPFormatterHelper formattedTime:[[SPUtils fixedZoneCounter:waterNowZone.counter] intValue]];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  // Get the new view controller using [segue destinationViewController].
  // Pass the selected object to the new view controller.
  UIViewController *destViewController = [segue destinationViewController];
  SPWaterZoneNowTableViewController *waterZoneNowViewController = (SPWaterZoneNowTableViewController*)destViewController;
  waterZoneNowViewController.theTabBarController = (SPMainScreenViewController*)self.tabBarController;
  SPWaterNowZone *waterZone = [self.zones objectAtIndex:[self.tableView indexPathForSelectedRow].row];
  waterZoneNowViewController.waterZone = waterZone;
}

#pragma mark - Backend

- (NSArray*)filteredZones:(NSArray*)zones
{
  NSMutableArray *rez = [NSMutableArray array];
  for (SPWaterNowZone *zone in zones) {
    // Skip the Master Valve
    if ([zone.id intValue] != 1) {
      [rez addObject:zone];
    }
  }
  return rez;
}

#pragma mark - Table View Cell callback

- (void)toggleWatering:(BOOL)switchValue onZoneWithId:(NSNumber*)theId andCounter:(NSNumber*)counter
{
  [self.postServerProxy toggleWatering:switchValue onZoneWithId:theId andCounter:counter];
}

@end
