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
#import "SettingsNameAndSecurityVC.h"
#import "ProvisionLocationSetupVC.h"
#import "ProvisionTimezonesListVC.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "API4StatusResponse.h"
#import "Utils.h"
#import "Provision.h"
#import "ProvisionLocation.h"
#import "SettingsDate.h"
#import "SettingsUnits.h"
#import "GlobalsManager.h"

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
NSString *kSettingsTimeZone           = @"Timezone";
NSString *kSettingsResetToDefaults    = @"Reset to Defaults";
NSString *kSettingsDataSources        = @"Data Sources";
NSString *kSettingsNetworkSettings    = @"Network Settings";
NSString *kSettingsDeviceName         = @"Device Name";
NSString *kSettingsRemoteAccess       = @"Remote Access";
NSString *kSettingsLocationSettings   = @"Location Settings";

@interface SettingsVC ()
{
    BOOL showZonesOnAppear;
}

@property (strong, nonatomic) NSArray *settings;
@property (strong, nonatomic) NSArray *settingsSectionNames;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) SettingsDate *settingsDate;
@property (strong, nonatomic) SettingsUnits *settingsUnits;

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
    
    // Section 1
    [settings addObject:@[kSettingsPrograms, kSettingsZones]];
    
    // Section 2
    if ([ServerProxy usesAPI4]) {
        [settings addObject:@[kSettingsRainDelay, kSettingsRestrictions]];
    } else {
        [settings addObject:@[kSettingsRainDelay]];
    }

    // Section 3
    if ([ServerProxy usesAPI4]) {
        [settings addObject:@[kSettingsNetworkSettings, kSettingsDataSources, kSettingsRainSensitivity, kSettingsLocationSettings, kSettingsUnits, kSettingsDate, kSettingsTime, kSettingsTimeZone, kSettingsDeviceName, kSettingsRemoteAccess, kSettingsSecurity, kSettingsResetToDefaults, kSettingsAbout]];
    } else {
        [settings addObject:@[kSettingsUnits, kSettingsDate, kSettingsTime, kSettingsSecurity, kSettingsAbout]];
    }
    
    self.settings = settings;
    self.settingsSectionNames = @[@"", @"", @"Device Settings"];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([ServerProxy usesAPI4]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        ServerProxy *getProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [getProvisionServerProxy requestProvision];
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
    
    if ([ServerProxy usesAPI4]) {
        if ([cell.textLabel.text isEqualToString:kSettingsNetworkSettings]) {
            cell.detailTextLabel.text = @"WiFi";
        } else if ([cell.textLabel.text isEqualToString:kSettingsDeviceName]) {
            cell.detailTextLabel.text = [Utils currentSprinkler].name;
        } else if ([cell.textLabel.text isEqualToString:kSettingsResetToDefaults]) {
            cell.detailTextLabel.text = @"Restore initial settings";
        } else if ([cell.textLabel.text isEqualToString:kSettingsTimeZone]) {
            cell.detailTextLabel.text = [GlobalsManager current].provision.location.timezone;
        } else if ([cell.textLabel.text isEqualToString:kSettingsLocationSettings]) {
            cell.detailTextLabel.text = [GlobalsManager current].provision.location.name;
        } else if ([cell.textLabel.text isEqualToString:kSettingsDate]) {
            NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
            cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format forceOnlyTimePart:NO forceOnlyDatePart:YES] stringFromDate:date];
        } else if ([cell.textLabel.text isEqualToString:kSettingsTime]) {
            NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
            cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format forceOnlyTimePart:YES forceOnlyDatePart:NO] stringFromDate:date];
        } else if ([cell.textLabel.text isEqualToString:kSettingsUnits]) {
            cell.detailTextLabel.text = [Utils sprinklerTemperatureUnits];
        } else {
            cell.detailTextLabel.text = nil;
        }
    }
    
//    if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
//        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
//    }
    
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
        SettingsNameAndSecurityVC *passwordVC = [[SettingsNameAndSecurityVC alloc] init];
        passwordVC.parent = self;
        passwordVC.isSecurityScreen = YES;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsDeviceName]) {
        SettingsNameAndSecurityVC *passwordVC = [[SettingsNameAndSecurityVC alloc] init];
        passwordVC.parent = self;
        passwordVC.isSecurityScreen = NO;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsAbout]) {
        SettingsAboutVC *settingsAboutVC = [[SettingsAboutVC alloc] init];
        [self.navigationController pushViewController:settingsAboutVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsResetToDefaults]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"All your programs, zone properties and Wi-Fi settings will be removed."
                                                           delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset to Defaults", nil];
        [alertView show];
    }
    else if ([settingsRow isEqualToString:kSettingsLocationSettings]) {
        ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
        locationSetupVC.dbSprinkler = [Utils currentSprinkler];
        [self.navigationController pushViewController:locationSetupVC animated:YES];
    } else if ([settingsRow isEqualToString:kSettingsTimeZone]) {
        ProvisionTimezonesListVC *timezonesListVC = [[ProvisionTimezonesListVC alloc] init];
        timezonesListVC.delegate = self;
        timezonesListVC.isPartOfWizard = NO;
        UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:timezonesListVC];
        [self.navigationController presentViewController:navDevices animated:YES completion:nil];
    }
}

#pragma mark - Actions

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != theAlertView.cancelButtonIndex) {
        ServerProxy *resetServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        [resetServerProxy provisionReset];
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        [NSTimer scheduledTimerWithTimeInterval:20
                                         target:self
                                       selector:@selector(waitForResetTimer:)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)timePickerVCWillDissapear:(id)timePicker
{
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];

    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if ([data isKindOfClass:[API4StatusResponse class]]) {
        API4StatusResponse *response = (API4StatusResponse*)data;
        BOOL err = ([response.statusCode intValue] != API4StatusCode_Success);
        NSString *errMessage = response.message;
        
        if (err) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self handleSprinklerGeneralError:errMessage showErrorMessage:YES];
        }
    } else if ([data isKindOfClass:[Provision class]]) {
        [GlobalsManager current].provision = (Provision*)data;
        ServerProxy *dateTimeServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [dateTimeServerProxy requestSettingsDate];
    } else if ([data isKindOfClass:[SettingsDate class]]) {
        self.settingsDate = data;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.tableView reloadData];
    }
}

- (void)loggedOut
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Logic


- (void)waitForResetTimer:(id)notif
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - TimeZoneSelectorDelegate

- (NSString*)timeZoneName
{
    return [GlobalsManager current].provision.location.timezone;
}

- (void)timeZoneSelected:(NSString*)timeZoneName
{
}

@end
