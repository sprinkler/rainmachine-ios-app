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
#import "CounterHelper.h"

@interface WaterNowLevel1VC ()
{
    NSTimeInterval retryInterval;
    int scheduleIntervalResetCounter;
}

@property (strong, nonatomic) ServerProxy *pollServerProxy;
//@property (strong, nonatomic) ServerProxy *quickRefreshServerProxy; // Used to avoid the 10 seconds delay for UI update. The POST request doesn't return a JSON response and we cannot update the UI immediately.
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastPollRequestError;
@property (strong, nonatomic) UIColor *greenColor;
@property (strong, nonatomic) UIColor *redColor;
@property (strong, nonatomic) UIColor *orangeColor;
@property (strong, nonatomic) CounterHelper *wateringCounterHelper;

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
    
    scheduleIntervalResetCounter = 0;
    self.wateringCounterHelper = [[CounterHelper alloc] initWithDelegate:self interval:1];
    
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
    
    self.title = [Utils fixedZoneName:self.wateringZone.name withId:self.wateringZone.id];
    
    [self updateStartButtonActiveStateTo:YES];
    
    [self.buttonDown setCustomRMFontWithCode:icon_Minus size:self.buttonDown.frame.size.width - 2];
    [self.buttonUp setCustomRMFontWithCode:icon_Plus size:self.buttonUp.frame.size.width - 2];
    
    [self.buttonDown setTitleColor:self.redColor forState:UIControlStateNormal];
    [self.buttonUp setTitleColor:self.greenColor forState:UIControlStateNormal];

    if ([Utils isZoneIdle:self.wateringZone]) {
        self.initialTimerRequestActivityIndicator.hidden = YES;
        self.counterLabel.hidden = NO;
    } else {
        if (self.wateringZone.counter) {
            self.initialTimerRequestActivityIndicator.hidden = YES;
            self.counterLabel.hidden = NO;

            [self.wateringCounterHelper updateCounter];
        } else {
            self.initialTimerRequestActivityIndicator.hidden = NO;
            self.counterLabel.hidden = YES;
        }
    }
    
    [self refreshUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    BOOL isWatering = [Utils isZoneWatering:self.wateringZone];
    BOOL isPending = [Utils isZonePending:self.wateringZone];
    BOOL isIdle = [Utils isZoneIdle:self.wateringZone];

    self.counterLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue] usingOnlyDigits:YES];

    self.counterLabel.textColor = isPending ? _orangeColor : _greenColor;

    if (isWatering) {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringRedButtonColor];
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.startButton setCustomBackgroundColorFromComponents:kWateringGreenButtonColor];
        [self.startButton setTitle:isPending ? @"Cancel" : @"Start" forState:UIControlStateNormal];
    }
    
    NSNumber *fixedCounterValue = [Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle];
    self.buttonDown.enabled = ([fixedCounterValue intValue] > 60);
    self.buttonDown.alpha = self.buttonDown.enabled ? 1 : kButtonInactiveOpacity;
    
    if (isIdle) {
        self.buttonDown.hidden = NO;
        self.buttonUp.hidden = NO;
    } else {
        self.buttonDown.hidden = YES;
        self.buttonUp.hidden = YES;
    }
}

#pragma - Counter timer

- (void)updatePollStateWithDelay:(float)delay
{
    if ([Utils isZoneIdle:self.wateringZone]) {
        [self stopPollRequests];
    } else {
        [self scheduleNextPollRequest:delay withServerProxy:self.pollServerProxy referenceDate:self.lastListRefreshDate];
    }
}

#pragma - WaterNowCounterHelper callbacks

- (int)counterValue
{
    BOOL isIdle = [Utils isZoneIdle:self.wateringZone];
    return [[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue];
}

- (void)setCounterValue:(int)value
{
    self.wateringZone.counter = [NSNumber numberWithInt:value];
    [self refreshCounterLabel:value];
}

- (void)refreshCounterLabel:(int)newCounter
{
    self.counterLabel.text = [NSString formattedTime:newCounter usingOnlyDigits:YES];
}

- (void)showCounterLabel
{
    self.initialTimerRequestActivityIndicator.hidden = YES;
    self.counterLabel.hidden = NO;
}

- (BOOL)isCounteringActive
{
    return [Utils isZoneWatering:self.wateringZone];
}

#pragma mark - Requests

- (void)stopPollRequests
{
    [self.pollServerProxy cancelAllOperations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)requestZoneStateRefreshWithServerProxy:(ServerProxy*)serverProxy
{
    [serverProxy requestWaterActionsForZone:self.wateringZone.id];
    
    self.lastListRefreshDate = [NSDate date];
}

- (void)scheduleNextPollRequest:(NSTimeInterval)scheduleInterval withServerProxy:(ServerProxy*)serverProxy referenceDate:(NSDate*)referenceDate
{
    if (scheduleIntervalResetCounter <= 0) {
        retryInterval = kWaterNowRefreshTimeInterval;
    } else {
        scheduleIntervalResetCounter--;
    }
    
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
    
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:showErrorMessage];

//    if ((serverProxy == self.pollServerProxy) || (serverProxy == self.quickRefreshServerProxy)) {
//        [self updateCounterAndPollState];
//    }

    if (serverProxy == self.pollServerProxy) {
        [self.wateringCounterHelper updateCounter];
        [self updatePollStateWithDelay:retryInterval];

        [self updateStartButtonActiveStateTo:YES];
        
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self.parent handleSprinklerNetworkError:nil showErrorMessage:YES];
    
    if (serverProxy == self.postServerProxy) {
//        [self scheduleNextPollRequest:5 withServerProxy:self.quickRefreshServerProxy];
    } else {
        self.lastPollRequestError = nil;
        
        self.wateringZone = data;

        [self.wateringCounterHelper updateCounter];
        [self updatePollStateWithDelay:retryInterval];
        
        [self updateStartButtonActiveStateTo:YES];

        [self refreshUI];
    }
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (IBAction)onUpButton:(id)sender {
    BOOL isIdle = [Utils isZoneIdle:self.wateringZone];
    
    if (isIdle) {
        int counter = [[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue];
        int newCounter = MIN(counter + 60, kMaxCounterValue);
        self.wateringZone.counter = [NSNumber numberWithInt:newCounter];
    
        [self refreshUI];
    }
}

- (IBAction)onDownButton:(id)sender {
    BOOL isIdle = [Utils isZoneIdle:self.wateringZone];
    
    if (isIdle) {
        int counter = [[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue];
        // This limiting is done to avoid confusion, because the value 0 is in fact used for both of the following:
        // * the default value of 5:00
        // * to show that a device is stopped
        int minCounterValue = [Utils isZoneWatering:self.wateringZone] ? 0 : 60;

        self.wateringZone.counter = [NSNumber numberWithInt:MAX(minCounterValue, counter - 60)];

        [self refreshUI];
    }
}

- (IBAction)onStartButton:(id)sender {
    BOOL startRequest = [self.postServerProxy toggleWateringOnZone:self.wateringZone withCounter:self.wateringZone.counter];
    if (!startRequest) {
        // Watering stop request sent. Freeze the counter until next update.
        [self.wateringCounterHelper stopCounterTimer];
    }
    
    if (startRequest) {
        [self.parent userStartedZone:self.wateringZone];
        [self.parent addZoneToStateChangeObserver:self.wateringZone];
        self.parent.delayedInitialListRefresh = YES;
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.parent userStoppedZone:self.wateringZone];
        [self.parent removeZoneFromStateChangeObserver:self.wateringZone];
        [self updateStartButtonActiveStateTo:NO];

        // Poll more often for a couple of times after a user action
        scheduleIntervalResetCounter = 3;
        retryInterval = kWaterNowRefreshTimeInterval_AfterUserAction;
        
        [self scheduleNextPollRequest:retryInterval withServerProxy:self.pollServerProxy referenceDate:[NSDate date]];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
