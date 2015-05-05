//
//  CloudAccountsVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 19/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "CloudAccountsVC.h"
#import "AddNewCell.h"
#import "Constants.h"
#import "+UILabel.h"
#import "AddNewDeviceVC.h"
#import "StorageManager.h"
#import "CloudUtils.h"
#import "Utils.h"

#pragma mark -

@interface CloudAccountsVC ()

@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) NSMutableDictionary *cloudResponsePerEmails;
@property (nonatomic, strong) AddNewDeviceVC *addCloudAccountVC;

- (void)updateEditButton;

@end

#pragma mark -

@implementation CloudAccountsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Account Settings";
    
    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = self.editBarButtonItem;

    NSArray *sprinklersByEmail = self.cloudResponse[@"sprinklersByEmail"];
    self.cloudResponsePerEmails = [NSMutableDictionary new];
    for (NSDictionary *cloudDict in sprinklersByEmail) {
        self.cloudResponsePerEmails[cloudDict[@"email"]] = cloudDict;
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
    
    [self updateEditButton];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSDictionary *cloudAccounts = [CloudUtils cloudAccounts];
    self.cloudEmails = [[cloudAccounts allKeys] mutableCopy];
    
    [self.cloudEmails sortUsingSelector:@selector(compare:)];
    
    [self.tableView reloadData];
    [self updateEditButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Edit mode

- (IBAction)edit:(id)sender {
    [self.tableView setEditing:!self.tableView.editing];
    if (self.tableView.editing) [self.editBarButtonItem setTitle:@"Done"];
    else [self.editBarButtonItem setTitle:@"Edit"];
    [self.tableView reloadData];
}

- (void)updateEditButton {
    self.navigationItem.rightBarButtonItem.enabled = (self.cloudEmails.count > 0);
    if (self.cloudEmails.count == 0 && self.tableView.editing) {
        [self edit:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.cloudEmails.count;
    if (section == 1) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CloudAccountCellIdentifier = @"CloudAccountCellIdentifier";
        
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:CloudAccountCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CloudAccountCellIdentifier];
        
        cell.textLabel.text = self.cloudEmails[indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
#if DEBUG
        NSDictionary *details = self.cloudResponsePerEmails[cell.textLabel.text];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"activeCount:%d knownCount:%d authCount:%d",
                                     [details[@"activeCount"] intValue],
                                     [details[@"knownCount"] intValue],
                                     [details[@"authCount"] intValue]];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
#endif
        
        return cell;
    }

    // Add Cloud Account
    AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
    cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
    [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
    
    [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    
    cell.titleLabel.text = @"Add Account";

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *cloudEmail = self.cloudEmails[indexPath.row];
        [CloudUtils deleteCloudAccountWithEmail:cloudEmail];
        [self.cloudEmails removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateEditButton];
        
        NSArray *remoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:nil];
        for (Sprinkler *sprinkler in remoteDevices) {
            if ([cloudEmail isEqualToString:sprinkler.email]) {
                if (sprinkler == [StorageManager current].currentSprinkler) {
                    [Utils invalidateLoginForCurrentSprinkler];
                    self.currentSprinklerDeleted = YES;
                }
                [[StorageManager current] deleteSprinkler:sprinkler];
            }
        }
        
        NSMutableDictionary *cloudSprinklers = [self.cloudSprinklers mutableCopy];
        [cloudSprinklers removeObjectForKey:cloudEmail];
        self.cloudSprinklers = cloudSprinklers;
                
        [self.tableView reloadData];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        AddNewDeviceVC *editCloudAccountVC = [[AddNewDeviceVC alloc] init];
        editCloudAccountVC.cloudUI = YES;
        editCloudAccountVC.edit = YES;
        
        NSString *cloudEmail = self.cloudEmails[indexPath.row];
        editCloudAccountVC.existingEmail = cloudEmail;
        editCloudAccountVC.existingPassword = [CloudUtils passwordForCloudAccountWithEmail:cloudEmail];
        
        [self.navigationController pushViewController:editCloudAccountVC animated:YES];
    } else {
        AddNewDeviceVC *addCloudAccountVC = [[AddNewDeviceVC alloc] init];
        addCloudAccountVC.cloudUI = YES;
        [self.navigationController pushViewController:addCloudAccountVC animated:YES];
    }
}

@end
