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
#import "RestrictionsVC.h"
#import "UnitsVC.h"
#import "DatePickerVC.h"
#import "SettingsTimePickerVC.h"
#import "SettingsPasswordVC.h"
#import "ServerProxy.h"

@interface SettingsVC ()
{
    BOOL showZonesOnAppear;
}

@property (nonatomic, readonly) BOOL restrictionsAvailable;
@property (nonatomic, readonly) NSInteger programsSection;
@property (nonatomic, readonly) NSInteger rainDelaySection;
@property (nonatomic, readonly) NSInteger restrictionsSection;
@property (nonatomic, readonly) NSInteger deviceSettingsSection;
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

#pragma mark - Table view sections

- (BOOL)restrictionsAvailable
{
    return [ServerProxy usesAPI4];
}

- (NSInteger)programsSection
{
    return 0;
}

- (NSInteger)rainDelaySection
{
    return 1;
}

- (NSInteger)restrictionsSection
{
    return (self.restrictionsAvailable ? 2 : -1);
}

- (NSInteger)deviceSettingsSection
{
    return (self.restrictionsAvailable ? 3 : 2);
}


#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.restrictionsAvailable ? 4 : 3);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == self.programsSection) {
        return 2;
    }
    else if (section == self.rainDelaySection) {
        return 1;
    }
    else if (section == self.restrictionsSection) {
        return 1;
    }
    else if (section == self.deviceSettingsSection) {
        return 5;
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == (self.restrictionsAvailable ? 3 : 2)) {
        return @"Device Settings";
    }
    
    return @"";
}

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
    
    if (indexPath.section == self.programsSection)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Programs";
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Zones";
        }
    }
    
    if (indexPath.section == self.rainDelaySection) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Rain Delay";
        }
    }
    
    if (indexPath.section == self.restrictionsSection) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Restrictions";
        }
    }

    if (indexPath.section == self.deviceSettingsSection)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Units";
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Date";
        }
        if (indexPath.row == 2) {
            cell.textLabel.text = @"Time";
        }
        if (indexPath.row == 3) {
            cell.textLabel.text = @"Security";
        }
    
        if (indexPath.row == 4) {
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
    
    if (indexPath.section == self.programsSection) {
        if (indexPath.row == 0) {
            ProgramsVC *programs = [[ProgramsVC alloc] init];
            programs.parent = self;
            [self.navigationController pushViewController:programs animated:YES];
        }
        if (indexPath.row == 1) {
            [self showZonesAnimated:YES];
        }
    }
    else if (indexPath.section == self.rainDelaySection) {
        if (indexPath.row == 0) {
            RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
            rainDelay.parent = self;
            [self.navigationController pushViewController:rainDelay animated:YES];
        }
    }
    else if (indexPath.section == self.restrictionsSection) {
        if (indexPath.row == 0) {
            RestrictionsVC *restrictions = [[RestrictionsVC alloc] init];
            restrictions.parent = self;
            [self.navigationController pushViewController:restrictions animated:YES];
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UnitsVC *unitsVC = [[UnitsVC alloc] init];
            unitsVC.parent = self;
            [self.navigationController pushViewController:unitsVC animated:YES];
        }
        else if (indexPath.row == 1) {
            DatePickerVC *datePickerVC = [[DatePickerVC alloc] init];
            datePickerVC.parent = self;
            [self.navigationController pushViewController:datePickerVC animated:YES];
        }
        else if (indexPath.row == 2) {
            SettingsTimePickerVC *timePickerVC = [[SettingsTimePickerVC alloc] initWithNibName:@"SettingsTimePickerVC" bundle:nil];
            timePickerVC.parent = self;
            [self.navigationController pushViewController:timePickerVC animated:YES];
        }
        else if (indexPath.row == 3) {
            SettingsPasswordVC *passwordVC = [[SettingsPasswordVC alloc] init];
            passwordVC.parent = self;
            [self.navigationController pushViewController:passwordVC animated:YES];
        }
        else if (indexPath.row == 4) {
            SettingsAboutVC *settingsAboutVC = [[SettingsAboutVC alloc] init];
            [self.navigationController pushViewController:settingsAboutVC animated:YES];
        }
    }
}

- (void)timePickerVCWillDissapear:(id)timePicker
{
}

@end
