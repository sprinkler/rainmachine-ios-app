//
//  SettingsAbout4VC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/02/15.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "SettingsAbout4VC.h"
#import "SettingsVC.h"
#import "ServerProxy.h"
#import "UpdateManager.h"
#import "Constants.h"
#import "Utils.h"
#import "APIVersion.h"
#import "AppDelegate.h"
#import "ColoredBackgroundButton.h"
#import "MBProgressHUD.h"

#define kRow_RainMachineFirmware    0
#define kRow_iOSAppVersion          1
#define kRow_HardwareVersion        2
#define kRow_APIVersion             3
#define kRow_StaticIPAddress        4
#define kRow_Netmask                5
#define kRow_Gateway                6
#define kRow_MACAddress             7
#define kRow_WiFiSSID               8
#define kRow_MemoryUsage            9
#define kRow_CPUUsage               10
#define kRow_Uptime                 11

#pragma mark -

@interface SettingsAbout4VC ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UpdateManager *updateManager;
@property (nonatomic, strong) ServerProxy *requestDiagServerProxy;
@property (nonatomic, strong) ServerProxy *requestWiFiServerProxy;
@property (nonatomic, strong) ServerProxy *requestVersionServerProxy;
@property (nonatomic, strong) ServerProxy *sendDiagnosticsServerProxy;
@property (nonatomic, strong) NSDictionary *diagResponseDictionary;
@property (nonatomic, strong) NSDictionary *wifiResponseDictionary;
@property (nonatomic, strong) APIVersion *apiVersion;

- (void)reload;
- (void)cancel;
- (void)requestDiag;
- (void)requestWifi;
- (void)requestVersion;
- (void)sendDiagnostics;

@property (nonatomic, readonly) BOOL reloading;
@property (nonatomic, assign) BOOL firstReloadFinished;
@property (nonatomic, strong) MBProgressHUD *hud;

- (NSString*)detailTextFromValue:(id)value metric:(NSString*)metric;
- (void)refreshProgressHUD;

@property (nonatomic, strong) NSString *iOSAppVersion;
@property (nonatomic, assign) BOOL checkingForUpdate;
@property (nonatomic, assign) BOOL updateAvailable;
@property (nonatomic, strong) NSString *updateAvailableVersion;

- (IBAction)startUpdate:(id)sender;

@end

#pragma mark -

@implementation SettingsAbout4VC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"About";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
    
    self.iOSAppVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    
    self.checkingForUpdate = YES;
    self.updateManager = [[UpdateManager alloc] initWithDelegate:self];
    [self.updateManager poll];
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self cancel];
    [self refreshProgressHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (BOOL)reloading {
    return (self.requestDiagServerProxy != nil || self.requestWiFiServerProxy != nil || self.requestVersionServerProxy != nil);
}

- (void)reload {
    [self requestDiag];
    [self requestWifi];
    [self requestVersion];
    [self refreshProgressHUD];
}

- (void)cancel {
    [self.requestDiagServerProxy cancelAllOperations], self.requestDiagServerProxy = nil;
    [self.requestWiFiServerProxy cancelAllOperations], self.requestWiFiServerProxy = nil;
    [self.requestVersionServerProxy cancelAllOperations], self.requestVersionServerProxy = nil;
    [self.sendDiagnosticsServerProxy cancelAllOperations], self.sendDiagnosticsServerProxy = nil;
    [self refreshProgressHUD];
}

- (void)requestDiag {
    self.requestDiagServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestDiagServerProxy requestDiag];
}

- (void)requestWifi {
    self.requestWiFiServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestWiFiServerProxy requestCurrentWiFi];
}

- (void)requestVersion {
    self.requestVersionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestVersionServerProxy requestAPIVersion];
}

- (void)sendDiagnostics {
    self.sendDiagnosticsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.sendDiagnosticsServerProxy sendDiagnostics];
    [self refreshProgressHUD];
}

- (NSString*)detailTextFromValue:(id)value metric:(NSString*)metric {
    if (!value) return @"none";
    if ([value isKindOfClass:[NSNull class]]) return @"none";
    NSString *stringValue = [NSString stringWithFormat:@"%@",value];
    if (!stringValue.length) return @"none";
    if (!metric.length) return stringValue;
    return [NSString stringWithFormat:@"%@%@",stringValue,metric];
}

- (void)refreshProgressHUD {
    BOOL shouldShowProgressHUD = (self.reloading || self.checkingForUpdate || self.sendDiagnosticsServerProxy != nil);
    if (shouldShowProgressHUD && !self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    else if (!shouldShowProgressHUD && self.hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.hud = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.firstReloadFinished) return 0;
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 12;
    if (section == 1) return 1;
    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 44.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"SettingsAboutCellIdentifier";
    static NSString *CellIdentifierAction = @"SettingsAboutCellIdentifierAction";
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == kRow_RainMachineFirmware) {
            cell.textLabel.text = @"RainMachine firmware";
            cell.detailTextLabel.text = [self detailTextFromValue:self.apiVersion.swVer metric:nil];
            
            if (self.updateAvailable) {
                ColoredBackgroundButton *updateNowButton = [ColoredBackgroundButton buttonWithType:UIButtonTypeSystem];
                
                updateNowButton.customBackgroundColorFromComponents = kSprinklerBlueColor;
                updateNowButton.tintColor = [UIColor blackColor];
                updateNowButton.frame = CGRectMake(0.0, 0.0, 104.0, 34.0);
                
                [updateNowButton setTitle:@"Update Now" forState:UIControlStateNormal];
                [updateNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [updateNowButton addTarget:self action:@selector(startUpdate:) forControlEvents:UIControlEventTouchUpInside];
                
                cell.accessoryView = updateNowButton;
            }
        }
        else if (indexPath.row == kRow_iOSAppVersion) {
            cell.textLabel.text = @"iOS app version";
            cell.detailTextLabel.text = [self detailTextFromValue:self.iOSAppVersion metric:nil];
        }
        else if (indexPath.row == kRow_HardwareVersion) {
            cell.textLabel.text = @"Hardware version";
            cell.detailTextLabel.text = [self detailTextFromValue:self.apiVersion.hwVer metric:nil];
        }
        else if (indexPath.row == kRow_APIVersion) {
            cell.textLabel.text = @"API version";
            cell.detailTextLabel.text = [self detailTextFromValue:self.apiVersion.apiVer metric:nil];
        }
        else if (indexPath.row == kRow_StaticIPAddress) {
            cell.textLabel.text = @"Static IP address";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.wifiResponseDictionary valueForKey:@"ipAddress"] metric:nil];
        }
        else if (indexPath.row == kRow_Netmask) {
            cell.textLabel.text = @"Netmask";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.wifiResponseDictionary valueForKey:@"netmaskAddress"] metric:nil];
        }
        else if (indexPath.row == kRow_Gateway) {
            cell.textLabel.text = @"Gateway";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.diagResponseDictionary valueForKey:@"gatewayAddress"] metric:nil];
        }
        else if (indexPath.row == kRow_MACAddress) {
            cell.textLabel.text = @"MAC address";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.wifiResponseDictionary valueForKey:@"macAddress"] metric:nil];
        }
        else if (indexPath.row == kRow_WiFiSSID) {
            cell.textLabel.text = @"WiFi SSID";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.wifiResponseDictionary valueForKey:@"ssid"] metric:nil];
        }
        else if (indexPath.row == kRow_MemoryUsage) {
            cell.textLabel.text = @"Memory usage";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.diagResponseDictionary valueForKey:@"memUsage"] metric:@" KB"];
        }
        else if (indexPath.row == kRow_CPUUsage) {
            cell.textLabel.text = @"CPU usage";
            cell.detailTextLabel.text = [self detailTextFromValue:@([[self.diagResponseDictionary valueForKey:@"cpuUsage"] intValue]) metric:@"%"];
        }
        else if (indexPath.row == kRow_Uptime) {
            cell.textLabel.text = @"Uptime";
            cell.detailTextLabel.text = [self detailTextFromValue:[self.diagResponseDictionary valueForKey:@"uptime"] metric:nil];
        }
        
        return cell;
    }
    else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierAction];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierAction];
        
        cell.textLabel.text = @"Send Diagnostics";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0];
        
        return cell;
    }
    
    return nil;
}

#pragma mark UiTableView delegat

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self sendDiagnostics];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestDiagServerProxy) {
        self.diagResponseDictionary = data;
        self.requestDiagServerProxy = nil;
    }
    else if (serverProxy == self.requestWiFiServerProxy) {
        self.wifiResponseDictionary = data;
        self.requestWiFiServerProxy = nil;
    }
    else if (serverProxy == self.requestVersionServerProxy) {
        self.apiVersion = data;
        self.requestVersionServerProxy = nil;
    }
    else if (serverProxy == self.sendDiagnosticsServerProxy) {
        self.sendDiagnosticsServerProxy = nil;
    }
    
    if (!self.reloading) self.firstReloadFinished = YES;
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.requestDiagServerProxy) self.requestDiagServerProxy = nil;
    else if (serverProxy == self.requestWiFiServerProxy) self.requestWiFiServerProxy = nil;
    else if (serverProxy == self.requestVersionServerProxy) self.requestVersionServerProxy = nil;
    else if (serverProxy == self.sendDiagnosticsServerProxy) self.sendDiagnosticsServerProxy = nil;
    
    if (!self.reloading) self.firstReloadFinished = YES;
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UpdateManager delegate

- (IBAction)startUpdate:(id)sender {
    [self.updateManager startUpdate];
}

- (void)sprinklerVersionReceivedMajor:(int)major minor:(int)minor subMinor:(int)subMinor {
    // Update the values from AppDelegate's UpdateManager too
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.updateManager.serverAPIMainVersion = major;
    appDelegate.updateManager.serverAPISubVersion = minor;
    appDelegate.updateManager.serverAPIMinorSubVersion = subMinor;
}

- (void)updateNowAvailable:(BOOL)available withVersion:(NSString *)the_new_version {
    self.updateAvailable = available;
    self.updateAvailableVersion = the_new_version;
    self.checkingForUpdate = NO;
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

@end
