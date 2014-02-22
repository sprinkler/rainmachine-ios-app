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
    
    [self.buttonUp setCustomRMFontWithCode:icon_Up size:90];
    [self.buttonDown setCustomRMFontWithCode:icon_Down size:90];
    
    [_buttonSety setCustomBackgroundColorFromComponents:kWateringGreenButtonColor];

    self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];

    [self.pollServerProxy getRainDelay];
    [self updateStartButtonActiveStateTo:NO setActivityIndicator:NO];
}

- (void)updateStartButtonActiveStateTo:(BOOL)state setActivityIndicator:(BOOL)setActivityIndicator
{
    if (setActivityIndicator) {
        self.rainDelaySetActivityIndicator.hidden = state;
    }
    self.buttonSety.enabled = state;
    self.buttonSety.alpha = state ? 1 : 0.66;
}

- (void)updateCounter
{
    self.initialTimerRequestActivityIndicator.hidden = YES;
    self.labelDays.hidden = NO;
    
    if (_rainDelay) {
        if ([_rainDelay intValue] == 1) {
            self.labelDays.text = @"1 day";
        } else {
            self.labelDays.text = [NSString stringWithFormat:@"%@ days", _rainDelay];
        }
    } else {
        self.labelDays.text = @"";
    }
}

#pragma mark - Actions

- (IBAction)up:(id)sender {
    self.rainDelay = [NSNumber numberWithInt:[_rainDelay intValue] + 1];
    [self updateCounter];
}

- (IBAction)down:(id)sender {
    self.rainDelay = [NSNumber numberWithInt:MAX(0, [_rainDelay intValue] - 1)];
    [self updateCounter];
}

- (IBAction)set:(id)sender {
    [self updateStartButtonActiveStateTo:NO setActivityIndicator:YES];
    [self.postServerProxy setRainDelay:_rainDelay];
}

#pragma mark - Server related

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    if (serverProxy == self.pollServerProxy) {
        [self updateCounter];
    }
    else if (serverProxy == self.postServerProxy) {
        [self updateStartButtonActiveStateTo:YES setActivityIndicator:YES];
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
    if (serverProxy == self.pollServerProxy) {
        if (![self.parent handleGeneralSprinklerError:nil showErrorMessage:YES]) {
            self.rainDelay = ((RainDelay*)data).rainDelay;
            [self updateCounter];
        }
    }
    else if (serverProxy == self.postServerProxy) {
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        }
    }
    [self updateStartButtonActiveStateTo:YES setActivityIndicator:YES];
}

- (void)loggedOut
{
    [self.parent handleLoggedOutSprinklerError];
}

@end
