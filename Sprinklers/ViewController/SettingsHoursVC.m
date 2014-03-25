//
//  SettingsHoursVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsHoursVC.h"
#import "SettingsAddNewRestrictionVC.h"

@interface SettingsHoursVC ()

@end

@implementation SettingsHoursVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Restricted hours";
    
    self.restrictions = [NSMutableArray array];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0)
        return [_restrictions count];
    
    // Add New restriction button
    return 1;
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
    UIView *view = [[UIView alloc] initWithFrame: CGRectZero];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        static NSString *CellIdentifier1 = @"Cell1";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier1];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = @"Add New Restriction";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }   
    else
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        static NSString *CellIdentifier3 = @"Cell2";
        cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier3];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: CellIdentifier3];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.textLabel.text = @"Daily";
        cell.detailTextLabel.text = @"7:30 AM - 6:00 PM";
    }
    else
    if (indexPath.section == 0 && indexPath.row == 1)
    {   
        static NSString *CellIdentifier3 = @"Cell2";
        cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier3];
            
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: CellIdentifier3];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = @"Mon, Wed, Sun";
        cell.detailTextLabel.text = @"4:00 PM - 12:00 AM";
    }
    
    NSLog(@"indexPath is: %d %d", (int)indexPath.section, (int)indexPath.row);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath: indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 0)
    {
    }
    
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        SettingsAddNewRestrictionVC *settingsAddNewRestrictionVC = [[SettingsAddNewRestrictionVC alloc] init];
        [self.navigationController pushViewController: settingsAddNewRestrictionVC animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Deleted row.");
}

@end
