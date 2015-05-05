//
//  NetworkSettingsVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 05/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "NetworkSettingsVC.h"
#import "PortForwardSettingsVC.h"
#import "Constants.h"
#import "Utils.h"

#pragma mark -

@interface NetworkSettingsVC ()

- (IBAction)onClose:(id)sender;
- (IBAction)onSwitchLocalDiscovery:(UISwitch*)localDiscoverySwitch;

@end

#pragma mark -

@implementation NetworkSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Network Settings";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(onClose:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *NetworkSettingsCellIdentifier = @"NetworkSettingsCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NetworkSettingsCellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NetworkSettingsCellIdentifier];
    
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Disable Local Discovery";
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        UISwitch *localDiscoverySwitch = [UISwitch new];
        localDiscoverySwitch.on = [Utils localDiscoveryDisabled];
        [localDiscoverySwitch addTarget:self action:@selector(onSwitchLocalDiscovery:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = localDiscoverySwitch;
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = @"Port Forward Settings";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *localDiscoverySwitch = (UISwitch*)cell.accessoryView;
        localDiscoverySwitch.on = !localDiscoverySwitch.isOn;
        [self onSwitchLocalDiscovery:localDiscoverySwitch];
    }
    else if (indexPath.section == 1) {
        PortForwardSettingsVC *portForwardSettingsVC = [[PortForwardSettingsVC alloc] init];
        portForwardSettingsVC.portForwardSprinklers = self.portForwardSprinklers;
        [self.navigationController pushViewController:portForwardSettingsVC animated:YES];
    }
}

#pragma mark - Actions

- (IBAction)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSwitchLocalDiscovery:(UISwitch*)localDiscoverySwitch {
    [Utils setLocalDiscoveryDisabled:localDiscoverySwitch.isOn];
}

@end
