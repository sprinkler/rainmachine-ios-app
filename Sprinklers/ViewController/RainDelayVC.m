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

@interface RainDelayVC ()
{
    BOOL resumeMode;
}

@property (strong, nonatomic) IBOutlet UILabel *labelDays;
@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSety;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) NSNumber *rainDelay;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rainDelaySetActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *initialTimerRequestActivityIndicator;
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

    resumeMode = NO;
    
    [self.buttonUp setCustomRMFontWithCode:icon_Up size:90];
    [self.buttonDown setCustomRMFontWithCode:icon_Down size:90];

    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];

    [self.pollServerProxy getRainDelay];

    [self refreshUI];
    [self updateStartButtonActiveStateTo:NO setActivityIndicator:NO];
}

- (void)refreshUI
{
    [self.buttonSety setCustomBackgroundColorFromComponents:resumeMode ? kWateringRedButtonColor : kWateringGreenButtonColor];
    [self.buttonSety setTitle:resumeMode ? @"Resume" : @"Set" forState:UIControlStateNormal];

    self.buttonUp.enabled = !resumeMode;
    self.buttonDown.enabled = !resumeMode && ([self.rainDelay intValue] > 1);

    self.buttonUp.alpha = self.buttonUp.enabled ? 1 : kButtonInactiveOpacity;
    self.buttonDown.alpha = self.buttonDown.enabled ? 1 : kButtonInactiveOpacity;

    [self refreshCounterUI];
}

- (void)updateStartButtonActiveStateTo:(BOOL)state setActivityIndicator:(BOOL)setActivityIndicator
{
    if (setActivityIndicator) {
        self.rainDelaySetActivityIndicator.hidden = state;
    }
    self.buttonSety.enabled = state;
    self.buttonSety.alpha = state ? 1 : 0.66;
}

- (void)refreshCounterUI
{
    self.labelDays.hidden = NO;
    
    if (_rainDelay) {
        if ([_rainDelay intValue] == 1) {
            self.labelDays.text = @"1 day";
        } else {
            self.labelDays.text = [NSString stringWithFormat:@"%@ days", _rainDelay];
        }
        self.initialTimerRequestActivityIndicator.hidden = YES;
    } else {
        self.labelDays.text = @"";
        self.initialTimerRequestActivityIndicator.hidden = NO;
    }
}

#pragma mark - Actions

- (IBAction)up:(id)sender {
    self.rainDelay = [NSNumber numberWithInt:[_rainDelay intValue] + 1];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)down:(id)sender {
    self.rainDelay = [NSNumber numberWithInt:MAX(0, [_rainDelay intValue] - 1)];
    [self refreshCounterUI];
    [self refreshUI];
}

- (IBAction)set:(id)sender {
    if (resumeMode) {
        [self updateStartButtonActiveStateTo:NO setActivityIndicator:YES];
        [self.postServerProxy setRainDelay:@0];
    } else {
        [self updateStartButtonActiveStateTo:NO setActivityIndicator:YES];
        [self.postServerProxy setRainDelay:_rainDelay];
    }
}

#pragma mark - Server related

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    if (serverProxy == self.pollServerProxy) {
    }
    else if (serverProxy == self.postServerProxy) {
        [self updateStartButtonActiveStateTo:YES setActivityIndicator:YES];
    }
    [self refreshUI];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    if (serverProxy == self.pollServerProxy) {
        self.rainDelay = ((RainDelay*)data).rainDelay;
        [self updateResumeMode];
    }
    else if (serverProxy == self.postServerProxy) {
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        } else {
            self.rainDelay = [userInfo objectForKey:@"rainDelay"];
            [self updateResumeMode];
        }
    }
    [self updateStartButtonActiveStateTo:YES setActivityIndicator:YES];
    [self refreshUI];
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

- (void)updateResumeMode
{
    resumeMode = ([_rainDelay intValue] != 0);
}

@end
