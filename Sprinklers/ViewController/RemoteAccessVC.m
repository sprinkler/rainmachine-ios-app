//
//  RemoteAccessVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "RemoteAccessVC.h"
#import "GlobalsManager.h"
#import "ServerProxy.h"
#import "CloudSettings.h"
#import "Additions.h"
#import "Utils.h"
#import "MBProgressHUD.h"

#define kRemoteAccess_SetCloudEmail_AlertView_Tag       1000
#define kRemoteAccess_InvalidEmail_AlertView_Tag        1001

#pragma mark -

@interface RemoteAccessVC ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) ServerProxy *enableRemoteAccessServerProxy;
@property (nonatomic, strong) ServerProxy *saveCloudEmailServerProxy;
@property (nonatomic, strong) ServerProxy *refreshCloudSettingsServerProxy;

- (void)refreshProgressHUD;
- (void)enableRemoteAccess:(BOOL)enable;
- (void)saveCloudEmail:(NSString*)email;
- (void)refreshCloudSettings;

- (IBAction)onEnableCloudEmail:(UISwitch*)enableCloudEmailSwitch;

@end

#pragma mark -

@implementation RemoteAccessVC

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Set remote access";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)refreshProgressHUD {
    BOOL shouldDisplayProgressHUD = (self.enableRemoteAccessServerProxy || self.saveCloudEmailServerProxy || self.refreshCloudSettingsServerProxy);
    if (shouldDisplayProgressHUD && !self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    else if (!shouldDisplayProgressHUD && self.hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.hud = nil;
    }
}

- (void)enableRemoteAccess:(BOOL)enable {
    self.enableRemoteAccessServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.enableRemoteAccessServerProxy enableRemoteAccess:enable];
    [self refreshProgressHUD];
}

- (void)saveCloudEmail:(NSString*)email {
    self.saveCloudEmailServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveCloudEmailServerProxy saveCloudEmail:email];
    [self refreshProgressHUD];
}

- (void)refreshCloudSettings {
    self.refreshCloudSettingsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.refreshCloudSettingsServerProxy requestCloudSettings];
    [self refreshProgressHUD];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
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
    
    CloudSettings *cloudSettings = [GlobalsManager current].cloudSettings;
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
        // TODO: Resend confirmation email
    }
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
        
        CloudSettings *cloudSettings = [GlobalsManager current].cloudSettings;
        NSString *email = cloudSettings.pendingEmail;
        if (!email.length) email = cloudSettings.email;
        
        [setCloudEmailAlertView textFieldAtIndex:0].text = email;
    }
    else {
        [self enableRemoteAccess:NO];
    }
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
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.enableRemoteAccessServerProxy) {
        self.enableRemoteAccessServerProxy = nil;
        [self refreshCloudSettings];
    }
    else if (serverProxy == self.saveCloudEmailServerProxy) {
        self.saveCloudEmailServerProxy = nil;
        [self enableRemoteAccess:YES];
    }
    else if (serverProxy == self.refreshCloudSettingsServerProxy) {
        [GlobalsManager current].cloudSettings = (CloudSettings*)data;
        self.refreshCloudSettingsServerProxy = nil;
        [self.tableView reloadData];
    }
    
    [self refreshProgressHUD];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.enableRemoteAccessServerProxy) self.enableRemoteAccessServerProxy = nil;
    else if (serverProxy == self.saveCloudEmailServerProxy) self.saveCloudEmailServerProxy = nil;
    else if (serverProxy == self.refreshCloudSettingsServerProxy) self.refreshCloudSettingsServerProxy = nil;
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
