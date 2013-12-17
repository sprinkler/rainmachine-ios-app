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
#import "SPConstants.h"
#import "SPServerProxy.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"

@interface LoginVC () {
    SPServerProxy *serverProxy;
    MBProgressHUD *hud;
}

@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UIButton *buttonCheckBox;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogin;

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
    
    UIView *customTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    UILabel *lblDeviceName = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 200, 24)];
    lblDeviceName.backgroundColor = [UIColor clearColor];
    lblDeviceName.textColor = [UIColor whiteColor];
    lblDeviceName.text = _sprinkler.name;
    lblDeviceName.font = [UIFont systemFontOfSize:18.0f];
    [customTitle addSubview:lblDeviceName];
    
    UILabel *lblDeviceAddress = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, 200, 20)];
    lblDeviceAddress.backgroundColor = [UIColor clearColor];
    lblDeviceAddress.textColor = [UIColor whiteColor];
    lblDeviceAddress.text = _sprinkler.address;
    lblDeviceAddress.font = [UIFont systemFontOfSize:10.0];
    [customTitle addSubview:lblDeviceAddress];
    
    self.navigationItem.titleView = customTitle;
    
    [_buttonLogin setupAsRoundColouredButton:[UIColor colorWithRed:kLoginGreenButtonColor[0] green:kLoginGreenButtonColor[1] blue:kLoginGreenButtonColor[2] alpha:1]];
    
    _buttonCheckBox.selected = [_sprinkler.loginRememberMe boolValue];
    
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
    serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self jsonRequest:NO];
    [serverProxy loginWithUserName:@"admin" password:_textPassword.text rememberMe:_buttonCheckBox.isSelected];
    [self startHud:@"Logging in..."];
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

- (void)loginSucceeded {
    self.sprinkler.loginRememberMe = [NSNumber numberWithBool:_buttonCheckBox.selected];
    [[StorageManager current] saveData];
    
    [self hideHud];
    
    [self showMainScreen];
}

- (void)loggedOut {
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Your password is incorrect." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showMainScreen {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
