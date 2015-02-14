//
//  BaseModalProvision.m
//  Sprinklers
//
//  Created by Fabian Matyas on 14/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "BaseModalProvisionVC.h"
#import "+UIDevice.h"
#import "AppDelegate.h"
#import "DevicesVC.h"

@interface BaseModalProvisionVC ()

@end

@implementation BaseModalProvisionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setWizardNavBarForVC:(UIViewController*)viewController
{
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                    target:self
                                                                                                    action:@selector(onCancel:)];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        viewController.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        viewController.navigationController.navigationBar.translucent = NO;
        viewController.tabBarController.tabBar.translucent = NO;
    }
    else {
        viewController.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
}

- (void)onCancel:(id)notif
{
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Cancel Setup?" message:@"Are you sure you want to cancel Rainmachine Setup?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Cancel Setup",nil];
    self.alertView.tag = kAlertView_SetupWizard_CancelWizard;
    [self.alertView show];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (theAlertView.tag == kAlertView_SetupWizard_CancelWizard) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            if (self.delegate) {
                [self.delegate.navigationController popToRootViewControllerAnimated:NO];
            } else {
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
//            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            [appDelegate.devicesVC.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }

    [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
}

@end
