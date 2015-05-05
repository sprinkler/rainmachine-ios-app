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
#import "ProvisionLocationSetupVC.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "+UIDevice.h"
#import "AppDelegate.h"
#import "DevicesVC.h"
#import "NetworkUtilities.h"
#import "Utils.h"
#import "API4StatusResponse.h"

@interface ProvisionNameSetupVC ()

@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *nextButton;
@property (weak, nonatomic) IBOutlet UITextField *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *verifyPasswordLabel;
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordLabel;
@property (strong, nonatomic) ServerProxy *provisionNameServerProxy;
@property (strong, nonatomic) ServerProxy *provisionPasswordServerProxy;
@property (strong, nonatomic) ServerProxy *loginServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation ProvisionNameSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    assert(self.sprinkler != nil);

    [ServerProxy pushSprinklerVersion];
    [ServerProxy setSprinklerVersionMajor:4 minor:0 subMinor:0];

    [self.nextButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    self.provisionNameServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
    self.provisionPasswordServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(onNext:)];

    self.deviceNameLabel.delegate = self;
    self.passwordLabel.delegate = self;
    self.verifyPasswordLabel.delegate = self;
    self.oldPasswordLabel.delegate = self;
    
    self.oldPasswordLabel.hidden = !(self.presentOldPasswordField);
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.deviceNameLabel.tintColor = self.deviceNameLabel.textColor;
        self.passwordLabel.tintColor = self.passwordLabel.textColor;
        self.verifyPasswordLabel.tintColor = self.verifyPasswordLabel.textColor;
        self.oldPasswordLabel.tintColor = self.oldPasswordLabel.textColor;
    }

    self.title = @"Setup";//self.sprinkler.sprinklerName;

    [self.deviceNameLabel becomeFirstResponder];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];

    [self setWizardNavBarForVC:self];
    
    [self refreshUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshUI
{
    self.navigationItem.rightBarButtonItem.enabled = (self.deviceNameLabel.text.length != 0) && (self.passwordLabel.text.length != 0) && (self.verifyPasswordLabel.text.length != 0);
}

- (IBAction)onNext:(id)sender {
    if (self.deviceNameLabel.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Rain Machine Name" message:@"Provide a name for your rain machine" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if (self.passwordLabel.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Password" message:@"Provide a password for your rain machine" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if (self.passwordLabel.text.length < 3) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Too Short" message:@"Please enter a longer password" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    if (![self.passwordLabel.text isEqualToString:self.verifyPasswordLabel.text]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password Confirmation" message:@"Passwords do not match" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    [self showHud];
    
    if (self.presentOldPasswordField) {
        [self loginWithPassword:self.oldPasswordLabel.text];
    } else {
        [self startSetProvisionRequests];
    }
}

- (void)startSetProvisionRequests
{
    [self.provisionNameServerProxy setProvisionName:self.deviceNameLabel.text];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo
{
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];

    if (serverProxy == self.provisionNameServerProxy) {
    }
    
    [self hideHud];
}

- (void)loginWithPassword:(NSString*)pwd
{
    [self.loginServerProxy cancelAllOperations];
    self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
    
    // Try to log in automatically
    [self.loginServerProxy loginWithUserName:@"admin" password:pwd rememberMe:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionNameServerProxy) {
        API4StatusResponse *response = (API4StatusResponse*)data;
        if ([response.statusCode intValue] != API4StatusCode_Success) {
            [self handleSprinklerGeneralError:response.message showErrorMessage:YES];
        }
        
        [self.provisionPasswordServerProxy setNewPassword:self.passwordLabel.text confirmPassword:self.verifyPasswordLabel.text oldPassword:self.oldPasswordLabel.text];
    }
    else if (serverProxy == self.provisionPasswordServerProxy) {
        [self hideHud];
        
        self.sprinkler.password = self.passwordLabel.text;
        
        ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
        locationSetupVC.sprinkler = self.sprinkler;
        locationSetupVC.isPartOfWizard = YES;
        
        [self.navigationController pushViewController:locationSetupVC animated:YES];
    }
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit
{
    NSString *address = self.sprinkler.url;
    NSString *port = [Utils getPort:address];
    address = [Utils getBaseUrl:address];
    
    [NetworkUtilities saveAccessTokenForBaseURL:address port:port loginResponse:(Login4Response*)loginResponse];
    
    self.loginServerProxy = nil;
    
    [self startSetProvisionRequests];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"It seems that the old password you eneterd is not correct." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self performSelector:@selector(refreshUI) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == self.deviceNameLabel) {
        [self.passwordLabel becomeFirstResponder];
    }
    else if (textField == self.passwordLabel) {
        [self.verifyPasswordLabel becomeFirstResponder];
    }
    else if (textField == self.verifyPasswordLabel) {
        [self.oldPasswordLabel becomeFirstResponder];
    }
    return NO;
}

@end
