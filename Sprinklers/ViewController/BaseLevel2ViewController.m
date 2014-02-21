//
//  BaseLevel2ViewController.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "BaseLevel2ViewController.h"
#import "Additions.h"
#import "StorageManager.h"
#import "BaseViewController.h"

@interface BaseLevel2ViewController ()

@end

@implementation BaseLevel2ViewController

#pragma mark - Init

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
}

#pragma mark - Error handling

- (void)handleServerLoggedOutUser {
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [[StorageManager current] saveData];
}

- (void)handleGeneralSprinklerError:(NSString *)errorMessage showErrorMessage:(BOOL)showErrorMessage {
//    [StorageManager current].currentSprinkler.lastError = errorMessage;
//    [[StorageManager current] saveData];
    
    if ((errorMessage) && (showErrorMessage)) {
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        self.alertView.tag = kError_AlertViewTag;
        [self.alertView show];
    }
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
//    [StorageManager current].currentSprinkler.lastError = errorTitle;
//    [[StorageManager current] saveData];
    
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
