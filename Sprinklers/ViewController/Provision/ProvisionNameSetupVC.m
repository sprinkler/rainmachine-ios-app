//
//  ProvisionNameSetupVCViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 08/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionNameSetupVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "LocationSetupVC.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"

@interface ProvisionNameSetupVC ()

@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *nextButton;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *verifyPasswordLabel;
@property (strong, nonatomic) ServerProxy *provisionNameServerProxy;
@property (strong, nonatomic) ServerProxy *provisionPasswordServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation ProvisionNameSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.nextButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    self.provisionNameServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
    self.provisionPasswordServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onNext:(id)sender {
    if (self.deviceNameLabel.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Rain Machine Name" message:@"Provide a name for your name machine" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if (self.passwordLabel.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Password" message:@"Provide a password for your name machine" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if (![self.passwordLabel.text isEqualToString:self.verifyPasswordLabel.text]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Confirmation" message:@"Passwords do not match" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    [self.provisionNameServerProxy setProvisionName:self.deviceNameLabel.text];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.delegate handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];

    if (serverProxy == self.provisionNameServerProxy) {
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionNameServerProxy) {
        [self.provisionPasswordServerProxy setNewPassword:self.passwordLabel.text confirmPassword:self.verifyPasswordLabel.text oldPassword:@""];
    }
    if (serverProxy == self.provisionPasswordServerProxy) {
        [self hideHud];
        LocationSetupVC *locationSetupVC = [[LocationSetupVC alloc] init];
        [self.navigationController pushViewController:locationSetupVC animated:YES];
    }
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit {
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showHud {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

@end
