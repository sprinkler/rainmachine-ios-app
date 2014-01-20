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

@interface LoginVC () {
    ServerProxy *serverProxy;
    MBProgressHUD *hud;
}

@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UIButton *buttonCheckBox;
@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UILabel *bucketLabel;

@end

@implementation LoginVC

#pragma mark - Init

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
    
    [_buttonLogin setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
    
    _buttonCheckBox.selected = [_sprinkler.loginRememberMe boolValue];
    
    [self.bucketLabel setCustomRMFontWithCode:icon_Stropitoare_Icon size:195];
    
    [_textPassword becomeFirstResponder];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Methods

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (IBAction)rememberMe:(id)sender {
    _buttonCheckBox.selected = !_buttonCheckBox.selected;
}

- (IBAction)login:(id)sender {
    serverProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];
    [serverProxy loginWithUserName:@"admin" password:_textPassword.text rememberMe:_buttonCheckBox.isSelected];
    [self startHud:nil]; // @"Logging in..."
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy {
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    [self hideHud];
}

- (void)loginSucceededAndRemembered:(BOOL)remembered {
    [StorageManager current].currentSprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    self.sprinkler.loginRememberMe = [NSNumber numberWithBool:remembered];
    [StorageManager current].currentSprinkler = self.sprinkler;
    [[StorageManager current] saveData];
    
    [self hideHud];
    
    [self.parent done];
}

- (void)loggedOut {
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Your password is incorrect." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
