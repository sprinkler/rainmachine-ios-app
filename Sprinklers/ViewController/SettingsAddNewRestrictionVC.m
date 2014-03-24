//
//  SettingsAddNewRestrictionVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsAddNewRestrictionVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"

@interface SettingsAddNewRestrictionVC ()

@property (strong, nonatomic) IBOutlet ColoredBackgroundButton *buttonSety;

@end

@implementation SettingsAddNewRestrictionVC
    
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }
    
    self.title = @"Add Restriction";
    
    [_buttonSety setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Add New restriction button
    switch (section)
    {
        case 0:
            return 2;
        break;
            
        case 1:
            return 1;
        break;
            
        case 2:
            return 1;
        break;
    }
    
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
    
    if (indexPath.section == 0)
    {
        static NSString *CellIdentifier1 = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: CellIdentifier1];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
        
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"From";
            cell.detailTextLabel.text = @"06:00 AM";
        }
        
        if (indexPath.row == 1)
        {
            cell.textLabel.text = @"To";
            cell.detailTextLabel.text = @"12:00 PM";
        }
    }
    
    if (indexPath.section == 1 && indexPath.row == 0)
    {
        static NSString *CellIdentifier1 = @"Cell1";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier1];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = @"Daily";
    }
    
    if (indexPath.section == 2 && indexPath.row == 0)
    {
        static NSString *CellIdentifier1 = @"Cell1";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier1];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = @"Weekdays";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath: indexPath animated:YES];
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
