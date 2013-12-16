//
//  SPMainScreenViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPMainScreenViewController.h"
#import "SPConstants.h"
#import "SPHomeViewController.h"
#import "SPWaterNowTableViewController.h"
#import "SPSettingsViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "AppDelegate.h"
#import "SPUtils.h"
#import "SPConstants.h"

const int kLoggedOut_AlertViewTag = 1;
const int kError_AlertViewTag = 2;

@interface SPMainScreenViewController ()

@end

@implementation SPMainScreenViewController

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
  
  self.title = @"Home";
  self.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
  if ([viewController isKindOfClass:[SPHomeViewController class]]) {
    tabBarController.title = @"Home";
  }
  else if ([viewController isKindOfClass:[SPWaterNowTableViewController class]]) {
    tabBarController.title = @"Water Now";
  }
  else if ([viewController isKindOfClass:[SPSettingsViewController class]]) {
    tabBarController.title = @"Settings";
  }
}

- (void)handleServerLoggedOutUser
{
  [self.navigationController popToRootViewControllerAnimated:NO];

  self.sprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
  [[StorageManager current] saveData];
}

- (void)handleGeneralSprinklerError:(NSString*)errorMessage showErrorMessage:(BOOL)showErrorMessage
{
  self.sprinkler.lastError = errorMessage;
  [[StorageManager current] saveData];

  if ((errorMessage) && (showErrorMessage)) {
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView.tag = kError_AlertViewTag;
    [self.alertView show];
  }
}

- (void)handleLoggedOutSprinklerError
{
  NSString *errorTitle = @"Logged out";
  self.sprinkler.lastError = errorTitle;
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

- (void)setNavBarColor:(UIColor*)color
{
  if ([SPUtils checkOSVersion] >= 7) {
    [self.navigationController.navigationBar setBarTintColor:color];
  } else {
    [self.navigationController.navigationBar setTintColor:color];
  }
  
  AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if ((color) &&
      ([self respondsToSelector:@selector(edgesForExtendedLayout)])) {
//        self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    // In iOS 7, to set the color of all barButtonItems in your app, set the tintColor property on the application's window in the AppDelegate.
    // More detailed info from Apple's iOS 7 UI Transition Guide here (Specifically under the 'Using Tint Color` section).
    // https://developer.apple.com/library/ios/documentation/userexperience/conceptual/TransitionGuide/AppearanceCustomization.html#//apple_ref/doc/uid/TP40013174-CH15-SW1
    // Note: it sets the tint of the tabbar item image&text too!
//    appDel.window.tintColor = [UIColor colorWithRed:kWindowTintColorOnBlueNavBar[0] green:kWindowTintColorOnBlueNavBar[1] blue:kWindowTintColorOnBlueNavBar[2] alpha:1];
  } else {
    
    appDel.window.tintColor = nil;
  }
}

@end
