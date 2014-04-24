//
//  SettingsAboutVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 04/04/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsAboutVC.h"
#import "UpdateManager.h"
#import "AppDelegate.h"

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
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    iosVersion.text = [NSString stringWithFormat: @"RainMachine iOS V %@", version];

    self.updateManager = [UpdateManager new];
    [self.updateManager poll:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UpdateManagerDelegate

- (void)sprinklerVersionReceivedMajor:(int)major minor:(int)minor
{
    // Update the values from AppDelegate's UpdateManager too
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.updateManager.serverAPIMainVersion = major;
    appDelegate.updateManager.serverAPISubVersion = minor;
    
    hwVersion.text = [NSString stringWithFormat: @"RainMachine Hardware V %d.%d", major, minor];
}

- (void)updateNowAvailable:(NSString *)the_new_version
{
}

@end
