//
//  AddNewDeviceVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "AddNewDeviceVC.h"
#import "CloudAccountsVC.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "Constants.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"
#import "Additions.h"
#import "CloudUtils.h"
#import "ServerProxy.h"
#import "+UIDevice.h"
#import "MBProgressHUD.h"

#define AlertViewAddCloudAccountTag         1000

@interface AddNewDeviceVC ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (assign, nonatomic) NSInteger scrollViewContentHeight;

@property (weak, nonatomic) IBOutlet UITextField *urlOrIPTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenEmailTextField;
@property (weak, nonatomic) IBOutlet ColoredBackgroundButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *tokenExplanationTextfield;
@property (weak, nonatomic) IBOutlet UIImageView *tokenSeparator;
@property (weak, nonatomic) IBOutlet UIImageView *nameAndUrlSeparator;
@property (weak, nonatomic) IBOutlet UILabel *tokenTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlOrIPTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameTitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *showPasswordButton;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *exampleIPLabel;

@property (strong, nonatomic) ServerProxy *cloudServerProxy;

- (void)checkCloudAccountForEmail:(NSString*)email password:(NSString*)password;
- (void)removeTokenView;
- (void)enableShowPasswordButton;
- (void)enableExampleIPLabel;

@end

@implementation AddNewDeviceVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Add Device";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollViewContentHeight = (self.edit ? 280.0 : 250.0);
    
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.contentView.frame = CGRectMake(0.0, 0.0, self.scrollView.bounds.size.width, self.contentView.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(0.0, self.scrollViewContentHeight);
    [self.scrollView addSubview:self.contentView];
    
    if (self.cloudUI) {
        self.title = (self.edit ? @"Edit Account" : @"Add Account");
        self.nameTitleLabel.text = @"E-mail address";
        self.urlOrIPTitleLabel.text = @"RainMachine password";
        self.urlOrIPTextField.secureTextEntry = YES;
        
        if (self.existingEmail) _nameTextField.text = self.existingEmail;
        if (self.existingPassword) _urlOrIPTextField.text = self.existingPassword;
        if (self.edit) [self enableShowPasswordButton];
        
        _nameTextField.keyboardType = UIKeyboardTypeEmailAddress;
        _urlOrIPTextField.keyboardType = UIKeyboardTypeDefault;
    } else {
        [self enableExampleIPLabel];
    }
    
    if (self.sprinkler) {
        self.nameTextField.text = self.sprinkler.name;
        self.urlOrIPTextField.text = self.sprinkler.address;
    }

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        _nameTextField.tintColor = _nameTextField.textColor;
        _urlOrIPTextField.tintColor = _urlOrIPTextField.textColor;
        _tokenEmailTextField.tintColor = _tokenEmailTextField.textColor;
    }

    [self removeTokenView];
    
    // Customize the Save button
    [self.saveButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];

    [_nameTextField becomeFirstResponder];
}

- (void)removeTokenView {
    [_tokenExplanationTextfield removeFromSuperview];
    [_nameAndUrlSeparator removeFromSuperview];
    [_tokenTitleLabel removeFromSuperview];
    [_tokenEmailTextField removeFromSuperview];
    
    NSInteger constraintConstant = 0.0;
    if (self.cloudUI) constraintConstant = (self.edit ? 58.0 : 18.0);
    else constraintConstant = 40.0;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_tokenSeparator
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_urlOrIPTextField
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:constraintConstant];

    constraint.priority = UILayoutPriorityRequired;
    
    [self.view addConstraint:constraint];
}

- (void)enableShowPasswordButton {
    self.showPasswordButton.hidden = NO;
    self.showPasswordLabel.hidden = NO;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_showPasswordLabel
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:_urlOrIPTextField
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:20.0];
    
    constraint.priority = UILayoutPriorityRequired;
    [self.view addConstraint:constraint];
}

- (void)enableExampleIPLabel {
    self.exampleIPLabel.hidden = NO;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_exampleIPLabel
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:_urlOrIPTextField
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:4.0];
    
    constraint.priority = UILayoutPriorityRequired;
    [self.view addConstraint:constraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cloudServerProxy cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)checkCloudAccountForEmail:(NSString*)email password:(NSString*)password {
    NSString *cloudProxyFinderURL = [[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey];
    self.cloudServerProxy = [[ServerProxy alloc] initWithServerURL:cloudProxyFinderURL delegate:self jsonRequest:YES];
    [self.cloudServerProxy checkCloudAccount:email password:password phoneID:[Utils phoneID]];
}

#pragma mark - Actions

- (IBAction)onShowPassword:(id)sender {
    self.showPasswordButton.selected = !self.showPasswordButton.selected;
    self.urlOrIPTextField.secureTextEntry = !self.showPasswordButton.selected;
}

- (IBAction)onSave:(id)sender {
    if (self.cloudUI) {
        if (!self.nameTextField.text.isValidEmail) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid email address" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else if ([CloudUtils existsCloudAccountWithEmail:self.nameTextField.text] && !self.edit) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"An account with the same email already exists." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        } else {
            [self.urlOrIPTextField resignFirstResponder];
            [self.nameTextField resignFirstResponder];
            [self.tokenEmailTextField resignFirstResponder];
            
            [self checkCloudAccountForEmail:self.nameTextField.text password:self.urlOrIPTextField.text];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"Verifying your account";
        }
    } else {
        NSString *name = self.nameTextField.text;
        NSString *address = [Utils fixedSprinklerAddress:self.urlOrIPTextField.text];
        NSURL *baseURL = [NSURL URLWithString:address];
        NSString *port = [Utils getPort:address];
        
        if ([name length] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete fields" message:@"Please provide a name for your device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        if ([address length] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete fields" message:@"Please provide a value for the IP address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
        
        if (!baseURL) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid URL" message:@"It looks like you entered an invalid URL for the sprinkler. Please check your syntax and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            return;
        }
        
        address = [Utils getBaseUrl:address];
        
        if ([name length] == 0) {
            name = address;
        }
        
        if (!port) {
            port = @"443";
        }
        
        if (_sprinkler) {
            _sprinkler.name = name;
            _sprinkler.address = address;
            _sprinkler.port = port;
            [[StorageManager current] saveData];
            [self.navigationController popViewControllerAnimated:YES];
            
        }
        else {
            if (![[StorageManager current] getSprinkler:name local:@NO]) {
                self.sprinkler = [[StorageManager current] addSprinkler:name ipAddress:address port:port isLocal:@NO email:nil mac:nil save:YES];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"A sprinkler with the same name already exists. Please select another name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                return;
            }
        }
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ((textField == self.nameTextField) ||
        (textField == self.tokenEmailTextField) ||
        (textField == self.urlOrIPTextField)
        ) {
        [textField resignFirstResponder];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.cloudServerProxy) {
        NSDictionary *sprinklerDict = (NSDictionary*)data;
        
        NSInteger activeCount = 0;
        NSInteger authCount = 0;
        NSInteger knownCount = 0;
        
        if ([sprinklerDict isKindOfClass:[NSDictionary class]]) {
            activeCount = [sprinklerDict[@"activeCount"] integerValue];
            authCount = [sprinklerDict[@"authCount"] integerValue];
            knownCount = [sprinklerDict[@"knownCount"] integerValue];
        }
        
        if (knownCount == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:[NSString stringWithFormat:@"Could not find any RainMachine associated to %@. Check that the email address is correct, and that the verification email has been confirmed.",self.nameTextField.text]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            alert.tag = AlertViewAddCloudAccountTag;
            [alert show];
        }
        else if (activeCount == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:[NSString stringWithFormat:@"The RainMachine associated to %@ is not connected to the Internet",self.nameTextField.text]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            alert.tag = AlertViewAddCloudAccountTag;
            [alert show];
        }
        else if (authCount == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"You entered a wrong password. Please try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
        else [self continueWithAddingOrReplacingCloudAccount];
        
        self.cloudServerProxy = nil;
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

- (void)continueWithAddingOrReplacingCloudAccount {
    if (self.edit) {
        if (self.existingEmail) {
            [CloudUtils deleteCloudAccountWithEmail:self.existingEmail];
            
            NSArray *remoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:nil];
            for (Sprinkler *sprinkler in remoteDevices) {
                if ([self.existingEmail isEqualToString:sprinkler.email]) {
                    if (sprinkler == [StorageManager current].currentSprinkler) {
                        [Utils invalidateLoginForCurrentSprinkler];
                        if ([self.parent isKindOfClass:[CloudAccountsVC class]]) {
                            ((CloudAccountsVC*)self.parent).currentSprinklerDeleted = YES;
                        }
                    }
                    [[StorageManager current] deleteSprinkler:sprinkler];
                }
            }
        }
    }
    
    [CloudUtils addCloudAccountWithEmail:self.nameTextField.text password:self.urlOrIPTextField.text];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.cloudServerProxy) {
        self.cloudServerProxy = nil;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification*)notification {
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.scrollView.contentSize = CGSizeMake(0.0, self.scrollViewContentHeight + keyboardSize.height);
}

- (void)keyboardWillHide:(NSNotification*)notification {
    self.scrollView.contentSize = CGSizeMake(0.0, self.scrollViewContentHeight);
}

#pragma mark - UiAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == AlertViewAddCloudAccountTag) {
        [self continueWithAddingOrReplacingCloudAccount];
    }
    else [super alertView:alertView didDismissWithButtonIndex:buttonIndex];
}

@end
