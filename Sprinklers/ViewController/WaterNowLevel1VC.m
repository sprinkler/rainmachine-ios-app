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
#import "ColoredBackgroundButton.h"

@interface WaterNowLevel1VC ()
{
    NSTimeInterval retryInterval;
    UIColor *greenColor;
    UIColor *redColor;
}

@property (strong, nonatomic) ServerProxy *pollServerProxy;
//@property (strong, nonatomic) ServerProxy *quickRefreshServerProxy; // Used to avoid the 10 seconds delay for UI update. The POST request doesn't return a JSON response and we cannot update the UI immediately.
@property (strong, nonatomic) ServerProxy *postServerProxy; // TODO: rename it to pollServerProxy or something better
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastPollRequestError;
@property (strong, nonatomic) WaterNowVC *parent;
@property (strong, nonatomic) NSTimer *counterTimer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ativityIndicator;

@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *counterLabel;
@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;

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
    
    [self.buttonUp setCustomRMFontWithCode:icon_Up size:90];
    [self.buttonDown setCustomRMFontWithCode:icon_Down size:90];

    greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:YES];
//    self.quickRefreshServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];
    
    self.title = self.waterZone.name;
    self.ativityIndicator.hidden = YES;
    
    // Initialize with a fake but valid value
    self.lastListRefreshDate = [NSDate date];

    [self refreshUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateCounterAndPollState:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopPollRequests];
}

- (void)stopPollRequests
{
    [self.pollServerProxy cancelAllOperations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)refreshUI
{
    BOOL watering = [Utils isZoneWatering:self.waterZone];

    self.counterLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.waterZone.counter watering:watering] intValue] usingOnlyDigits:YES];

    if (watering) {
        self.counterLabel.textColor = redColor;
    } else {
        self.counterLabel.textColor = greenColor;
    }

    if (watering) {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringRedButtonColor];
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringGreenButtonColor];
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    }
}

#pragma - Counter timer

- (void)startCounterTimer
{
    [self stopCounterTimer];
    self.counterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(counterTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)counterTimer:(id)notif
{
    int counter = [self.waterZone.counter intValue] - 1;
    int newCounter = MAX(0, counter);
    self.waterZone.counter = [NSNumber numberWithInt:newCounter];
    self.counterLabel.text = [NSString formattedTime:newCounter usingOnlyDigits:YES];
}

- (void)stopCounterTimer
{
    [self.counterTimer invalidate];
    self.counterTimer = nil;
}

- (void)updateCounterAndPollState:(float)delay
{
    if (/*(self.counterTimer) &&*/ (![Utils isZoneWatering:self.waterZone])) {
        [self stopCounterTimer];
        [self stopPollRequests];
    } else {
//        if (/*(!self.counterTimer) &&*/ ([Utils isZoneWatering:self.waterZone])) {
            [self startCounterTimer];
            [self scheduleNextPollRequest:delay withServerProxy:self.pollServerProxy referenceDate:self.lastListRefreshDate];
//        }
    }
}

#pragma mark - Requests

- (void)requestZoneStateRefreshWithServerProxy:(ServerProxy*)serverProxy
{
    [serverProxy requestWaterActionsForZone:self.waterZone.id];
    
    self.lastListRefreshDate = [NSDate date];
}

- (void)scheduleNextPollRequest:(NSTimeInterval)scheduleInterval withServerProxy:(ServerProxy*)serverProxy referenceDate:(NSDate*)referenceDate
{
    if (serverProxy == self.pollServerProxy) {
        // Clear previously scheduled pollServerProxy requests
        [serverProxy cancelAllOperations];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:referenceDate];
    
    if (t >= scheduleInterval) {
        [self requestZoneStateRefreshWithServerProxy:serverProxy];
    } else {
        [self performSelector:@selector(requestZoneStateRefreshWithServerProxy:) withObject:serverProxy afterDelay:scheduleInterval - t];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
    BOOL showErrorMessage = YES;
    if (serverProxy == self.pollServerProxy) {
        showErrorMessage = NO;
        if (!self.lastPollRequestError) {
            retryInterval = 2 * kWaterNowRefreshTimeInterval;
            showErrorMessage = YES;
        }
        self.lastPollRequestError = error;
    }
    
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:showErrorMessage];

//    if ((serverProxy == self.pollServerProxy) || (serverProxy == self.quickRefreshServerProxy)) {
//        [self updateCounterAndPollState];
//    }

    if (serverProxy == self.pollServerProxy) {
        [self updateCounterAndPollState:retryInterval];

        self.ativityIndicator.hidden = YES;
        
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
    [self.parent handleGeneralSprinklerError:nil showErrorMessage:YES];
    
    if (serverProxy == self.postServerProxy) {
//        [self scheduleNextPollRequest:5 withServerProxy:self.quickRefreshServerProxy];
    } else {
        self.lastPollRequestError = nil;
        
        self.waterZone = data;

        [self updateCounterAndPollState:kWaterNowRefreshTimeInterval];
        
        self.ativityIndicator.hidden = YES;

        [self refreshUI];
    }
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (IBAction)onUpButton:(id)sender {
    BOOL watering = [Utils isZoneWatering:self.waterZone];
    
    int counter = [[Utils fixedZoneCounter:self.waterZone.counter watering:watering] intValue];
    NSNumber *newCounter = [NSNumber numberWithInt:counter + 60];
    self.waterZone.counter = newCounter;
    
    [self refreshUI];
    
    if ([Utils isZoneWatering:self.waterZone]) {
        self.ativityIndicator.hidden = NO;
        [self.postServerProxy toggleWatering:watering onZone:self.waterZone withCounter:newCounter];
    }
}

- (IBAction)onDownButton:(id)sender {
    BOOL watering = [Utils isZoneWatering:self.waterZone];
    
    int counter = [[Utils fixedZoneCounter:self.waterZone.counter watering:watering] intValue];
    // This limiting is done to avoid confusion, because the value 0 is in fact used for both of the following:
    // * the default value of 5:00
    // * to show that a device is stopped
    int minCounterValue = [Utils isZoneWatering:self.waterZone] ? 0 : 60;

    NSNumber *newCounter = [NSNumber numberWithInt:MAX(minCounterValue, counter - 60)];
    self.waterZone.counter = newCounter;
    
    [self refreshUI];
    
    if ([Utils isZoneWatering:self.waterZone]) {
        self.ativityIndicator.hidden = NO;
        [self.postServerProxy toggleWatering:watering onZone:self.waterZone withCounter:newCounter];
    }
    
//    if ([newCounter intValue] == 0) {
//        self.waterZone.state = @"";
//    }
}

- (IBAction)onStartButton:(id)sender {
    BOOL watering = [Utils isZoneWatering:self.waterZone];
    self.ativityIndicator.hidden = NO;
    [self.postServerProxy toggleWatering:!watering onZone:self.waterZone withCounter:self.waterZone.counter];
    [self scheduleNextPollRequest:kWaterNowRefreshTimeInterval withServerProxy:self.pollServerProxy referenceDate:[NSDate date]];
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
