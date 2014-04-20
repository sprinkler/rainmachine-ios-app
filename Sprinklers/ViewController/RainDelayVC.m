//
//  RainDelayVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainDelayVC.h"
#import "Additions.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "Utils.h"
#import "ServerResponse.h"
#import "RainDelay.h"
#import "SettingsVC.h"

const int kOneDayInSeconds = 24 * 60 * 60;

@interface RainDelayVC ()
{
    BOOL resumeMode;
}

@property (strong, nonatomic) IBOutlet UILabel *labelDays;
@property (strong, nonatomic) IBOutlet UILabel *labelHours;
@property (strong, nonatomic) IBOutlet UILabel *labelMinutes;
@property (strong, nonatomic) IBOutlet UILabel *labelHours_0Days;
@property (strong, nonatomic) IBOutlet UILabel *labelMinutes_0Days;
@property (weak, nonatomic) IBOutlet UILabel *labelCounter;

@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSety;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) RainDelay *rainDelayData;
@property (strong, nonatomic) NSDate *lastPollDate;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rainDelaySetActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *initialRequestActivityIndicator;

//@property (strong, nonatomic) NSTimer *counterTimer; // Useful if seconds are to be shown too

@end

@implementation RainDelayVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Delay";
        self.rainDelayData = [RainDelay new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    resumeMode = NO;
    self.lastPollDate = [NSDate date];

    [self.buttonUp setCustomRMFontWithCode:icon_Plus size:self.buttonUp.frame.size.width - 2];
    [self.buttonDown setCustomRMFontWithCode:icon_Minus size:self.buttonUp.frame.size.width - 2];

    self.labelCounter.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    UIColor *greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    UIColor *redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    
    [self.buttonDown setTitleColor:redColor forState:UIControlStateNormal];
    [self.buttonUp setTitleColor:greenColor forState:UIControlStateNormal];
    
    [self.labelDays setTextColor:greenColor];
    [self.labelHours setTextColor:greenColor];
    [self.labelMinutes setTextColor:greenColor];
    [self.labelHours_0Days setTextColor:greenColor];
    [self.labelMinutes_0Days setTextColor:greenColor];
    
    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    
    [self.pollServerProxy getRainDelay];
    
    [self updateStartButtonActiveStateTo:NO];
    [self hideUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self scheduleNextPollRequest:kRainDelayRefreshTimeInterval withServerProxy:self.pollServerProxy referenceDate:self.lastPollDate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopPollRequests];
}

- (void)hideUI
{
    self.initialRequestActivityIndicator.hidden = NO;
    self.rainDelaySetActivityIndicator.hidden = YES;

    self.buttonSety.hidden = YES;
    
    self.buttonUp.hidden = YES;
    self.buttonDown.hidden = YES;
    
    self.labelDays.hidden = YES;
    self.labelHours.hidden = YES;
    self.labelMinutes.hidden = YES;
    self.labelHours_0Days.hidden = YES;
    self.labelMinutes_0Days.hidden = YES;
    
    self.labelCounter.hidden = YES;
}

- (void)updateStartButtonActiveStateTo:(BOOL)state
{
    self.rainDelaySetActivityIndicator.hidden = state;
    self.buttonSety.enabled = state;
    self.buttonSety.alpha = state ? 1 : 0.66;
}

- (void)refreshUI
{
    self.initialRequestActivityIndicator.hidden = YES;
    self.buttonSety.hidden = NO;

    [self.buttonSety setCustomBackgroundColorFromComponents:resumeMode ? kWateringRedButtonColor : kWateringGreenButtonColor];
    [self.buttonSety setTitle:resumeMode ? @"Resume" : @"Delay" forState:UIControlStateNormal];
    
    self.buttonDown.enabled = ([self.rainDelayData.rainDelay intValue] > 1);
    
    self.buttonUp.alpha = self.buttonUp.enabled ? 1 : kButtonInactiveOpacity;
    self.buttonDown.alpha = self.buttonDown.enabled ? 1 : kButtonInactiveOpacity;
    
    self.buttonUp.hidden = resumeMode;
    self.buttonDown.hidden = resumeMode;
    
    self.labelCounter.hidden = resumeMode;
    
    [self refreshCounterUI];
}

- (void)refreshCounterUI
{
    if (resumeMode) {
        assert(_rainDelayData);
        int m = ([_rainDelayData.delayCounter intValue] / 60) % 60;
        int h = ([_rainDelayData.delayCounter intValue] / (60 * 60)) % 24;
        int d = ([_rainDelayData.delayCounter intValue] / (60 * 60)) / 24;
        if (d == 0) {
            if (h == 0) {
                // Consider 'labelHours' to be the minutes label
                self.labelHours.text = [NSString stringWithFormat:@"%d minutes", m];

                self.labelDays.hidden = YES;
                self.labelHours.hidden = NO;
                self.labelMinutes.hidden = YES;
                self.labelHours_0Days.hidden = YES;
                self.labelMinutes_0Days.hidden = YES;
            } else {
                self.labelHours_0Days.text = [NSString stringWithFormat:@"%d hours", h];
                self.labelMinutes_0Days.text = [NSString stringWithFormat:@"%d minutes", m];
                
                self.labelDays.hidden = YES;
                self.labelHours.hidden = YES;
                self.labelMinutes.hidden = YES;
                self.labelHours_0Days.hidden = NO;
                self.labelMinutes_0Days.hidden = NO;
            }
        } else {
            self.labelDays.text = [NSString stringWithFormat:@"%d day%@", d, (d == 1) ? @"" : @"s"];
            self.labelHours.text = [NSString stringWithFormat:@"%d hours", h];
            self.labelMinutes.text = [NSString stringWithFormat:@"%d minutes", m];
            
            self.labelDays.hidden = NO;
            self.labelHours.hidden = NO;
            self.labelMinutes.hidden = NO;
            self.labelHours_0Days.hidden = YES;
            self.labelMinutes_0Days.hidden = YES;
        }
    } else {
        int d = [_rainDelayData.rainDelay intValue];
        if (d == 0) {
            d = 1;
        }
        self.labelCounter.text = [NSString stringWithFormat:@"%d day%@", d, (d == 1) ? @"" : @"s"];
    }
}

#pragma mark - Actions

- (IBAction)up:(id)sender {
    self.rainDelayData.rainDelay = [NSNumber numberWithInt:[_rainDelayData.rainDelay intValue] + 1];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)down:(id)sender {
    self.rainDelayData.rainDelay = [NSNumber numberWithInt:MAX(0, [_rainDelayData.rainDelay intValue] - 1)];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)set:(id)sender {
    if (resumeMode) {
        [self updateStartButtonActiveStateTo:NO];
        [self.postServerProxy setRainDelay:@0];
    } else {
        [self updateStartButtonActiveStateTo:NO];
        [self.postServerProxy setRainDelay:_rainDelayData.rainDelay];
    }
}

#pragma mark - Requests

- (void)stopPollRequests
{
    [self.pollServerProxy cancelAllOperations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)requestStateRefreshWithServerProxy:(ServerProxy*)serverProxy
{
    [serverProxy getRainDelay];

    self.lastPollDate = [NSDate date];
}

- (void)scheduleNextPollRequest:(NSTimeInterval)scheduleInterval withServerProxy:(ServerProxy*)serverProxy referenceDate:(NSDate*)referenceDate
{
    if (serverProxy == self.pollServerProxy) {
        // Clear previously scheduled pollServerProxy requests
        [self stopPollRequests];
    }
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:referenceDate];
    
    if (t >= scheduleInterval) {
        [self requestStateRefreshWithServerProxy:serverProxy];
    } else {
        [self performSelector:@selector(requestStateRefreshWithServerProxy:) withObject:serverProxy afterDelay:scheduleInterval - t];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
    if (serverProxy == self.pollServerProxy) {
    }
    else if (serverProxy == self.postServerProxy) {
        [self updateStartButtonActiveStateTo:YES];
    }

    [self updateStartButtonActiveStateTo:YES];
    [self refreshUI];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    if (serverProxy == self.pollServerProxy) {
        self.rainDelayData = (RainDelay*)data;
    
        NSInteger timeStamp = [self.rainDelayData.delayCounter intValue];
        if (timeStamp == -1) {
            self.rainDelayData.rainDelay = [NSNumber numberWithInt:1];
        }
        
        [self updateResumeMode];
    }
    else if (serverProxy == self.postServerProxy) {
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            self.rainDelayData.delayCounter = [NSNumber numberWithInt:[[userInfo objectForKey:@"rainDelay"] intValue] * kOneDayInSeconds];
            [self updateResumeMode];
        }
    }

    [self updatePollState];
    [self updateStartButtonActiveStateTo:YES];
    [self refreshUI];
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (void)updateResumeMode
{
    resumeMode = ([self.rainDelayData.delayCounter intValue] > 0);
}

#pragma mark - Counter

//- (void)startCounterTimer
//{
//    [self stopCounterTimer];
//    self.counterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
//                                                         target:self
//                                                       selector:@selector(counterTimer:)
//                                                       userInfo:nil
//                                                        repeats:YES];
//}
//
//- (void)counterTimer:(id)notif
//{
//    int counter = [self.rainDelayData.delayCounter intValue] - 1;
//    int newCounter = MAX(0, counter);
//    self.rainDelayData.delayCounter = [NSNumber numberWithInt:newCounter];
//    [self refreshCounterUI];
//}
//
//- (void)stopCounterTimer
//{
//    [self.counterTimer invalidate];
//    self.counterTimer = nil;
//}

- (void)updatePollState
{
    if ([self.rainDelayData.delayCounter intValue] == -1) {
//        [self stopCounterTimer];
        [self stopPollRequests];
    } else {
//        [self startCounterTimer];
        [self scheduleNextPollRequest:kRainDelayRefreshTimeInterval withServerProxy:self.pollServerProxy referenceDate:self.lastPollDate];
    }
}

@end
