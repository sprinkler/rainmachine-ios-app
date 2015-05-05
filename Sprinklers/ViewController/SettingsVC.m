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
#import "WindSensitivityVC.h"
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
#import "ProvisionSystem.h"
#import "SettingsDate.h"
#import "SettingsUnits.h"
#import "GlobalsManager.h"
#import "ProvisionAvailableWiFisVC.h"
#import "StorageManager.H"
#import "AppDelegate.h"
#import "DevicesVC.h"
#import "DataSourcesVC.h"
#import "ProvisionRemoteAccessVC.h"
#import "CloudSettings.h"
#import "RainSensorVC.h"
#import "WateringHistoryVC.h"
#import "SoftwareUpdateVC.h"

NSString *kSettingsPrograms             = @"Programs";
NSString *kSettingsWateringHistory      = @"Watering History";
NSString *kSettingsSnooze               = @"Snooze";
NSString *kSettingsRainDelay            = @"Rain Delay";
NSString *kSettingsRestrictions         = @"Restrictions";
NSString *kSettingsWeather              = @"Weather";
NSString *kSettingsSystemSettings       = @"System Settings";
NSString *kSettingsAbout                = @"About";
NSString *kSettingsSoftwareUpdate       = @"Software Update";

// Weather
NSString *kSettingsDataSources          = @"Data Sources";
NSString *kSettingsRainSensitivity      = @"Rain Sensitivity";
NSString *kSettingsWindSensitivity      = @"Wind Sensitivity";

// System Settings

NSString *kSettingsNetworkSettings      = @"Network Settings";
NSString *kSettingsRemoteAccess         = @"Remote Access";
NSString *kSettingsRainSensor           = @"Rain Sensor";
NSString *kSettingsDeviceName           = @"Device Name";
NSString *kSettingsLocation             = @"Location";
NSString *kSettingsDate                 = @"Date";
NSString *kSettingsTime                 = @"Time";
NSString *kSettingsUse24HoursFormat     = @"Use 24 hours format";
NSString *kSettingsTimeZone             = @"Timezone";
NSString *kSettingsUnits                = @"Units";
NSString *kSettingsPassword             = @"Password";
NSString *kSettingsResetToDefaults      = @"Reset to Defaults";

@interface SettingsVC ()

@property (strong, nonatomic) NSArray *settings;
@property (strong, nonatomic) NSString *parentSetting;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) SettingsDate *settingsDate;
@property (strong, nonatomic) SettingsUnits *settingsUnits;

@property (nonatomic, readonly) NSArray *weatherSettings;
@property (nonatomic, readonly) NSArray *systemSetting;

@end

@implementation SettingsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[GlobalsManager current] addObserver:self forKeyPath:@"cloudSettings" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

- (id)initWithSettings:(NSArray*)settings parentSetting:(NSString*)parentSetting {
    self = [self init];
    if (!self) return nil;
    
    _settings = settings;
    _parentSetting = parentSetting;
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[GlobalsManager current] removeObserver:self forKeyPath:@"cloudSettings"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self.parentSetting isEqualToString:kSettingsSystemSettings]) {
        if ([ServerProxy usesAPI4]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            ServerProxy *getProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
            [getProvisionServerProxy requestProvision];
            
            if ([GlobalsManager current].cloudSettings.pendingEmail.length) {
                [[GlobalsManager current] startPollingCloudSettings];
            }
        } else {
            ServerProxy *dateTimeServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
            [dateTimeServerProxy requestSettingsDate];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[GlobalsManager current] stopPollingCloudSettings];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == [GlobalsManager current] && [keyPath isEqualToString:@"cloudSettings"]) {
        [self.tableView reloadData];
        if (![GlobalsManager current].cloudSettings.pendingEmail.length) {
            [[GlobalsManager current] stopPollingCloudSettings];
        }
    }
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.settings.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 48.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    
    cell.textLabel.text = self.settings[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    if ([cell.textLabel.text isEqualToString:kSettingsUse24HoursFormat]) {
        UISwitch *cellSwitch = [UISwitch new];
        [cellSwitch addTarget:self action:@selector(onSwitchUse24HoursFormat:) forControlEvents:UIControlEventValueChanged];
        cellSwitch.on = [Utils isTime24HourFormat];
        cell.accessoryView = cellSwitch;
    }

    cell.userInteractionEnabled = YES;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.text = nil;
    
    if ([cell.textLabel.text isEqualToString:kSettingsSystemSettings]) {
        if ([ServerProxy usesAPI4]) {
            cell.detailTextLabel.text = @"Network, Location, Time...";
        } else {
            cell.detailTextLabel.text = @"Units, Date, Time";
        }
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsAbout]) {
        if ([ServerProxy usesAPI4]) {
            cell.detailTextLabel.text = @"Version info, System stats...";
        } else {
            cell.detailTextLabel.text = @"Version info";
        }
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsNetworkSettings]) {
        cell.detailTextLabel.text = @"WiFi";
        if ([Utils isCloudDevice:[Utils currentSprinkler]]) {
            cell.userInteractionEnabled = NO;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsRemoteAccess]) {
        cell.detailTextLabel.text = [Utils cloudEmailStatusForCloudSettings:[GlobalsManager current].cloudSettings];
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsRainSensor]) {
        cell.detailTextLabel.text = ([GlobalsManager current].provision.system.useRainSensor ? @"Activated" : @"Not activated");
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsDeviceName]) {
        cell.detailTextLabel.text = [Utils currentSprinkler].name;
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsLocation]) {
        cell.detailTextLabel.text = [GlobalsManager current].provision.location.name;
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsDate]) {
        NSNumber *time_format = [Utils isTime24HourFormat] ? @24 : @12;
        NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
        cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:time_format seconds:YES forceOnlyTimePart:NO forceOnlyDatePart:YES] stringFromDate:date];
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsTime]) {
        NSNumber *time_format = [Utils isTime24HourFormat] ? @24 : @12;
        NSDate *date = [[Utils sprinklerDateFormatterForTimeFormat:self.settingsDate.time_format] dateFromString:self.settingsDate.appDate];
        cell.detailTextLabel.text = [[Utils sprinklerDateFormatterForTimeFormat:time_format seconds:YES forceOnlyTimePart:YES forceOnlyDatePart:NO] stringFromDate:date];
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsTimeZone]) {
        cell.detailTextLabel.text = [GlobalsManager current].provision.location.timezone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsUnits]) {
        cell.detailTextLabel.text = [Utils sprinklerUnits];
    }
    else if ([cell.textLabel.text isEqualToString:kSettingsResetToDefaults]) {
        cell.detailTextLabel.text = @"Restore initial settings";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *settingsRow = self.settings[indexPath.row];
    
    // Main settings
    
    if ([settingsRow isEqualToString:kSettingsPrograms]) {
        ProgramsVC *programs = [[ProgramsVC alloc] init];
        programs.parent = self;
        [self.navigationController pushViewController:programs animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsWateringHistory]) {
        WateringHistoryVC *wateringHistoryVC = [[WateringHistoryVC alloc] init];
        [self.navigationController pushViewController:wateringHistoryVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsSnooze]) {
        RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
        rainDelay.title = @"Snooze";
        rainDelay.parent = self;
        [self.navigationController pushViewController:rainDelay animated:YES];
    }
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
    else if ([settingsRow isEqualToString:kSettingsWeather]) {
        SettingsVC *settingsVC = [[SettingsVC alloc] initWithSettings:self.weatherSettings parentSetting:kSettingsWeather];
        settingsVC.title = kSettingsWeather;
        [self.navigationController pushViewController:settingsVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsSystemSettings]) {
        SettingsVC *settingsVC = [[SettingsVC alloc] initWithSettings:self.systemSetting parentSetting:kSettingsSystemSettings];
        settingsVC.title = kSettingsSystemSettings;
        [self.navigationController pushViewController:settingsVC animated:YES];
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
    else if ([settingsRow isEqualToString:kSettingsSoftwareUpdate]) {
        SoftwareUpdateVC *softwareUpdateVC = [[SoftwareUpdateVC alloc] init];
        [self.navigationController pushViewController:softwareUpdateVC animated:YES];
    }

    // Weather Settings
    
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
    else if ([settingsRow isEqualToString:kSettingsWindSensitivity]) {
        WindSensitivityVC *windSensitivityVC = [[WindSensitivityVC alloc] init];
        windSensitivityVC.parent = self;
        [self.navigationController pushViewController:windSensitivityVC animated:YES];
    }
    
    // System Settings
    
    else if ([settingsRow isEqualToString:kSettingsNetworkSettings]) {
        ProvisionAvailableWiFisVC *availableWiFiVC = [[ProvisionAvailableWiFisVC alloc] init];
        availableWiFiVC.inputSprinklerMAC = [Utils currentSprinkler].sprinklerId;
        [self.navigationController pushViewController:availableWiFiVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsRemoteAccess]) {
        ProvisionRemoteAccessVC *remoteAccessVC = [[ProvisionRemoteAccessVC alloc] initWithNibName:@"ProvisionRemoteAccessVC" bundle:nil];
        remoteAccessVC.isPartOfWizard = NO;
        remoteAccessVC.dbSprinkler = [Utils currentSprinkler];
        [self.navigationController pushViewController:remoteAccessVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsRainSensor]) {
        RainSensorVC *rainSensorVC = [[RainSensorVC alloc] init];
        [self.navigationController pushViewController:rainSensorVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsDeviceName]) {
        SettingsNameAndSecurityVC *passwordVC = [[SettingsNameAndSecurityVC alloc] init];
        passwordVC.parent = self;
        passwordVC.isSecurityScreen = NO;
        [self.navigationController pushViewController:passwordVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsLocation]) {
        ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
        locationSetupVC.dbSprinkler = [Utils currentSprinkler];
        [self.navigationController pushViewController:locationSetupVC animated:YES];
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
    else if ([settingsRow isEqualToString:kSettingsUse24HoursFormat]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *cellSwitch = (UISwitch*)cell.accessoryView;
        cellSwitch.on = !cellSwitch.isOn;
        [self onSwitchUse24HoursFormat:cellSwitch];
    }
    else if ([settingsRow isEqualToString:kSettingsTimeZone]) {
        ProvisionTimezonesListVC *timezonesListVC = [[ProvisionTimezonesListVC alloc] init];
        timezonesListVC.delegate = self;
        timezonesListVC.isPartOfWizard = NO;
        UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:timezonesListVC];
        [self.navigationController presentViewController:navDevices animated:YES completion:nil];
    }
    else if ([settingsRow isEqualToString:kSettingsUnits]) {
        UnitsVC *unitsVC = [[UnitsVC alloc] init];
        unitsVC.parent = self;
        [self.navigationController pushViewController:unitsVC animated:YES];
    }
    else if ([settingsRow isEqualToString:kSettingsPassword]) {
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
}

#pragma mark - Settings options

- (NSArray*)weatherSettings {
    if ([ServerProxy usesAPI4]) {
        return @[kSettingsDataSources,
                 kSettingsRainSensitivity,
                 kSettingsWindSensitivity];
    } else {
        return @[];
    }
}

- (NSArray*)systemSetting {
    if ([ServerProxy usesAPI4]) {
        return @[kSettingsNetworkSettings,
                 kSettingsRemoteAccess,
                 kSettingsRainSensor,
                 kSettingsDeviceName,
                 kSettingsLocation,
                 kSettingsDate,
                 kSettingsTime,
                 kSettingsUse24HoursFormat,
                 kSettingsTimeZone,
                 kSettingsUnits,
                 kSettingsPassword,
                 kSettingsResetToDefaults];
    } else {
        return @[kSettingsDate,
                 kSettingsTime,
                 kSettingsUnits,
                 kSettingsPassword];
    }
}

#pragma mark - Actions

- (void)resetToDefaults {
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

- (void)timePickerVCWillDissapear:(id)timePicker {
}

- (IBAction)onSwitchUse24HoursFormat:(UISwitch*)sender {
    [Utils setIsTime24HourFormat:sender.isOn];
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
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

- (NSString*)timeZoneName {
    return [GlobalsManager current].provision.location.timezone;
}

- (void)timeZoneSelected:(NSString*)timeZoneName {
}

@end
