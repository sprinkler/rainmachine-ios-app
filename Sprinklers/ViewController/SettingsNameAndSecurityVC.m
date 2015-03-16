//
//  SettingsPasswordVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsNameAndSecurityVC.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "StorageManager.h"
#import "+UIDevice.h"
#import "NetworkUtilities.h"
#import "AppDelegate.h"
#import "SetPassword4Response.h"
#import "API4StatusResponse.h"

@interface SettingsNameAndSecurityVC ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textFieldConfirmPassword;

@property (strong, nonatomic) ServerProxy *passwordServerProxy;
@property (strong, nonatomic) ServerProxy *provisionNameServerProxy;

@end

@implementation SettingsNameAndSecurityVC

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

    self.textFieldNewPassword.delegate = self;

    if (!self.isSecurityScreen) {
        // Use self.textFieldNewPassword as the field for the new name
        self.textFieldOldPassword.hidden = YES;
        self.textFieldConfirmPassword.hidden = YES;
        self.textFieldNewPassword.placeholder = @"New Rainmachine Name";
    } else {
        self.textFieldOldPassword.delegate = self;
        self.textFieldConfirmPassword.delegate = self;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.title = self.isSecurityScreen ? @"Password" : @"Rainmachine Name";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isSecurityScreen) {
        [self.textFieldOldPassword becomeFirstResponder];
    } else {
        [self.textFieldNewPassword becomeFirstResponder];
    }
}

- (void)save
{
    if (self.isSecurityScreen) {
        [self.textFieldOldPassword resignFirstResponder];
    } else {
        [self.textFieldNewPassword resignFirstResponder];
    }

    if (self.isSecurityScreen) {
        if (!self.passwordServerProxy) {
            if ([self allFieldsFilled]) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.passwordServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
                
                [self.passwordServerProxy setNewPassword:self.textFieldNewPassword.text confirmPassword:self.textFieldConfirmPassword.text oldPassword:self.textFieldOldPassword.text];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"Please fill in all fields"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        }
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.provisionNameServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        [self.provisionNameServerProxy setProvisionName:self.textFieldNewPassword.text];
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

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.passwordServerProxy) {
        self.passwordServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInf{
    
    if (serverProxy == self.passwordServerProxy) {
        
        self.passwordServerProxy = nil;
        if ([ServerProxy usesAPI3]) {
            ServerResponse *response = (ServerResponse*)data;
            if ([response.status isEqualToString:@"err"]) {
                [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
            } else {
                [Utils invalidateLoginForCurrentSprinkler];
                
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle: nil message:@"Password changed successfully!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                [alertView show];
            }
        } else {
            if ([data isKindOfClass:[API4StatusResponse class]]) {
                API4StatusResponse *response = (API4StatusResponse*)data;
                [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
            } else {
                [Utils invalidateLoginForCurrentSprinkler];
                
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle: nil message:@"Password changed successfully!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                [alertView show];
            }
        }
    } else if (serverProxy == self.provisionNameServerProxy) {
        API4StatusResponse *response = (API4StatusResponse*)data;
        if ([response.statusCode intValue] != API4StatusCode_Success) {
            [self handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            [StorageManager current].currentSprinkler.name = self.textFieldNewPassword.text;
            [[StorageManager current] saveData];
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle: nil message:@"Rainmachine name has been succesfully set!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        }
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.isSecurityScreen) {
        if (buttonIndex == 0) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate refreshRootViews:nil];
        } else {
            [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
        }
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == self.textFieldOldPassword) {
        [self.textFieldNewPassword becomeFirstResponder];
    }
    else if (textField == self.textFieldNewPassword) {
        if (!self.textFieldConfirmPassword.hidden) {
            [self.textFieldConfirmPassword becomeFirstResponder];
        }
    }
    return NO;
}

@end
