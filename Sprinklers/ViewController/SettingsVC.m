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
#import "RainSensitivityVC.h"
#import "UnitsVC.h"
#import "DatePickerVC.h"
#import "SettingsTimePickerVC.h"
#import "SettingsPasswordVC.h"
#import "ServerProxy.h"

NSString *kSettingsPrograms           = @"Programs";
NSString *kSettingsZones              = @"Zones";

NSString *kSettingsRainDelay          = @"Rain Delay";
NSString *kSettingsRestrictions       = @"Restrictions";

NSString *kSettingsRainSensitivity    = @"Rain Sensitivity";
NSString *kSettingsUnits              = @"Units";
NSString *kSettingsDate               = @"Date";
NSString *kSettingsTime               = @"Time";
NSString *kSettingsSecurity           = @"Security";
NSString *kSettingsAbout              = @"About";

@interface SettingsVC ()
{
    BOOL showZonesOnAppear;
}

@property (strong, nonatomic) NSArray *settings;
@property (strong, nonatomic) NSArray *settingsSectionNames;
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
    
    NSMutableArray *settings = [NSMutableArray new];
    
    [settings addObject:@[kSettingsPrograms, kSettingsZones]];
    if ([ServerProxy usesAPI4]) [settings addObject:@[kSettingsRainDelay, kSettingsRestrictions]];
    else [settings addObject:@[kSettingsRainDelay]];
    if ([ServerProxy usesAPI4]) [settings addObject:@[kSettingsRainSensitivity, kSettingsUnits, kSettingsDate, kSettingsTime, kSettingsSecurity, kSettingsAbout]];
    else [settings addObject:@[kSettingsUnits, kSettingsDate, kSettingsTime, kSettingsSecurity, kSettingsAbout]];
    
    self.settings = settings;
    self.settingsSectionNames = @[@"", @"", @"Device Settings"];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
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

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settings.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *settingsSection = self.settings[section];
    return settingsSection.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.settingsSectionNames[section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSArray *settingsSection = self.settings[indexPath.section];
    cell.textLabel.text = settingsSection[indexPath.row];
    
    if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *settingsSection = self.settings[indexPath.section];
    NSString *settingsRow = settingsSection[indexPath.row];
    
    // Section 1.
    
    if ([settingsRow isEqualToString:kSettingsPrograms]) {
        ProgramsVC *programs = [[ProgramsVC alloc] init];
        programs.parent = self;
        [self.navigationController pushViewController:programs animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsZones]) {
        [self showZonesAnimated:YES];
    }
    
    // Section 2.
    
    else if ([settingsRow isEqualToString:kSettingsRainDelay]) {
        RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
        rainDelay.parent = self;
        [self.navigationController pushViewController:rainDelay animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsRestrictions]) {
        RestrictionsVC *restrictions = [[RestrictionsVC alloc] init];
        restrictions.parent = self;
        [self.navigationController pushViewController:restrictions animated:YES];
    }

    // Section 3: Device Settings
    
    else if ([settingsRow isEqualToString:kSettingsRainSensitivity]) {
        RainSensitivityVC *rainSensitivityVC = [[RainSensitivityVC alloc] init];
        rainSensitivityVC.parent = self;
        [self.navigationController pushViewController:rainSensitivityVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsUnits]) {
        UnitsVC *unitsVC = [[UnitsVC alloc] init];
        unitsVC.parent = self;
        [self.navigationController pushViewController:unitsVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsDate]) {
        DatePickerVC *datePickerVC = [[DatePickerVC alloc] init];
        datePickerVC.parent = self;
        [self.navigationController pushViewController:datePickerVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsTime]) {
        SettingsTimePickerVC *timePickerVC = [[SettingsTimePickerVC alloc] initWithNibName:@"SettingsTimePickerVC" bundle:nil];
        timePickerVC.parent = self;
        [self.navigationController pushViewController:timePickerVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsSecurity]) {
        SettingsPasswordVC *passwordVC = [[SettingsPasswordVC alloc] init];
        passwordVC.parent = self;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsAbout]) {
        SettingsAboutVC *settingsAboutVC = [[SettingsAboutVC alloc] init];
        [self.navigationController pushViewController:settingsAboutVC animated:YES];
    }
}

#pragma mark - Actions

- (void)timePickerVCWillDissapear:(id)timePicker
{
}

@end
