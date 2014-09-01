//
//  UnitsVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 27/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "UnitsVC.h"
#import "SettingsUnits.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ServerResponse.h"
#import "SettingsVC.h"
#import "Utils.h"
#import "+UIDevice.h"
#import "AppDelegate.h"
#import "StatsVC.h"
#import "ServerProxy.h"

@interface UnitsVC ()
{
}

@property (strong, nonatomic) SettingsUnits *settingsUnits;
@property (strong, nonatomic) ServerProxy *pullServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString *unitsBeforeSave;

@end

@implementation UnitsVC

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self.tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];

    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.pullServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    if ([ServerProxy usesAPI3]) {
        [self.pullServerProxy requestSettingsUnits];
    } else {
        self.settingsUnits = [SettingsUnits new];
        self.settingsUnits.units = [Utils sprinklerTemperatureUnits];
        [self serverResponseReceived:self.settingsUnits serverProxy:self.pullServerProxy userInfo:nil];
    }
    
    self.title = @"Units";
}

- (void)save
{
    if ((self.settingsUnits) && (!self.postServerProxy) && (!self.pullServerProxy)) {
            // If we save the same unit again the server returns error: "Units not saved"
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        // The server proxy still needs to be created (becaue we use its valeu in serverResponseReceived)
        self.postServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        if ([ServerProxy usesAPI3]) {
            [self.postServerProxy setSettingsUnits:self.settingsUnits.units];
        } else {
            [Utils setSprinklerTemperatureUnits:self.settingsUnits.units];
            [self serverResponseReceived:nil serverProxy:self.postServerProxy userInfo:nil];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.settingsUnits ? 2 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SimpleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Fahrenheit";
        cell.accessoryType = [self.settingsUnits.units isEqualToString:@"F"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"Celsius";
        cell.accessoryType = [self.settingsUnits.units isEqualToString:@"C"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *otherIndexPath = [NSIndexPath indexPathForRow:1 - indexPath.row inSection:indexPath.section];
    UITableViewCell *otherCell = [self.tableView cellForRowAtIndexPath:otherIndexPath];
    otherCell.accessoryType = UITableViewCellAccessoryNone;
    
    UITableViewCell *selCell = [self.tableView cellForRowAtIndexPath:indexPath];
    selCell.accessoryType =UITableViewCellAccessoryCheckmark;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.settingsUnits.units = (indexPath.row == 0) ? @"F" : @"C";
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.pullServerProxy) {
        self.pullServerProxy = nil;
    }
    else if (serverProxy == self.postServerProxy) {
        self.postServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.tableView reloadData];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.pullServerProxy) {
        self.settingsUnits = data;
        self.unitsBeforeSave = self.settingsUnits.units;
        self.pullServerProxy = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    }
    else if (serverProxy == self.postServerProxy) {
        self.unitsBeforeSave = self.settingsUnits.units;
        self.postServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.statsVC setUnitsText:self.settingsUnits.units];
        }
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
