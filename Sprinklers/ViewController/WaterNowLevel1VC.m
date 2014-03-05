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
#import "Additions.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"

@interface WaterNowLevel1VC ()
{
    NSTimeInterval retryInterval;
    BOOL freezeCounter;
}

@property (strong, nonatomic) ServerProxy *pollServerProxy;
//@property (strong, nonatomic) ServerProxy *quickRefreshServerProxy; // Used to avoid the 10 seconds delay for UI update. The POST request doesn't return a JSON response and we cannot update the UI immediately.
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastPollRequestError;
@property (strong, nonatomic) WaterNowVC *parent;
@property (strong, nonatomic) NSTimer *counterTimer;
@property (strong, nonatomic) UIColor *greenColor;
@property (strong, nonatomic) UIColor *redColor;
@property (strong, nonatomic) UIColor *orangeColor;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *startStopActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *initialTimerRequestActivityIndicator;
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
    
    self.greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    self.orangeColor = [UIColor colorWithRed:kWateringOrangeButtonColor[0] green:kWateringOrangeButtonColor[1] blue:kWateringOrangeButtonColor[2] alpha:1];
    self.redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
//    self.quickRefreshServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];

    // Initialize with a fake but valid value
    self.lastListRefreshDate = [NSDate date];
    
    self.title = [Utils fixedZoneName:self.waterZone.name withId:self.waterZone.id];
    
    [self updateStartButtonActiveStateTo:YES];
    
    [self.buttonUp setCustomRMFontWithCode:icon_Up size:self.buttonUp.frame.size.width];
    [self.buttonDown setCustomRMFontWithCode:icon_Down size:self.buttonDown.frame.size.width];

    if ([Utils isZoneIdle:self.waterZone]) {
        self.initialTimerRequestActivityIndicator.hidden = YES;
        self.counterLabel.hidden = NO;
    }
    
    freezeCounter = NO;
    
    [self refreshUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updatePollStateWithDelay:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopPollRequests];
}

#pragma mark - UI

- (void)updateStartButtonActiveStateTo:(BOOL)state
{
    self.startStopActivityIndicator.hidden = state;
    self.startButton.enabled = state;
    self.startButton.alpha = state ? 1 : 0.66;
}

- (void)refreshUI
{
    BOOL isWatering = [Utils isZoneWatering:self.waterZone];
    BOOL isPending = [Utils isZonePending:self.waterZone];
    BOOL isIdle = [Utils isZoneIdle:self.waterZone];

    self.counterLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.waterZone.counter isIdle:isIdle] intValue] usingOnlyDigits:YES];

    self.counterLabel.textColor = isPending ? _orangeColor : _greenColor;

    if (isWatering) {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringRedButtonColor];
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringGreenButtonColor];
        [self.startButton setTitle:isPending ? @"Cancel" : @"Start" forState:UIControlStateNormal];
    }
    
    if (isIdle) {
        self.buttonDown.alpha = 1;
        self.buttonUp.alpha = 1;
        self.buttonDown.enabled = YES;
        self.buttonUp.enabled = YES;
    } else {
        self.buttonDown.alpha = 0.66;
        self.buttonUp.alpha = 0.66;
        self.buttonDown.enabled = NO;
        self.buttonUp.enabled = NO;
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
    if (!freezeCounter) {
        self.counterLabel.text = [NSString formattedTime:newCounter usingOnlyDigits:YES];
    }
}

- (void)stopCounterTimer
{
    [self.counterTimer invalidate];
    self.counterTimer = nil;
}

- (void)updateCounter
{
    self.initialTimerRequestActivityIndicator.hidden = YES;
    self.counterLabel.hidden = NO;
    
    if (![Utils isZoneWatering:self.waterZone]) {
        [self stopCounterTimer];
    } else {
        [self startCounterTimer];
    }
}

- (void)updatePollStateWithDelay:(float)delay
{
    if ([Utils isZoneIdle:self.waterZone]) {
        [self stopPollRequests];
    } else {
        [self scheduleNextPollRequest:delay withServerProxy:self.pollServerProxy referenceDate:self.lastListRefreshDate];
    }
}

#pragma mark - Requests

- (void)stopPollRequests
{
    [self.pollServerProxy cancelAllOperations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)requestZoneStateRefreshWithServerProxy:(ServerProxy*)serverProxy
{
    [serverProxy requestWaterActionsForZone:self.waterZone.id];
    
    self.lastListRefreshDate = [NSDate date];
}

- (void)scheduleNextPollRequest:(NSTimeInterval)scheduleInterval withServerProxy:(ServerProxy*)serverProxy referenceDate:(NSDate*)referenceDate
{
    if (serverProxy == self.pollServerProxy) {
        // Clear previously scheduled pollServerProxy requests
        [self stopPollRequests];
    }
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:referenceDate];
    
    if (t >= scheduleInterval) {
        [self requestZoneStateRefreshWithServerProxy:serverProxy];
    } else {
        [self performSelector:@selector(requestZoneStateRefreshWithServerProxy:) withObject:serverProxy afterDelay:scheduleInterval - t];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
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
        freezeCounter = NO;
        
        [self updateCounter];
        [self updatePollStateWithDelay:retryInterval];

        [self updateStartButtonActiveStateTo:YES];
        
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self.parent handleGeneralSprinklerError:nil showErrorMessage:YES];
    
    if (serverProxy == self.postServerProxy) {
//        [self scheduleNextPollRequest:5 withServerProxy:self.quickRefreshServerProxy];
    } else {
        freezeCounter = NO;
        
        self.lastPollRequestError = nil;
        
        self.waterZone = data;

        [self updateCounter];
        [self updatePollStateWithDelay:kWaterNowRefreshTimeInterval];
        
        [self updateStartButtonActiveStateTo:YES];

        [self refreshUI];
    }
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (IBAction)onUpButton:(id)sender {
    BOOL isIdle = [Utils isZoneIdle:self.waterZone];
    
    if (isIdle) {
        int counter = [[Utils fixedZoneCounter:self.waterZone.counter isIdle:isIdle] intValue];
        int newCounter = MIN(counter + 60, kMaxCounterValue);
        self.waterZone.counter = [NSNumber numberWithInt:newCounter];
        
        [self refreshUI];
    }
}

- (IBAction)onDownButton:(id)sender {
    BOOL isIdle = [Utils isZoneIdle:self.waterZone];
    
    if (isIdle) {
        int counter = [[Utils fixedZoneCounter:self.waterZone.counter isIdle:isIdle] intValue];
        // This limiting is done to avoid confusion, because the value 0 is in fact used for both of the following:
        // * the default value of 5:00
        // * to show that a device is stopped
        int minCounterValue = [Utils isZoneWatering:self.waterZone] ? 0 : 60;

        self.waterZone.counter = [NSNumber numberWithInt:MAX(minCounterValue, counter - 60)];
        
        [self refreshUI];
    }
}

- (IBAction)onStartButton:(id)sender {
    if (![self.postServerProxy toggleWateringOnZone:self.waterZone withCounter:self.waterZone.counter]) {
        // Watering stop request sent. Freeze the counter until next update.
        freezeCounter = YES;
    }

//    [self updateStartButtonActiveStateTo:NO];
//    [self scheduleNextPollRequest:kWaterNowRefreshTimeInterval withServerProxy:self.pollServerProxy referenceDate:[NSDate date]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
