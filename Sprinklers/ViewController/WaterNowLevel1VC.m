//
//  WaterNowLevel1VC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "WaterNowLevel1VC.h"
#import "Constants.h"
#import "+UIButton.h"
#import "WaterNowZone.h"
#import "ServerProxy.h"
#import "Utils.h"
#import "WaterNowVC.h"
#import "WaterNowTimerCell.h"
#import "WaterNowStartCell.h"
#import "Additions.h"

@interface WaterNowLevel1VC ()
{
    NSTimeInterval retryInterval;
    UIColor *greenColor;
    UIColor *redColor;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) WaterNowVC *parent;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WaterNowLevel1VC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];

    [_tableView registerNib:[UINib nibWithNibName:@"WaterNowTimerCell" bundle:nil] forCellReuseIdentifier:@"WaterNowTimerCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"WaterNowStartCell" bundle:nil] forCellReuseIdentifier:@"WaterNowStartCell"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:YES];
    
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

- (void)refreshUI
{
    [self.tableView reloadData];
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
    
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:showErrorMessage];
    
    [self scheduleNextListRefreshRequest:retryInterval];
    
    retryInterval *= 2;
    retryInterval = MIN(retryInterval, 8 * kWaterNowListRefreshTimeInterval);
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
    self.lastScheduleRequestError = nil;
    
    [self.parent handleGeneralSprinklerError:nil showErrorMessage:YES];
    
    self.waterZone = [data objectAtIndex:0];
    [self refreshUI];
    
    if (serverProxy == self.serverProxy) {
        [self scheduleNextListRefreshRequest:kWaterNowListRefreshTimeInterval];
    }
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (IBAction)onUpButton:(id)sender {
    BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];
    
    int counter = [[Utils fixedZoneCounter:self.waterZone.counter] intValue];
    NSNumber *newCounter = [NSNumber numberWithInt:counter + 10];
    self.waterZone.counter = newCounter;
    
    [self refreshUI];
    
    if (watering) {
        [self.postServerProxy toggleWatering:YES onZoneWithId:self.waterZone.id andCounter:newCounter];
    }
}

- (IBAction)onDownButton:(id)sender {
    BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];
    
    int counter = [[Utils fixedZoneCounter:self.waterZone.counter] intValue];
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

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 300;
    }
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL watering = [self.waterZone.state isEqualToString:@"Watering"];
    UITableViewCell *theCell = nil;
    
    if (indexPath.row == 0) {
        
        // TODO: keep the timer cell cached and configure it directly from refreshUI
        static NSString *CellIdentifier = @"WaterNowTimerCell";
        WaterNowTimerCell *cell = (WaterNowTimerCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

        cell.timerLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.waterZone.counter] intValue]];
        [cell.upButton setupWithImage:[UIImage imageNamed:@"button_up"]];
        [cell.downButton setupWithImage:[UIImage imageNamed:@"button_down"]];
        
        if (watering) {
            cell.timerLabel.textColor = greenColor;
        } else {
            cell.timerLabel.textColor = greenColor;
        }
        
        theCell = cell;
    } else {
        static NSString *CellIdentifier = @"WaterNowStartCell";
        WaterNowStartCell *cell = (WaterNowStartCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (watering) {
            [cell.startButton setupAsRoundColouredButton:redColor];
            [cell.startButton setTitle:@"Stop" forState:UIControlStateNormal];
        } else {
            [cell.startButton setupAsRoundColouredButton:greenColor];
            [cell.startButton setTitle:@"Start" forState:UIControlStateNormal];
        }
        
        theCell = cell;
    }
    
    [theCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return theCell;
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
