//
//  SettingsPasswordVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsPasswordVC.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "StorageManager.h"
#import "+UIDevice.h"
#import "NetworkUtilities.h"
#import "AppDelegate.h"

@interface SettingsPasswordVC ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmPassword;

@property (strong, nonatomic) ServerProxy *postServerProxy;

@end

@implementation SettingsPasswordVC

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
	// Do any additional setup after loading the view.
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.textFieldOldPassword.tintColor = [UIColor blackColor];
        self.textFieldNewPassword.tintColor = [UIColor blackColor];
        self.textFieldConfirmPassword.tintColor = [UIColor blackColor];
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.title = @"Password";
}

- (void)save
{
    if (!self.postServerProxy) {
        if ([self allFieldsFilled]) {
            // If we save the same unit again the server returns error: "Units not saved"
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
            
            [self.postServerProxy setNewPassword:self.textFieldNewPassword.text confirmPassword:self.textFieldConfirmPassword.text oldPassword:self.textFieldOldPassword.text];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Please fill in all fields"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (BOOL)allFieldsFilled
{
    return ((self.textFieldNewPassword.text.length != 0) && (self.textFieldConfirmPassword.text.length != 0) && (self.textFieldOldPassword.text.length != 0));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
    
    if (serverProxy == self.postServerProxy) {
        self.postServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInf{
    
    if (serverProxy == self.postServerProxy) {
        
        self.postServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            [Utils invalidateLoginForCurrentSprinkler];
            
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle: nil message:@"Password changed successufully!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        }
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate refreshRootViews:nil];
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
