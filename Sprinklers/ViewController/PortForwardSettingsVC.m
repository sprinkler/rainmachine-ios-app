//
//  PortForwardSettingsVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 04/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "PortForwardSettingsVC.h"
#import "AddNewDeviceVC.h"
#import "AddNewCell.h"
#import "Constants.h"
#import "Sprinkler.h"
#import "Utils.h"
#import "StorageManager.h"
#import "+UILabel.h"

#pragma mark -

@interface PortForwardSettingsVC ()

@property (nonatomic, strong) NSMutableArray *portForwardSprinklers;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) AddNewDeviceVC *addNewDeviceVC;

- (void)updateEditButton;

@end

#pragma mark -

@implementation PortForwardSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Direct Access";
    
    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = self.editBarButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
    [self updateEditButton];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.portForwardSprinklers = [[Utils manuallyEnteredSprinklers] mutableCopy];
    [self.portForwardSprinklers sortUsingComparator:^NSComparisonResult(Sprinkler *sprinkler1, Sprinkler *sprinkler2) {
        return [sprinkler1.name compare:sprinkler2.name];
    }];
    
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
    self.navigationItem.rightBarButtonItem.enabled = (self.portForwardSprinklers.count > 0);
    if (self.portForwardSprinklers.count == 0 && self.tableView.editing) {
        [self edit:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.portForwardSprinklers.count;
    if (section == 1) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *PortForwardDeviceCellIdentifier = @"PortForwardDeviceCellIdentifier";
        
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:PortForwardDeviceCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PortForwardDeviceCellIdentifier];
        
        Sprinkler *sprinkler = self.portForwardSprinklers[indexPath.row];
        
        cell.textLabel.text = sprinkler.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSString *adressWithoutPrefix = [Utils addressWithoutPrefix:sprinkler.address];
        
        if ([sprinkler.port isEqual: @"443"]) {
            cell.detailTextLabel.text = sprinkler.port ? [NSString stringWithFormat:@"%@", adressWithoutPrefix] : sprinkler.address;
        }
        else {
            cell.detailTextLabel.text = sprinkler.port ? [NSString stringWithFormat:@"%@:%@", adressWithoutPrefix, sprinkler.port] : sprinkler.address;
        }
        
        return cell;
    }
    
    // Add Cloud Account
    AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
    cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
    [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
    
    [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
    
    cell.titleLabel.text = @"Add Device";
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Sprinkler *sprinkler = [self.portForwardSprinklers objectAtIndex:indexPath.row];
        if (sprinkler == [StorageManager current].currentSprinkler) {
            [Utils invalidateLoginForCurrentSprinkler];
            self.currentSprinklerDeleted = YES;
        }
        [[StorageManager current] deleteSprinkler:sprinkler];
        
        NSMutableArray *portForwardSprinklers = [self.portForwardSprinklers mutableCopy];
        [portForwardSprinklers removeObjectAtIndex:indexPath.row];
        self.portForwardSprinklers = portForwardSprinklers;
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateEditButton];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        self.addNewDeviceVC = [[AddNewDeviceVC alloc] init];
        self.addNewDeviceVC.parent = self;
        self.addNewDeviceVC.edit = YES;
        self.addNewDeviceVC.sprinkler = self.portForwardSprinklers[indexPath.row];
        
        [self.navigationController pushViewController:self.addNewDeviceVC animated:YES];
    } else {
        self.addNewDeviceVC = [[AddNewDeviceVC alloc] init];
        self.addNewDeviceVC.parent = self;
        [self.navigationController pushViewController:self.addNewDeviceVC animated:YES];
    }
}

@end
