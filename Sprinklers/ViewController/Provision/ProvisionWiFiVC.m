//
//  ProvisionWiFiVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 01/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionWiFiVC.h"
#import "LabelAndTextFieldCell.h"
#import "ProvisionSelectWiFiSecurityOptionVC.h"
#import "+UIDevice.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "Constants.h"

#define kProvisionWiFi_SSID 1
#define kProvisionWiFi_Password 2

@interface ProvisionWiFiVC ()

@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL showSecurity;
@property (nonatomic, assign) BOOL forceShowKeyboard;
@property (strong, nonatomic) ServerProxy *provisionServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation ProvisionWiFiVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.forceShowKeyboard = YES;
    
    // Show security option when it is unknown
    self.showSecurity = (self.securityOption == nil);
    if (!self.securityOption) {
        self.securityOption = @"None";
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"LabelAndTextFieldCell" bundle:nil] forCellReuseIdentifier:@"LabelAndTextFieldCell"];
    
    self.title = @"Enter Password";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Join"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(join)];

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }

    [self refreshUI];
    
    self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
}

- (void)refreshUI
{
    self.navigationItem.rightBarButtonItem.enabled = (self.password.length > 0) && (self.SSID.length > 0);
}

- (void)dismiss
{
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        if ([cell isKindOfClass:[LabelAndTextFieldCell class]]) {
            LabelAndTextFieldCell *labelAndTextFieldCell = (LabelAndTextFieldCell*)cell;
            [labelAndTextFieldCell.textField resignFirstResponder];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel
{
    [self dismiss];
}

- (void)join
{
    [self.delegate joinWiFi:self.SSID encryption:[self APISecurityOptionFromUIText] key:self.password sprinklerId:self.sprinkler.sprinklerId];

    [self dismiss];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self sectionForSecurity] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self sectionForSSID]) {
        return 1;
    }
    
    if (section == [self sectionForSecurity]) {
        return [self rowForPassword] + 1;
    }
    
    return 1;
}

- (int)sectionForSSID
{
    return self.showSSID ? 0 : -1;
}

- (int)sectionForSecurity
{
    return [self sectionForSSID] + 1;
}

- (int)rowForSecurity
{
    return self.showSecurity ? 0 : -1;
}

- (int)rowForPassword
{
    return [self rowForSecurity] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (indexPath.section == [self sectionForSSID]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LabelAndTextFieldCell" forIndexPath:indexPath];
        LabelAndTextFieldCell *labelAndTextFieldCell = (LabelAndTextFieldCell*)cell;
        labelAndTextFieldCell.textField.text = self.SSID;
        labelAndTextFieldCell.textField.placeholder = @"Network Name";
        labelAndTextFieldCell.textField.delegate = self;
        labelAndTextFieldCell.textField.secureTextEntry = YES;
        labelAndTextFieldCell.textField.tag = kProvisionWiFi_SSID;
        labelAndTextFieldCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (self.forceShowKeyboard) {
            self.forceShowKeyboard = NO;
            [labelAndTextFieldCell.textField becomeFirstResponder];
        }
    }
    else if (indexPath.section == [self sectionForSecurity]) {
        if (indexPath.row == [self rowForSecurity]) {
            cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Debug"];
            }
            cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
            cell.textLabel.text = @"Security";
            cell.detailTextLabel.text = self.securityOption;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if (indexPath.row == [self rowForPassword]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"LabelAndTextFieldCell" forIndexPath:indexPath];
            LabelAndTextFieldCell *labelAndTextFieldCell = (LabelAndTextFieldCell*)cell;
            labelAndTextFieldCell.titleLabel.text = @"Password";
            labelAndTextFieldCell.textField.text = self.password;
            labelAndTextFieldCell.textField.placeholder = @"";
            labelAndTextFieldCell.textField.delegate = self;
            labelAndTextFieldCell.textField.secureTextEntry = YES;
            labelAndTextFieldCell.textField.tag = kProvisionWiFi_Password;
            labelAndTextFieldCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.forceShowKeyboard) {
                self.forceShowKeyboard = NO;
                [labelAndTextFieldCell.textField becomeFirstResponder];
            }
        }
    }

    assert(cell);
    
    return cell;
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == [self sectionForSecurity]) {
        if (indexPath.row == [self rowForSecurity]) {
            ProvisionSelectWiFiSecurityOptionVC *selectSecurityOptionVC = [[ProvisionSelectWiFiSecurityOptionVC alloc] initWithDelegate:self];
            selectSecurityOptionVC.selectedIndex = [NSIndexPath indexPathForRow:[ProvisionSelectWiFiSecurityOptionVC indexForSecurityOption:self.securityOption] inSection:0];

            [self.navigationController pushViewController:selectSecurityOptionVC animated:YES];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (NSString*)APISecurityOptionFromUIText
{
    if ([self.securityOption isEqualToString:@"None"]) {
        return @"none";
    }
    else if ([self.securityOption isEqualToString:@"PSK"]) {
        return @"psk";
    }
    else if ([self.securityOption isEqualToString:@"PSK2"]) {
        return @"psk2";
    }

    return nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == kProvisionWiFi_Password) {
        self.password = newString;
    }
    if (textField.tag == kProvisionWiFi_SSID) {
        self.SSID = newString;
    }
    
    [self refreshUI];
    
    return YES;
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.provisionServerProxy) {
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionServerProxy) {
//    TODO: handle error code
    }
    
    [self hideHud];
    
    [self refreshUI];
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
