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
#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "SettingsVC.h"
#import "MBProgressHUD.h"

@interface RainDelayVC ()

@property (strong, nonatomic) IBOutlet UILabel *labelDays;
@property (strong, nonatomic) IBOutlet UILabel *labelHours;
@property (strong, nonatomic) IBOutlet UILabel *labelMinutes;
@property (strong, nonatomic) IBOutlet UILabel *labelHours_0Days;
@property (strong, nonatomic) IBOutlet UILabel *labelMinutes_0Days;
@property (weak, nonatomic) IBOutlet UILabel *labelCounter;

@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonDelayResume;
@property (strong, nonatomic) RainDelayPoller *rainDelayPoller;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rainDelaySetActivityIndicator;

@end

@implementation RainDelayVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Delay";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.rainDelayPoller = [[RainDelayPoller alloc] initWithDelegate:self];

    [self.buttonUp setCustomRMFontWithCode:icon_Plus size:self.buttonUp.frame.size.width - 2];
    [self.buttonDown setCustomRMFontWithCode:icon_Minus size:self.buttonUp.frame.size.width - 2];

    [self.buttonDelayResume setTitle:@"" forState:UIControlStateNormal];
    
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
    
    [self hideUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.rainDelayPoller scheduleNextPoll:0];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.rainDelayPoller stopPollRequests];
}

- (void)hideUI
{
    self.rainDelaySetActivityIndicator.hidden = YES;

    self.buttonDelayResume.hidden = YES;
    
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
    self.buttonDelayResume.enabled = state;
    self.buttonDelayResume.alpha = state ? 1 : 0.66;
}

- (void)refreshUI
{
    BOOL rainDelayMode = [self.rainDelayPoller rainDelayMode];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self.buttonDelayResume setCustomBackgroundColorFromComponents:rainDelayMode ? kWateringRedButtonColor : kWateringGreenButtonColor];
    [self.buttonDelayResume setTitle:rainDelayMode ? @"Resume" : @"Delay" forState:UIControlStateNormal];
    self.buttonDelayResume.hidden = NO;

    self.buttonDown.enabled = ([self.rainDelayPoller.rainDelayData.rainDelay intValue] > 1);
    
    self.buttonUp.alpha = self.buttonUp.enabled ? 1 : kButtonInactiveOpacity;
    self.buttonDown.alpha = self.buttonDown.enabled ? 1 : kButtonInactiveOpacity;
    
    self.buttonUp.hidden = rainDelayMode;
    self.buttonDown.hidden = rainDelayMode;
    
    self.labelCounter.hidden = rainDelayMode;
    
    [self refreshCounterUI];
}

- (void)refreshCounterUI
{
    BOOL rainDelayMode = [self.rainDelayPoller rainDelayMode];

    if (rainDelayMode) {
        assert(self.rainDelayPoller.rainDelayData);
        int m = ([self.rainDelayPoller.rainDelayData.delayCounter intValue] / 60) % 60;
        int h = ([self.rainDelayPoller.rainDelayData.delayCounter intValue] / (60 * 60)) % 24;
        int d = ([self.rainDelayPoller.rainDelayData.delayCounter intValue] / (60 * 60)) / 24;
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
        self.labelDays.hidden = YES;
        self.labelHours.hidden = YES;
        self.labelMinutes.hidden = YES;
        self.labelHours_0Days.hidden = YES;
        self.labelMinutes_0Days.hidden = YES;

        int d = [self.rainDelayPoller.rainDelayData.rainDelay intValue];
        if (d == 0) {
            d = 1;
        }
        self.labelCounter.text = [NSString stringWithFormat:@"%d day%@", d, (d == 1) ? @"" : @"s"];
    }
}

#pragma mark - Actions

- (IBAction)up:(id)sender {
    self.rainDelayPoller.rainDelayData.rainDelay = [NSNumber numberWithInt:[self.rainDelayPoller.rainDelayData.rainDelay intValue] + 1];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)down:(id)sender {
    self.rainDelayPoller.rainDelayData.rainDelay = [NSNumber numberWithInt:MAX(0, [self.rainDelayPoller.rainDelayData.rainDelay intValue] - 1)];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)set:(id)sender {
    if ([self.rainDelayPoller rainDelayMode]) {
        [self updateStartButtonActiveStateTo:NO];
    } else {
        [self updateStartButtonActiveStateTo:NO];
    }
    
    [self.rainDelayPoller setRainDelay];
}

#pragma mark - RainDelayPollerDelegate

- (void)handleSprinklerNetworkError:(NSError*)error operation:(AFHTTPRequestOperation *)operation showErrorMessage:(BOOL)showErrorMessage {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)handleSprinklerGeneralError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [self.parent handleSprinklerGeneralError:errorMessage showErrorMessage:YES];
}


- (void)hideRainDelayActivityIndicator:(BOOL)hide
{
    [self updateStartButtonActiveStateTo:YES];
}

- (void)refreshStatus
{
    [self refreshUI];
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (void)hideHUD
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - Rain Delay related

- (void)setRainDelay
{
    [self hideRainDelayActivityIndicator:NO];
    
    [self.rainDelayPoller setRainDelay];
}

@end
