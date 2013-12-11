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
#import "SPWaterNowViewController.h"
#import "SPSettingsViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"

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
  else if ([viewController isKindOfClass:[SPWaterNowViewController class]]) {
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

@end
