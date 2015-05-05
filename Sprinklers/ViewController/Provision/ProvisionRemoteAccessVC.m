//
//  ProvisionRemoteAccessVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ProvisionRemoteAccessVC.h"
#import "DevicesVC.h"
#import "GlobalsManager.h"
#import "ServerProxy.h"
#import "Sprinkler.h"
#import "CloudSettings.h"
#import "CloudUtils.h"
#import "Additions.h"
#import "DiscoveredSprinklers.h"
#import "Sprinkler.h"
#import "Utils.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "ColoredBackgroundButton.h"

#define kRemoteAccess_SetCloudEmail_AlertView_Tag                   1000
#define kRemoteAccess_InvalidEmail_AlertView_Tag                    1001
#define kRemoteAccess_FinishRainmachineSetup_AlertView_Tag          1002
#define kRemoteAccess_CloudEmailWarning_AlertView_Tag               1003
#define kRemoteAccess_VerificationEmail_AlertView_Tag               1004

#pragma mark -

@interface ProvisionRemoteAccessVC ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) NSString *currentPendingEmail;
@property (nonatomic, assign) BOOL currentRemoteAccessEnabled;

@property (nonatomic, strong) ServerProxy *enableRemoteAccessServerProxy;
@property (nonatomic, strong) ServerProxy *saveCloudEmailServerProxy;
@property (nonatomic, strong) ServerProxy *refreshCloudSettingsServerProxy;
@property (nonatomic, strong) ServerProxy *emailValidatorServerProxy;

@property (nonatomic, strong) CloudSettings *wizardCloudSettings;
@property (nonatomic, assign) BOOL cloudEmailWarningWasShown;

- (void)refreshProgressHUD;
- (void)enableRemoteAccess:(BOOL)enable;
- (void)saveCloudEmail:(NSString*)email;
- (void)validateEmail:(NSString*)email showProgress:(BOOL)showProgress;
- (void)refreshCloudSettings;

- (void)showCloudEmailWarning;
- (void)showRainMachineSetUpSuccessfulAlert;

- (IBAction)onEnableCloudEmail:(UISwitch*)enableCloudEmailSwitch;
- (IBAction)onSkip:(id)sender;

@end

#pragma mark -

@implementation ProvisionRemoteAccessVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[GlobalsManager current] addObserver:self forKeyPath:@"cloudSettings" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

- (void)dealloc {
    [[GlobalsManager current] removeObserver:self forKeyPath:@"cloudSettings"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Set remote access";
    
    if (self.isPartOfWizard) {
        self.wizardCloudSettings = [CloudSettings new];
        self.saveButton.customBackgroundColorFromComponents = kSprinklerBlueColor;
        
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            self.emailAddressTextField.tintColor = [UIColor blackColor];
        }
        
        self.emailAddressTextField.text = [CloudUtils firstCloudAccount];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Skip"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(onSkip:)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([ServerProxy usesAPI4]) {
        if (!self.isPartOfWizard && [GlobalsManager current].cloudSettings.pendingEmail.length) {
            [[GlobalsManager current] startPollingCloudSettings];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.isPartOfWizard) {
        [[GlobalsManager current] stopPollingCloudSettings];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == [GlobalsManager current] && [keyPath isEqualToString:@"cloudSettings"]) {
        [self.tableView reloadData];
        if (![GlobalsManager current].cloudSettings.pendingEmail.length) {
            [[GlobalsManager current] stopPollingCloudSettings];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)refreshProgressHUD {
    BOOL shouldDisplayProgressHUD = (self.enableRemoteAccessServerProxy || self.saveCloudEmailServerProxy || self.refreshCloudSettingsServerProxy || self.emailValidatorServerProxy);
    if (shouldDisplayProgressHUD && !self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    else if (!shouldDisplayProgressHUD && self.hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.hud = nil;
    }
}

- (void)enableRemoteAccess:(BOOL)enable {
    self.currentRemoteAccessEnabled = enable;
    
    if (self.sprinkler) self.enableRemoteAccessServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
    else self.enableRemoteAccessServerProxy = [[ServerProxy alloc] initWithSprinkler:self.dbSprinkler delegate:self jsonRequest:YES];
    
    [self.enableRemoteAccessServerProxy enableRemoteAccess:enable];
    [self refreshProgressHUD];
}

- (void)saveCloudEmail:(NSString*)email {
    self.currentPendingEmail = email;
    
    if (self.sprinkler) self.saveCloudEmailServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
    else self.saveCloudEmailServerProxy = [[ServerProxy alloc] initWithSprinkler:self.dbSprinkler delegate:self jsonRequest:YES];
    
    [self.saveCloudEmailServerProxy saveCloudEmail:email];
    [self refreshProgressHUD];
}

- (void)validateEmail:(NSString*)email showProgress:(BOOL)showProgress; {
    NSString *emailValidatorURL = [[NSUserDefaults standardUserDefaults] objectForKey:kCloudEmailValidatorURLKey];
    ServerProxy *emailValidatorServerProxy = [[ServerProxy alloc] initWithServerURL:emailValidatorURL delegate:self jsonRequest:YES];

    [emailValidatorServerProxy validateEmail:email
                                  deviceName:(self.sprinkler ? self.sprinkler.sprinklerName : self.dbSprinkler.name)
                                         mac:(self.sprinkler ? self.sprinkler.sprinklerId : self.dbSprinkler.mac)];
    
    if (showProgress) {
        self.emailValidatorServerProxy = emailValidatorServerProxy;
        [self refreshProgressHUD];
    }
}

- (void)refreshCloudSettings {
    if (self.sprinkler) self.refreshCloudSettingsServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:NO];
    else self.refreshCloudSettingsServerProxy = [[ServerProxy alloc] initWithSprinkler:self.dbSprinkler delegate:self jsonRequest:NO];
    
    [self.refreshCloudSettingsServerProxy requestCloudSettings];
    [self refreshProgressHUD];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.isPartOfWizard) return 1;
    
    CloudSettings *cloudSettings = [GlobalsManager current].cloudSettings;
    if (!cloudSettings.enabled) return 1;
    if (cloudSettings.pendingEmail.length) return 2;
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CloudEmailCellIdentifier = @"CloudEmailCell";
    static NSString *ResendConfirmationEmailCellIdentifier = @"ResendConfirmationEmailCell";
    
    CloudSettings *cloudSettings = (self.isPartOfWizard ? self.wizardCloudSettings : [GlobalsManager current].cloudSettings);
    UITableViewCell *cell = nil;
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CloudEmailCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CloudEmailCellIdentifier];
        
        cell.textLabel.text = @"Cloud Email";
        cell.detailTextLabel.text = [Utils cloudEmailStatusForCloudSettings:cloudSettings];
        
        UISwitch *enableCloudEmailSwitch = [UISwitch new];
        enableCloudEmailSwitch.on = cloudSettings.enabled;
        
        [enableCloudEmailSwitch addTarget:self action:@selector(onEnableCloudEmail:) forControlEvents:UIControlEventValueChanged];
        
        cell.accessoryView = enableCloudEmailSwitch;
    }
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:ResendConfirmationEmailCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ResendConfirmationEmailCellIdentifier];
        
        cell.textLabel.text = @"Resend confirmation email";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        UISwitch *enableCloudEmailSwitch = (UISwitch*)cell.accessoryView;
        if (!enableCloudEmailSwitch.isOn) enableCloudEmailSwitch.on = YES;
        [self onEnableCloudEmail:enableCloudEmailSwitch];
    }
    else if (indexPath.section == 1) {
        [self validateEmail:[GlobalsManager current].cloudSettings.pendingEmail showProgress:YES];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)onEnableCloudEmail:(UISwitch*)enableCloudEmailSwitch {
    if (enableCloudEmailSwitch.isOn) {
        UIAlertView *setCloudEmailAlertView = [[UIAlertView alloc] initWithTitle:@"Set Cloud Email"
                                                                         message:nil
                                                                        delegate:self
                                                               cancelButtonTitle:@"Cancel"
                                                               otherButtonTitles:@"Save", nil];
        setCloudEmailAlertView.tag = kRemoteAccess_SetCloudEmail_AlertView_Tag;
        setCloudEmailAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [setCloudEmailAlertView show];
        
        CloudSettings *cloudSettings = (self.isPartOfWizard ? self.wizardCloudSettings : [GlobalsManager current].cloudSettings);
        NSString *email = cloudSettings.pendingEmail;
        if (!email.length) email = cloudSettings.email;
        if (!email.length) email = [CloudUtils firstCloudAccount];
        
        [setCloudEmailAlertView textFieldAtIndex:0].text = email;
        [setCloudEmailAlertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
    }
    else {
        [self enableRemoteAccess:NO];
    }
}

- (IBAction)onSkip:(id)sender {
    if (!self.wizardCloudSettings.enabled && !self.cloudEmailWarningWasShown) {
        [self showCloudEmailWarning];
        self.cloudEmailWarningWasShown = YES;
    } else {
        [self showRainMachineSetUpSuccessfulAlert];
    }
}

- (IBAction)onSave:(id)sender {
    NSString *email = self.emailAddressTextField.text;
    if (!email.isValidEmail) {
        UIAlertView *invalidEmailAlertView = [[UIAlertView alloc] initWithTitle:@"Invalid email address"
                                                                        message:@"Please enter a valid email address"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
        invalidEmailAlertView.tag = kRemoteAccess_InvalidEmail_AlertView_Tag;
        [invalidEmailAlertView show];
        return;
    }
    
    [self.emailAddressTextField resignFirstResponder];
    [self saveCloudEmail:email];
}

- (void)showCloudEmailWarning {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"In order to remotely access your RainMachine, you need to provide a valid email."
                                                       delegate:self
                                              cancelButtonTitle:@"Back"
                                              otherButtonTitles:@"Skip",nil];
    alertView.tag = kRemoteAccess_CloudEmailWarning_AlertView_Tag;
    [alertView show];
}

- (void)showRainMachineSetUpSuccessfulAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Congratulations. Your RainMachine is ready to use. Please setup your watering programs."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    alertView.tag = kRemoteAccess_FinishRainmachineSetup_AlertView_Tag;
    [alertView show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kRemoteAccess_SetCloudEmail_AlertView_Tag) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [self.tableView reloadData];
        }
        else if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString *email = [alertView textFieldAtIndex:0].text;
            if (!email.isValidEmail) {
                UIAlertView *invalidEmailAlertView = [[UIAlertView alloc] initWithTitle:@"Invalid email address"
                                                                                message:@"Please enter a valid email address"
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                invalidEmailAlertView.tag = kRemoteAccess_InvalidEmail_AlertView_Tag;
                [invalidEmailAlertView show];
                [self.tableView reloadData];
            } else {
                [self saveCloudEmail:email];
            }
        }
    }
    else if (alertView.tag == kRemoteAccess_FinishRainmachineSetup_AlertView_Tag) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.devicesVC deviceSetupFinished];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    else if (alertView.tag == kRemoteAccess_CloudEmailWarning_AlertView_Tag) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self showRainMachineSetUpSuccessfulAlert];
        }
    }
    else if (alertView.tag == kRemoteAccess_VerificationEmail_AlertView_Tag) {
        if (self.isPartOfWizard) {
            [self performSelector:@selector(showRainMachineSetUpSuccessfulAlert)
                       withObject:nil
                       afterDelay:0.2];
        }
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.saveCloudEmailServerProxy) {
        if (self.isPartOfWizard) {
            self.wizardCloudSettings.pendingEmail = self.currentPendingEmail;
        } else {
            [GlobalsManager current].cloudSettings.pendingEmail = self.currentPendingEmail;
            self.dbSprinkler.pendingEmail = self.currentPendingEmail;
        }
        
        self.saveCloudEmailServerProxy = nil;
        
        [self enableRemoteAccess:YES];
    }
    else if (serverProxy == self.enableRemoteAccessServerProxy) {
        if (self.isPartOfWizard) {
            self.wizardCloudSettings.enabled = self.currentRemoteAccessEnabled;
        } else {
            [GlobalsManager current].cloudSettings.enabled = self.currentRemoteAccessEnabled;
        }
        
        self.enableRemoteAccessServerProxy = nil;
        
        if (self.currentRemoteAccessEnabled) {
            [self validateEmail:self.currentPendingEmail showProgress:YES];
        }
    }
    else if (serverProxy == self.emailValidatorServerProxy) {
        NSString *email = (self.isPartOfWizard ? self.emailAddressTextField.text : self.currentPendingEmail);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:[NSString stringWithFormat:@"For your own security, a verification email has been sent to %@. Please open the email and click the link to verify it. You might want to check your Spam folder too.",email]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = kRemoteAccess_VerificationEmail_AlertView_Tag;
        [alertView show];
        
        if (!self.isPartOfWizard) [self refreshCloudSettings];
        else {
            if ([CloudUtils existsCloudAccountWithEmail:email]) [CloudUtils updateCloudAccountWithEmail:email newPassword:self.sprinkler.password];
            else [CloudUtils addCloudAccountWithEmail:email password:self.sprinkler.password];
        }
        self.emailValidatorServerProxy = nil;
        
        [[GlobalsManager current] startPollingCloudSettings];
    }
    else if (serverProxy == self.refreshCloudSettingsServerProxy) {
        [GlobalsManager current].cloudSettings = (CloudSettings*)data;
        self.refreshCloudSettingsServerProxy = nil;
    }
    
    
    [self refreshProgressHUD];
    if (!self.hud) [self.tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.enableRemoteAccessServerProxy) self.enableRemoteAccessServerProxy = nil;
    else if (serverProxy == self.saveCloudEmailServerProxy) self.saveCloudEmailServerProxy = nil;
    else if (serverProxy == self.refreshCloudSettingsServerProxy) self.refreshCloudSettingsServerProxy = nil;
    else if (serverProxy == self.emailValidatorServerProxy) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failure sending confirmation email"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        self.emailValidatorServerProxy = nil;
    }
    
    [self refreshProgressHUD];
    if (!self.hud) [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
