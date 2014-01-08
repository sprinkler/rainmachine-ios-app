//
//  SettingsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SettingsVC.h"
#import "Additions.h"
#import "ProgramsVC.h"
#import "ZonesVC.h"
#import "RainDelayVC.h"

@interface SettingsVC ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //TODO: Load current sprinkler from SettingsManager here and update content if needed.
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Programs Properties";
            cell.detailTextLabel.text = @"Next run: P2 at 06:45PST";  //TODO: Get correct next run.
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Zone Properties";
            cell.detailTextLabel.text = @"8 active, 4 inactive";  //TODO: Get correct zone numbers.
        }
    }
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Rain Delay";
            cell.detailTextLabel.text = @"0 days"; //TODO: Get correct delay;
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Restrictions";
            cell.detailTextLabel.text = @"Daily 09:30AM - 10:30AM"; //TODO: Get correct restrictions;
        }
    }

    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Device Settings";
            cell.detailTextLabel.text = @"Units, Locations, Data Sources & Types...";
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Statistics";
            cell.detailTextLabel.text = @"1 Month, 1 Year...";
        }
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row + (2 * indexPath.section)) {
        case 0: {
            ProgramsVC *programs = [[ProgramsVC alloc] init];
            [self.navigationController pushViewController:programs animated:YES];
        }
            break;
        case 1: {
            ZonesVC *zones = [[ZonesVC alloc] init];
            [self.navigationController pushViewController:zones animated:YES];
        }
            break;
        case 2: {
            RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
            [self.navigationController pushViewController:rainDelay animated:YES];
        }
            break;
        case 3:
            break;
        case 4:
            break;
        case 5:
            break;
        default:
            break;
    }
}

@end
