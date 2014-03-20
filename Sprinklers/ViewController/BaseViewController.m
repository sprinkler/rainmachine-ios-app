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
#import "Utils.h"
#import "UpdaterVC.h"
#import "AppDelegate.h"

@interface BaseViewController ()

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firmwareUpdateNeeded:) name:kFirmwareUpdateNeeded object:nil];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:kSprinklerWaterColor[0] green:kSprinklerWaterColor[1] blue:kSprinklerWaterColor[2] alpha:1];
        self.navigationController.navigationBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:kSprinklerWaterColor[0] green:kSprinklerWaterColor[1] blue:kSprinklerWaterColor[2] alpha:1];
    }
}

- (void)updateTitle {
    self.navigationItem.title = [StorageManager current].currentSprinkler.name;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateTitle];
}

#pragma mark - Error handling

- (void)handleServerLoggedOutUser {
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [[StorageManager current] saveData];
}

- (BOOL)handleGeneralSprinklerError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
//    [StorageManager current].currentSprinkler.lastError = errorMessage;
//    [[StorageManager current] saveData];
    
    if ((errorMessage) && (showErrorMessage)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kError_AlertViewTag;
        [self.alertView show];
        
        return YES;
    }
    
    return NO;
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
//    [StorageManager current].currentSprinkler.lastError = errorTitle;
    [[StorageManager current] saveData];
    
    self.alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView.tag = kLoggedOut_AlertViewTag;
    [self.alertView show];
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kLoggedOut_AlertViewTag) {
        [self handleServerLoggedOutUser];

        [StorageManager current].currentSprinkler = nil;
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews];
    }
    
    self.alertView = nil;
}

- (void)firmwareUpdateNeeded:(NSNotification*)notif
{
    // Are we the top most VC?
    // This test filters the case when for ex. DevicesVC is on screen
    if (self.navigationController.visibleViewController == self) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        UINavigationController *navC = (UINavigationController*)(appDelegate.tabBarController.selectedViewController);
        // Are we the selected VC in the tab view?
        if (navC.viewControllers[0] == self) {
            NSNumber *serverAPIMainVersion = (NSNumber*)[notif object];
            UpdaterVC *updaterVC = [[UpdaterVC alloc] init];
            
            updaterVC.serverAPIMainVersion = [serverAPIMainVersion intValue];
            
            UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:updaterVC];
            [self presentViewController:navDevices animated:YES completion:nil];
        }
    }
}

@end
