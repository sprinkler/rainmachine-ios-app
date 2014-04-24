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

@interface SettingsAboutVC ()

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

    int major = [UpdateManager current].serverAPIMainVersion;
    int minor = [UpdateManager current].serverAPISubVersion;
    
    hwVersion.text = [NSString stringWithFormat: @"RainMachine Firmware V %d.%d", major, minor];
    
    doUpdate.hidden = YES;
    if ([Utils isDevice359Plus])
    {
        doUpdate.hidden = NO;
    }
}

- (void) startUpdateRefreshUI
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void) stopUpdateRefreshUI
{   
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) doUpdate
{
    [self startUpdateRefreshUI];
}

@end
