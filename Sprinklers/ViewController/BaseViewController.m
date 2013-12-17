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

@interface BaseViewController ()

@end

@implementation BaseViewController

#pragma mark - Dealloc

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
    
    UIView *customTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UILabel *lblDeviceName = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 200, 24)];
    lblDeviceName.backgroundColor = [UIColor clearColor];
    lblDeviceName.textColor = [UIColor whiteColor];
    lblDeviceName.text = @"Device Name";  //TODO: replace with name from Sprinkler
    lblDeviceName.font = [UIFont systemFontOfSize:18.0f];
    [customTitle addSubview:lblDeviceName];
    
    UILabel *lblDeviceAddress = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 200, 20)];
    lblDeviceAddress.backgroundColor = [UIColor clearColor];
    lblDeviceAddress.textColor = [UIColor whiteColor];
    lblDeviceAddress.text = @"192.168.0.103"; //TODO: replace with address from Sprinkler
    lblDeviceAddress.font = [UIFont systemFontOfSize:10.0];
    [customTitle addSubview:lblDeviceAddress];
    
    self.navigationItem.titleView = customTitle;
}

#pragma mark - Methods

- (void)openDevices {
    DevicesVC *devicesVC = [[DevicesVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:devicesVC];
    [self presentViewController:navDevices animated:YES completion:nil];
}

@end
