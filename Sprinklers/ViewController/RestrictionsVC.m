//
//  RestrictionsVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 07/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsVC.h"
#import "SettingsRestrictionsHotDaysCell.h"
#import "RestrictedMonthsVC.h"
#import "RestrictionsWeekDaysVC.h"

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
    
    [_tableView registerNib:[UINib nibWithNibName:@"SettingsRestrictionsHotDaysCell" bundle:nil] forCellReuseIdentifier:@"SettingsRestrictionsHotDaysCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (indexPath.row == 0)
    {
        SettingsRestrictionsHotDaysCell* settingsRestrictionsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsRestrictionsHotDaysCell" forIndexPath:indexPath];
        
        settingsRestrictionsCell.textLabel.text = @"Hot Days";
        settingsRestrictionsCell.detailTextLabel.text = @"Allow extra watering";  //TODO: Get correct information.
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
    
    switch (indexPath.row) {
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
            
        default:
            break;
    }
}

@end
