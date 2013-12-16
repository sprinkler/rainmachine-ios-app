//
//  SPWaterZoneNowTableViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 14/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPWaterZoneNowTableViewController.h"
#import "SPConstants.h"
#import "+UIButton.h"
#import "SPWaterNowZone.h"
#import "SPServerProxy.h"
#import "SPMainScreenViewController.h"
#import "SPFormatterHelper.h"
#import "SPUtils.h"

@interface SPWaterZoneNowTableViewController ()

@end

@implementation SPWaterZoneNowTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  [self.upButton setupWithImage:[UIImage imageNamed:@"buttonUp"]];
  [self.downButton setupWithImage:[UIImage imageNamed:@"buttonDown"]];

  [self refreshUI];
  // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:NO];
  self.postServerProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:YES];
  
  self.title = self.waterZone.name;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [self requestZoneStateRefresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)refreshUI
{
  self.timerLabel.text = [SPFormatterHelper formattedTime:[[SPUtils fixedZoneCounter:self.waterZone.counter] intValue]];
  BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];

  UIColor *greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
  if (watering) {
    [self.startButton setupAsRoundColouredButton:greenColor];
    self.timerLabel.textColor = greenColor;
    [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
  } else {
    UIColor *redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    [self.startButton setupAsRoundColouredButton:redColor];
    self.timerLabel.textColor = greenColor;
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  cell.backgroundColor = [UIColor clearColor];
  return cell;
}

#pragma mark - Requests

- (void)requestZoneStateRefresh
{
  [self.serverProxy requestWaterActionsForZone:self.waterZone.id];

  self.lastListRefreshDate = [NSDate date];
}

- (void)scheduleNextListRefreshRequest:(NSTimeInterval)scheduleInterval
{
  NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.lastListRefreshDate];
  if (t >= scheduleInterval) {
    [self requestZoneStateRefresh];
  } else {
    [self performSelector:@selector(requestZoneStateRefresh) withObject:nil afterDelay:scheduleInterval - t];
  }
}

#pragma mark - Table view data source

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
  
  [(SPMainScreenViewController*)self.theTabBarController handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:showErrorMessage];
  
  [self scheduleNextListRefreshRequest:retryInterval];
  
  retryInterval *= 2;
  retryInterval = MIN(retryInterval, 8 * kWaterNowListRefreshTimeInterval);
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
  self.lastScheduleRequestError = nil;
  
  [(SPMainScreenViewController*)self.theTabBarController handleGeneralSprinklerError:nil showErrorMessage:YES];
  
  self.waterZone = [data objectAtIndex:0];
  [self refreshUI];

  if (serverProxy == self.serverProxy) {
    [self scheduleNextListRefreshRequest:kWaterNowListRefreshTimeInterval];
  }
}

- (void)loggedOut
{
  [(SPMainScreenViewController*)self.theTabBarController handleLoggedOutSprinklerError];
}

- (IBAction)onUpButton:(id)sender {
  BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];

  int counter = [[SPUtils fixedZoneCounter:self.waterZone.counter] intValue];
  NSNumber *newCounter = [NSNumber numberWithInt:counter + 10];
  self.waterZone.counter = newCounter;

  [self refreshUI];
  
  if (watering) {
    [self.postServerProxy toggleWatering:YES onZoneWithId:self.waterZone.id andCounter:newCounter];
  }
}

- (IBAction)onDownButton:(id)sender {
  BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];

  int counter = [[SPUtils fixedZoneCounter:self.waterZone.counter] intValue];
  // This limiting is done to avoid confusion, because the value 0 is in fact used also for both:
  // * the default value of 5:00
  // * to show that a device is stopped
  NSNumber *newCounter = [NSNumber numberWithInt:MAX(10, counter - 10)];
  self.waterZone.counter = newCounter;

  [self refreshUI];

  if (watering) {
    [self.postServerProxy toggleWatering:YES onZoneWithId:self.waterZone.id andCounter:newCounter];
  }

  if ([newCounter intValue] == 0) {
    self.waterZone.state = @"";
  }
}

- (IBAction)onStartButton:(id)sender {
  BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];
  [self.postServerProxy toggleWatering:!watering onZoneWithId:self.waterZone.id andCounter:self.waterZone.counter];
}

@end
