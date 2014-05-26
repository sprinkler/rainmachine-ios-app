//
//  LoginVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "LoginVC.h"
#import "Additions.h"
#import "+UIButton.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"
#import "DevicesVC.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"
#import "+UIDevice.h"
#import "Networkutilities.h"

@interface LoginVC () {
}

@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UIButton *buttonCheckBox;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UILabel *bucketLabel;
@property (weak, nonatomic) IBOutlet UITextField *textUsername;

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSDictionary *automaticLoginInfo;

@end

@implementation LoginVC

#pragma mark - Init

- (id)initWithAutomaticLoginInfo:(NSDictionary*)info
{
    self = [super init];
    if (self) {
        self.automaticLoginInfo = info;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Login";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    UILabel *lblDeviceName;
    UILabel *lblDeviceAddress;
    self.navigationItem.titleView = [Utils customSprinklerTitleWithOutDeviceView:&lblDeviceName outDeviceAddressView:&lblDeviceAddress];
    
    lblDeviceName.text = _sprinkler.name;
    lblDeviceAddress.text = _sprinkler.address;
    
    [_buttonLogin setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    
    _buttonCheckBox.selected = [_sprinkler.loginRememberMe boolValue];
    
    [self.bucketLabel setCustomRMFontWithCode:icon_Stropitoare_Icon size:195];
    
    _textUsername.text = self.sprinkler.username ? self.sprinkler.username : @"admin";
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        _textUsername.tintColor = _textUsername.textColor;
        _textPassword.tintColor = _textPassword.textColor;
    }
    
    // TODO: uncomment this line in case the device version is >= 4.0
//    [self setup40SprinklerUI];
    
    if (self.automaticLoginInfo) {
        BOOL isSessionOnly = [self.automaticLoginInfo[kSprinklerKeychain_isSessionOnly] boolValue];
        NSString *username = self.automaticLoginInfo[kSprinklerKeychain_UsernameKey];
        NSString *password = self.automaticLoginInfo[kSprinklerKeychain_PasswordKey];
        
        _textPassword.text = password;
        _textUsername.text = username;
        
        [self loginWithUsername:username password:password rememberMe:!isSessionOnly];
    } else {
        [_textPassword becomeFirstResponder];
    }
}

- (void)setup40SprinklerUI
{
    [self.textUsername removeFromSuperview];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_textPassword
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.bucketLabel
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:4.0]];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Methods

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - Actions
- (IBAction)rememberMe:(id)sender {
    _buttonCheckBox.selected = !_buttonCheckBox.selected;
}

- (IBAction)login:(id)sender {
    [self loginWithUsername:_textUsername.text password:_textPassword.text rememberMe:_buttonCheckBox.isSelected];
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password rememberMe:(BOOL)rememberMe
{
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils sprinklerURL:self.sprinkler] delegate:self jsonRequest:NO];
    [self.serverProxy loginWithUserName:username password:password rememberMe:rememberMe];
    [self startHud:nil]; // @"Logging in..."
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self hideHud];
    UIAlertView *alertView = nil;
    if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
        alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
    [alertView show];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self hideHud];
}

- (void)loginSucceededAndRemembered:(BOOL)remembered unit:(NSString*)unit {
    
    [NetworkUtilities saveCookiesForBaseURL:self.sprinkler.address port:self.sprinkler.port username:_textUsername.text password:_textPassword.text];
    
    self.sprinkler.loginRememberMe = [NSNumber numberWithBool:remembered];
    self.sprinkler.username = _textUsername.text;
    [StorageManager current].currentSprinkler = self.sprinkler;
    [[StorageManager current] saveData];
    
    [self hideHud];
    
    [self.parent done:unit];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showMainScreenAnimated:(BOOL)animated {
    [self.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
