//
//  SettingsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SettingsAboutVC.h"
#import "SettingsVC.h"
#import "Additions.h"
#import "ProgramsVC.h"
#import "ZonesVC.h"
#import "RainDelayVC.h"
#import "UnitsVC.h"
#import "DatePickerVC.h"
#import "SettingsTimePickerVC.h"
#import "SettingsPasswordVC.h"

@interface SettingsVC ()
{
    BOOL showZonesOnAppear;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSettingsZonesNotif) name:kShowSettingsZones object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (showZonesOnAppear) {
        showZonesOnAppear = NO;
        [self showZonesAnimated:NO];
    }
}

- (void)showZonesAnimated:(BOOL)animated
{
    ZonesVC *zones = [[ZonesVC alloc] init];
    [self.navigationController pushViewController:zones animated:animated];
}

- (void)showSettingsZonesNotif
{
    showZonesOnAppear = YES;
    self.tabBarController.selectedViewController = self.navigationController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    else if (section == 1) {
        return 1;
    }
    else if (section == 2) {
        return 6;
    }
    
    return 0;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 20;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 1;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
//    return view;
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == 2) {
//        if (indexPath.row == 0) {
//            return 38;
//        }
//    }
//    return 44;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Programs";
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Zone";
        }
    }
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Rain Delay";
        }
    }
    
    if (indexPath.section == 2)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Device Settings";
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
                cell.separatorInset = UIEdgeInsetsZero;
            }
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Units";
        }
        if (indexPath.row == 2) {
            cell.textLabel.text = @"Date";
        }
        if (indexPath.row == 3) {
            cell.textLabel.text = @"Time";
        }
        if (indexPath.row == 4) {
            cell.textLabel.text = @"Security";
        }
        
        if (indexPath.row == 5) {
            cell.textLabel.text = @"About";
        }
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProgramsVC *programs = [[ProgramsVC alloc] init];
            programs.parent = self;
            [self.navigationController pushViewController:programs animated:YES];
        }
        if (indexPath.row == 1) {
            [self showZonesAnimated:YES];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
            rainDelay.parent = self;
            [self.navigationController pushViewController:rainDelay animated:YES];
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 1) {
            UnitsVC *unitsVC = [[UnitsVC alloc] init];
            unitsVC.parent = self;
            [self.navigationController pushViewController:unitsVC animated:YES];
        }
        else if (indexPath.row == 2) {
            DatePickerVC *datePickerVC = [[DatePickerVC alloc] init];
            datePickerVC.parent = self;
            [self.navigationController pushViewController:datePickerVC animated:YES];
        }
        else if (indexPath.row == 3) {
            SettingsTimePickerVC *timePickerVC = [[SettingsTimePickerVC alloc] init];
            timePickerVC.parent = self;
            [self.navigationController pushViewController:timePickerVC animated:YES];
        }
        else if (indexPath.row == 4) {
            SettingsPasswordVC *passwordVC = [[SettingsPasswordVC alloc] init];
            passwordVC.parent = self;
            [self.navigationController pushViewController:passwordVC animated:YES];
        }
        else if (indexPath.row == 5) {
            SettingsAboutVC *settingsAboutVC = [[SettingsAboutVC alloc] init];
            [self.navigationController pushViewController:settingsAboutVC animated:YES];
        }
    }
}

- (void)timePickerVCWillDissapear:(id)timePicker
{
}

@end
