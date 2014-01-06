//
//  BaseViewController.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "BaseViewController.h"
#import "Additions.h"
#import "DevicesVC.h"
#import "Sprinkler.h"
#import "StorageManager.h"

@interface BaseViewController () {
    UILabel *lblDeviceName;
    UILabel *lblDeviceAddress;
}

@end

@implementation BaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.262745 green:0.592157 blue:0.796079 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.262745 green:0.592157 blue:0.796079 alpha:1];
    }
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_menu_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(openDevices)];
    self.navigationItem.leftBarButtonItem = menuButton;
    
    [self updateTitle];
}

- (void)updateTitle {
    UIView *customTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    lblDeviceName = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 200, 24)];
    lblDeviceName.backgroundColor = [UIColor clearColor];
    lblDeviceName.textColor = [UIColor whiteColor];
    lblDeviceName.text = [StorageManager current].currentSprinkler.name;  //TODO: replace with name from Sprinkler
    lblDeviceName.font = [UIFont systemFontOfSize:18.0f];
    [customTitle addSubview:lblDeviceName];
    
    lblDeviceAddress = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 200, 20)];
    lblDeviceAddress.backgroundColor = [UIColor clearColor];
    lblDeviceAddress.textColor = [UIColor whiteColor];
    lblDeviceAddress.text = [StorageManager current].currentSprinkler.address;//TODO: replace with address from Sprinkler
    lblDeviceAddress.font = [UIFont systemFontOfSize:10.0];
    [customTitle addSubview:lblDeviceAddress];
    
    self.navigationItem.titleView = customTitle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    lblDeviceName.text = [StorageManager current].currentSprinkler.name;
    lblDeviceAddress.text = [StorageManager current].currentSprinkler.address;
}

#pragma mark - Methods

- (void)openDevices {
    DevicesVC *devicesVC = [[DevicesVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:devicesVC];
    [self presentViewController:navDevices animated:YES completion:nil];
}

#pragma mark - Error handling

- (void)handleServerLoggedOutUser {
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [[StorageManager current] saveData];
}

- (void)handleGeneralSprinklerError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
    [StorageManager current].currentSprinkler.lastError = errorMessage;
    [[StorageManager current] saveData];
    
    if ((errorMessage) && (showErrorMessage)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kError_AlertViewTag;
        [self.alertView show];
    }
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
    [StorageManager current].currentSprinkler.lastError = errorTitle;
    [[StorageManager current] saveData];
    
    self.alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView.tag = kLoggedOut_AlertViewTag;
    [self.alertView show];
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kLoggedOut_AlertViewTag) {
        [self handleServerLoggedOutUser];
    }
    
    self.alertView = nil;
}

@end
