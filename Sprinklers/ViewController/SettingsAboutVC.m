//
//  SettingsAboutVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 04/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsAboutVC.h"
#import "UpdateManager.h"
#import "Utils.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"

@interface SettingsAboutVC ()

@property (strong, nonatomic) UpdateManager *updateManager;

@end

@implementation SettingsAboutVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"About";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    iosVersion.text = [NSString stringWithFormat: @"RainMachine iOS V %@", version];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    int major = appDelegate.updateManager.serverAPIMainVersion;
    int minor = appDelegate.updateManager.serverAPISubVersion;
    
    if ((major > 0) && (minor > 0)) {
        // At first, fill the values with what we have available
        [self sprinklerVersionReceivedMajor:major minor:minor];
    } else {
        hwVersion.hidden = YES;
    }
    
    consoleUpdate.hidden = YES;
    doUpdate.hidden = YES;
    [doUpdate setCustomBackgroundColorFromComponents:kSprinklerBlueColor];

    self.updateManager = [[UpdateManager alloc] initWithDelegate:self];
    [self.updateManager poll];
    
    [self startUpdateRefreshUI];
}

- (void)startUpdateRefreshUI
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)stopUpdateRefreshUI
{   
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UpdateManagerDelegate

- (IBAction) doUpdate
{
    [self.updateManager startUpdate];
}

- (void)sprinklerVersionReceivedMajor:(int)major minor:(int)minor
{
    // Update the values from AppDelegate's UpdateManager too
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.updateManager.serverAPIMainVersion = major;
    appDelegate.updateManager.serverAPISubVersion = minor;
    
    hwVersion.text = [NSString stringWithFormat: @"RainMachine Hardware V %d.%d", major, minor];
    hwVersion.hidden = ((major == 0) || (minor == 0));
    
    if (![Utils isDevice359Plus]) {
        // When device is lower than 3.59 show a label saying the update is available from the rain machine console
        [self stopUpdateRefreshUI];
        consoleUpdate.hidden = NO;
    }
}

- (void)updateNowAvailable:(BOOL)available withVersion:(NSString *)the_new_version
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (available) {
        doUpdate.hidden = NO;
    }

    [self stopUpdateRefreshUI];
}

@end
