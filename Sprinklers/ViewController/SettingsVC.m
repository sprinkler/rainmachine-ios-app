//
//  SettingsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SettingsAboutVC.h"
#import "SettingsAbout4VC.h"
#import "SettingsVC.h"
#import "Additions.h"
#import "ProgramsVC.h"
#import "ZonesVC.h"
#import "RainDelayVC.h"
#import "RestrictionsVC.h"
#import "RainSensitivityVC.h"
#import "UnitsVC.h"
#import "SettingsDatePickerVC.h"
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
#import "ProvisionAvailableWiFisVC.h"
#import "StorageManager.H"
#import "AppDelegate.h"
#import "DevicesVC.h"
#import "DataSourcesVC.h"
#import "RemoteAccessVC.h"
#import "CloudSettings.h"

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
    }
    
    NSArray *settingsSection = self.settings[indexPath.section];
    cell.textLabel.text = settingsSection[indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if ([ServerProxy usesAPI4]) {
        if ([cell.textLabel.text isEqualToString:kSettingsNetworkSettings]) {
            cell.detailTextLabel.text = @"WiFi";
        } else if ([cell.textLabel.text isEqualToString:kSettingsDeviceName]) {
            cell.detailTextLabel.text = [Utils currentSprinkler].name;
        } else if ([cell.textLabel.text isEqualToString:kSettingsResetToDefaults]) {
            cell.detailTextLabel.text = @"Restore initial settings";
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if ([cell.textLabel.text isEqualToString:kSettingsTimeZone]) {
            cell.detailTextLabel.text = [GlobalsManager current].provision.location.timezone;
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else if ([cell.textLabel.text isEqualToString:kSettingsLocationSettings]) {
            cell.detailTextLabel.text = [GlobalsManager current].provision.location.name;
        } else if ([cell.textLabel.text isEqualToString:kSettingsDate]) {
            NSNumber *time_format = [Utils timeIs24HourFormat] ? @24 : @12;
            NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
            cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:time_format seconds:YES forceOnlyTimePart:NO forceOnlyDatePart:YES] stringFromDate:date];
        } else if ([cell.textLabel.text isEqualToString:kSettingsTime]) {
            NSNumber *time_format = [Utils timeIs24HourFormat] ? @24 : @12;
            NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
            cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:time_format seconds:YES forceOnlyTimePart:YES forceOnlyDatePart:NO] stringFromDate:date];
        } else if ([cell.textLabel.text isEqualToString:kSettingsUnits]) {
            cell.detailTextLabel.text = [Utils sprinklerTemperatureUnits];
        } else if ([cell.textLabel.text isEqualToString:kSettingsRemoteAccess]) {
            cell.detailTextLabel.text = [Utils cloudEmailStatusForCloudSettings:[GlobalsManager current].cloudSettings];
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
    
    else if ([settingsRow isEqualToString:kSettingsNetworkSettings]) {
        ProvisionAvailableWiFisVC *availableWiFiVC = [[ProvisionAvailableWiFisVC alloc] init];
        availableWiFiVC.inputSprinklerMAC = [Utils currentSprinkler].sprinklerId;
        [self.navigationController pushViewController:availableWiFiVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsDataSources]) {
        DataSourcesVC *dataSourcesVC = [[DataSourcesVC alloc] init];
        dataSourcesVC.parent = self;
        [self.navigationController pushViewController:dataSourcesVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsRainSensitivity]) {
        RainSensitivityVC *rainSensitivityVC = [[RainSensitivityVC alloc] init];
        rainSensitivityVC.parent = self;
        [self.navigationController pushViewController:rainSensitivityVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsLocationSettings]) {
        ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
        locationSetupVC.dbSprinkler = [Utils currentSprinkler];
        [self.navigationController pushViewController:locationSetupVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsUnits]) {
        UnitsVC *unitsVC = [[UnitsVC alloc] init];
        unitsVC.parent = self;
        [self.navigationController pushViewController:unitsVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsDate]) {
        SettingsDatePickerVC *datePickerVC = [[SettingsDatePickerVC alloc] init];
        datePickerVC.parent = self;
        [self.navigationController pushViewController:datePickerVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsTime]) {
        SettingsTimePickerVC *timePickerVC = [[SettingsTimePickerVC alloc] initWithNibName:@"SettingsTimePickerVC" bundle:nil];
        timePickerVC.parent = self;
        [self.navigationController pushViewController:timePickerVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsTimeZone]) {
        ProvisionTimezonesListVC *timezonesListVC = [[ProvisionTimezonesListVC alloc] init];
        timezonesListVC.delegate = self;
        timezonesListVC.isPartOfWizard = NO;
        UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:timezonesListVC];
        [self.navigationController presentViewController:navDevices animated:YES completion:nil];
    }
    else if ([settingsRow isEqualToString:kSettingsDeviceName]) {
        SettingsNameAndSecurityVC *passwordVC = [[SettingsNameAndSecurityVC alloc] init];
        passwordVC.parent = self;
        passwordVC.isSecurityScreen = NO;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsRemoteAccess]) {
        RemoteAccessVC *remoteAccessVC = [[RemoteAccessVC alloc] init];
        remoteAccessVC.parent = self;
        [self.navigationController pushViewController:remoteAccessVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsSecurity]) {
        SettingsNameAndSecurityVC *passwordVC = [[SettingsNameAndSecurityVC alloc] init];
        passwordVC.parent = self;
        passwordVC.isSecurityScreen = YES;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsResetToDefaults]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"All your programs, zone properties and Wi-Fi settings will be removed."
                                                           delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset to Defaults", nil];
        alertView.tag = kAlertView_DoYouWantToReset;
        [alertView show];
    }
    else if ([settingsRow isEqualToString:kSettingsAbout]) {
        if ([ServerProxy usesAPI3]) {
            SettingsAboutVC *settingsAboutVC = [[SettingsAboutVC alloc] init];
            [self.navigationController pushViewController:settingsAboutVC animated:YES];
        } else {
            SettingsAbout4VC *settingsAboutVC = [[SettingsAbout4VC alloc] init];
            settingsAboutVC.parent = self;
            [self.navigationController pushViewController:settingsAboutVC animated:YES];
        }
    }
}

#pragma mark - Actions

- (void)resetToDefaults
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    Sprinkler *sprinkler = [Utils currentSprinkler];
    
    [Utils invalidateLoginForCurrentSprinkler];
    
    [appDelegate refreshRootViews:nil];
    [appDelegate.devicesVC setResetToDefaultsModeWithSprinkler:sprinkler];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (theAlertView.tag == kAlertView_ResetToDefaultsSuccesfull) {
        [self resetToDefaults];
    }
    else if (theAlertView.tag == kAlertView_DoYouWantToReset) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            ServerProxy *resetServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
            [resetServerProxy provisionReset];
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
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
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        API4StatusResponse *response = (API4StatusResponse*)data;
        BOOL err = ([response.statusCode intValue] != API4StatusCode_Success);
        
        if (err) {
            [self handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
//            [self resetToDefaults];
            [Utils invalidateLoginForCurrentSprinkler];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate refreshRootViews:nil];

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Succesfuly restored initial settings" message:@"Rainmachine is now rebooting. In order to set up your Rainmachine, switch to iOS Settings, connect to RainMachine's WiFi network, switch back to Rainmachine app, then select \"New Rainmachine setup\""
                                                               delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            alertView.tag = kAlertView_ResetToDefaultsSuccesfull;
            
            [alertView show];
        }
    }
    else if ([data isKindOfClass:[Provision class]]) {
        [GlobalsManager current].provision = (Provision*)data;
        ServerProxy *requestCloudSettingsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [requestCloudSettingsServerProxy requestCloudSettings];
    }
    else if ([data isKindOfClass:[CloudSettings class]]) {
        [GlobalsManager current].cloudSettings = (CloudSettings*)data;
        ServerProxy *dateTimeServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [dateTimeServerProxy requestSettingsDate];
    }
    else if ([data isKindOfClass:[SettingsDate class]]) {
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

#pragma mark - TimeZoneSelectorDelegate

- (NSString*)timeZoneName
{
    return [GlobalsManager current].provision.location.timezone;
}

- (void)timeZoneSelected:(NSString*)timeZoneName
{
}

@end
