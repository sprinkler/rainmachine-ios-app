//
//  RestrictionsVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 07/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsVC.h"
#import "RestrictedMonthsVC.h"
#import "RestrictionsWeekDaysVC.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "StorageManager.h"
#import "RestrictionsData.h"
#import "PickerVC.h"
#import "SettingsHoursVC.h"
#import "Utils.h"

@interface RestrictionsVC ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation RestrictionsVC

#pragma Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Restrictions";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate: self jsonRequest: NO];
    
    [_tableView registerNib:[UINib nibWithNibName: @"SettingsRestrictionsHotDaysCell" bundle:nil] forCellReuseIdentifier: @"SettingsRestrictionsHotDaysCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //TODO: Load current sprinkler from SettingsManager here and update content if needed.
    [self.serverProxy requestWateringRestrictions];
    [self startHud:nil]; // @"Receivivfgfggng data..."
    
    [self refreshStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.serverProxy cancelAllOperations];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}
    
- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)refreshStatus
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy {
    [self.hud hide:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Network error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    DLog(@"%s", __PRETTY_FUNCTION__);
    [self.hud hide:YES];
    
    // NSMutableArray* restrictionsDataArray = data;
    //RestrictionsData* restrictionsData = restrictionsDataArray[0];

    [_tableView reloadData];
}

- (void)handleLoggedOutSprinklerError {
    NSString *errorTitle = @"Logged out";
//    [StorageManager current].currentSprinkler.lastError = errorTitle;
//    [[StorageManager current] saveData];
    
    self.alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView.tag = kLoggedOut_AlertViewTag;
    [self.alertView show];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

    return 20.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.row == 0)
    {
        //add a switch
        UISwitch *switchview = [[UISwitch alloc] initWithFrame: CGRectZero];
        cell.accessoryView = switchview;
        
        cell.textLabel.text = @"Hot Days";
        cell.detailTextLabel.text = @"Allow extra watering";
    }
    
    if (indexPath.row == 1) {
        cell.textLabel.text = @"Freeze Protect";
        cell.detailTextLabel.text = @"Do not water under 38° F";  //TODO: Get correct temperature.
    }
    if (indexPath.row == 2) {
        cell.textLabel.text = @"Months";
        cell.detailTextLabel.text = @"Jan, Feb, Nov, Dec";  //TODO: Get correct months.
    }
    if (indexPath.row == 3) {
        cell.textLabel.text = @"Weekdays";
        cell.detailTextLabel.text = @"Mon, Wed";  //TODO: Get correct days.
    }
    if (indexPath.row == 4) {
        cell.textLabel.text = @"Hours";
        cell.detailTextLabel.text = @"Every day 7:30 AM - 6:00 PM";  //TODO: Get correct hours.
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    
    switch (indexPath.row)
    {
        case 1:
        {
            PickerVC *pickerVC = [[PickerVC alloc] init];
            [self.navigationController pushViewController:pickerVC animated:YES];
        }break;
            
        case 2:
        {
            RestrictedMonthsVC *restrictedMonths = [[RestrictedMonthsVC alloc] init];
            [self.navigationController pushViewController: restrictedMonths animated:YES];
        }
        break;
                
        case 3:
        {
            RestrictionsWeekDaysVC *restrictionsWeekDaysVC = [[RestrictionsWeekDaysVC alloc] init];
            [self.navigationController pushViewController: restrictionsWeekDaysVC animated:YES];
        }
        break;

        case 4:
        {
            SettingsHoursVC *settingsHoursVC = [[SettingsHoursVC alloc] init];
            [self.navigationController pushViewController: settingsHoursVC animated:YES];
        }
        break;
            
        default:
            break;
    }
}

@end
