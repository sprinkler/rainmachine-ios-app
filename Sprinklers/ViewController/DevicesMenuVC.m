//
//  DevicesMenuVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 04/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DevicesMenuVC.h"
#import "CloudAccountsVC.h"
#import "NetworkSettingsVC.h"
#import "AddNewDeviceVC.h"
#import "Additions.h"
#import "Constants.h"

NSInteger DevicesMenuAccountSettingsSection     = 0;
NSInteger DevicesMenuNetworkSettingsSection     = 1;

#pragma mark -

@interface DevicesMenuVC ()

@property (nonatomic, strong) CloudAccountsVC *cloudAccountsVC;
@property (nonatomic, strong) NetworkSettingsVC *networkSettingsVC;

@end

#pragma mark -

@implementation DevicesMenuVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Devices";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(onClose:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.cloudAccountsVC) {
        self.cloudEmails = self.cloudAccountsVC.cloudEmails;
        self.cloudAccountsVC = nil;
    }
    
    if (self.networkSettingsVC) {
        self.networkSettingsVC = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == DevicesMenuAccountSettingsSection) return 1;
    if (section == DevicesMenuNetworkSettingsSection) return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *DevicesMenuCellIdentifier = @"DevicesMenuCellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DevicesMenuCellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DevicesMenuCellIdentifier];
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.section == DevicesMenuAccountSettingsSection) cell.textLabel.text = @"Account Settings";
    else if (indexPath.section == DevicesMenuNetworkSettingsSection) cell.textLabel.text = @"Network Settings";

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == DevicesMenuAccountSettingsSection) {
        self.cloudAccountsVC = [[CloudAccountsVC alloc] init];
        self.cloudAccountsVC.cloudResponse = self.cloudResponse;
        self.cloudAccountsVC.cloudSprinklers = self.cloudSprinklers;
        self.cloudAccountsVC.cloudEmails = self.cloudEmails;
        [self.navigationController pushViewController:self.cloudAccountsVC animated:YES];
    }
    else if (indexPath.section == DevicesMenuNetworkSettingsSection) {
        self.networkSettingsVC = [[NetworkSettingsVC alloc] init];
        self.networkSettingsVC.portForwardSprinklers = self.manuallyEnteredSprinkler;
        [self.navigationController pushViewController:self.networkSettingsVC animated:YES];
    }
}

@end
