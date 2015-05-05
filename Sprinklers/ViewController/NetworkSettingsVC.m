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

#pragma mark -

@interface NetworkSettingsVC ()

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

#pragma mark - Actions

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        cell.textLabel.text = @"Local Discovery";
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        UISwitch *localDiscoverySwitch = [UISwitch new];
        localDiscoverySwitch.on = ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableLocalDiscoveryKey];
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
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *localDiscoverySwitch = (UISwitch*)cell.accessoryView;
        localDiscoverySwitch.on = !localDiscoverySwitch.isOn;
        [[NSUserDefaults standardUserDefaults] setBool:!localDiscoverySwitch.isOn forKey:kDisableLocalDiscoveryKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (indexPath.section == 1) {
        PortForwardSettingsVC *portForwardSettingsVC = [[PortForwardSettingsVC alloc] init];
        portForwardSettingsVC.portForwardSprinklers = self.portForwardSprinklers;
        [self.navigationController pushViewController:portForwardSettingsVC animated:YES];
    }
}

@end
