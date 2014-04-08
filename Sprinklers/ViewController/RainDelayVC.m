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
@property (strong, nonatomic) IBOutlet UILabel *labelHours;
@property (strong, nonatomic) IBOutlet UILabel *labelMinutes;

@property (weak, nonatomic) IBOutlet UIButton *buttonUp;
@property (weak, nonatomic) IBOutlet UIButton *buttonDown;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSety;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) NSNumber *rainDelay;
@property (strong, nonatomic) NSNumber *rainDelayHours;
@property (strong, nonatomic) NSNumber *rainDelayMinutes;

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
    
    [self.buttonUp setCustomRMFontWithCode:icon_Plus size:self.buttonUp.frame.size.width - 2];
    [self.buttonDown setCustomRMFontWithCode:icon_Minus size:self.buttonUp.frame.size.width - 2];

    UIColor *greenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    UIColor *redColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    
    [self.buttonDown setTitleColor:redColor forState:UIControlStateNormal];
    [self.buttonUp setTitleColor:greenColor forState:UIControlStateNormal];
    
    [self.labelDays setTextColor:greenColor];
    [self.labelHours setTextColor:greenColor];
    [self.labelMinutes setTextColor:greenColor];
    
    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    
    self.rainDelayHours = [NSNumber numberWithInt: 0];
    self.rainDelayMinutes = [NSNumber numberWithInt: 0];
    
    [self.pollServerProxy getRainDelay];
    
    [self refreshUI];
    [self updateStartButtonActiveStateTo:NO setActivityIndicator:NO];
}

- (void)refreshUI
{
    [self.buttonSety setCustomBackgroundColorFromComponents:resumeMode ? kWateringRedButtonColor : kWateringGreenButtonColor];
    [self.buttonSety setTitle:resumeMode ? @"Resume" : @"Resume" forState:UIControlStateNormal];

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
    self.labelHours.hidden = NO;
    self.labelMinutes.hidden = NO;
    
    if (_rainDelay) {
        if ([_rainDelay intValue] == 1) {
            self.labelDays.text = @"1 day";
            self.labelHours.text = [NSString stringWithFormat:@"%@ hours", _rainDelayHours];
            self.labelMinutes.text = [NSString stringWithFormat:@"%@ minutes", _rainDelayMinutes];
        } else {
            self.labelDays.text = [NSString stringWithFormat:@"%@ days", _rainDelay];
            self.labelHours.text = [NSString stringWithFormat:@"%@ hours", _rainDelayHours];
            self.labelMinutes.text = [NSString stringWithFormat:@"%@ minutes", _rainDelayMinutes];
        }
        self.initialTimerRequestActivityIndicator.hidden = YES;
    } else {
        self.labelDays.text = @"";
        self.labelHours.text = @"";
        self.labelMinutes.text = @"";
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
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
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
    
        NSLog(@"rainDelay=%d delayCounter=%d", (int)[((RainDelay*)data).rainDelay intValue], (int)[((RainDelay*)data).delayCounter intValue]);
        
        NSInteger timeStamp = [((RainDelay*)data).delayCounter intValue];
        int hours = 0;
        int minutes = 0;
    
        if (timeStamp >= 0)
        {
            NSDate* date = [NSDate dateWithTimeIntervalSince1970: timeStamp];
            hours = (int)[date hour];
            minutes = (int)[date minute];
            
            NSLog(@"hours=%d minutes=%d", hours, minutes);
    
            self.rainDelayHours = [NSNumber numberWithInt: hours];
            self.rainDelayMinutes = [NSNumber numberWithInt: minutes];
        }
        
        [self updateResumeMode];
    }
    else if (serverProxy == self.postServerProxy) {
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
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
