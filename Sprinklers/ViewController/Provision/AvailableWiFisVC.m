//
//  AvailableWiFisVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "AvailableWiFisVC.h"
#import "ServiceManager.h"
#import "Sprinkler.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "WiFi.h"
#import "ProvisionWiFiVC.h"
#import "Utils.h"
#import "NetworkUtilities.h"
#import "WiFiCell.h"
#import "ProvisionNameSetupVC.h"
#import "LocationSetupVC.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AppDelegate.h"
#import "UpdateManager.h"

#define kPollInterval 6

const float kWifiSignalMin = -100;
const float kWifiSignalMax = -50;

@interface AvailableWiFisVC ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) NSArray *discoveredSprinklers;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) MBProgressHUD *wifiRebootHud;
@property (strong, nonatomic) NSArray *availableWiFis;
@property (strong, nonatomic) NSTimer *devicesPollTimer;
@property (strong, nonatomic) ProvisionWiFiVC *provisionWiFiVC;
@property (assign, nonatomic) BOOL isScrolling;
@property (strong, nonatomic) UILabel *headerView;
@property (assign, nonatomic) BOOL loggedIn;
@property (assign, nonatomic) BOOL firstStart;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSDate *startDateWifiJoin;
@property (strong, nonatomic) NSDictionary *sprinklerCurrentWiFi;

@property (strong, nonatomic) ServerProxy *requestAvailableWiFisProvisionServerProxy;
@property (strong, nonatomic) ServerProxy *loginServerProxy;
@property (strong, nonatomic) ServerProxy *requestCurrentWiFiProxy;
@property (strong, nonatomic) ServerProxy *joinWifiServerProxy;
@property (strong, nonatomic) ServerProxy *requestDiagProxy;

@end

@implementation AvailableWiFisVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.updateManager stopAll];

    [ServerProxy pushSprinklerVersion];
    [ServerProxy setSprinklerVersionMajor:4 minor:0 subMinor:0];
    
    self.duringWiFiRestart = NO;
    
    self.firstStart = YES;
    
    self.isScrolling = NO;

    [self.tableView registerNib:[UINib nibWithNibName:@"WiFiCell" bundle:nil] forCellReuseIdentifier:@"WiFiCell"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidResignActive) name:@"ApplicationDidResignActive" object:nil];

    self.view.backgroundColor = self.tableView.backgroundColor;
    
    self.headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 46)];
    self.headerView.text = @"Connect your Rain Machine to a WiFi network";
    self.headerView.textColor = [UIColor darkGrayColor];
    self.headerView.numberOfLines = 0;
    self.headerView.textAlignment = NSTextAlignmentCenter;

    // Do any additional setup after loading the view from its nib.
//    [self refreshUI];

    self.title = @"Setup";

    self.firstStart = NO;
}

- (void)updateTVHeaderToHidden:(BOOL)hidden
{
    if (hidden) {
        self.tableView.tableHeaderView = nil;
    } else {
        self.tableView.tableHeaderView = self.headerView;
    }
}

- (void)shouldStartBroadcastForceUIRefresh:(BOOL)forceUIRefresh
{
//    [self shouldStopBroadcast];
    [[ServiceManager current] startBroadcastForSprinklers:YES];
}

- (void)appDidBecomeActive
{
//    [self shouldStartBroadcastForceUIRefresh:NO];

    if (self.availableWiFis.count == 0) {
        [self showHud];
    }
//    [self restartPolling];
//    [self.devicesPollTimer fire];
}

- (void)appDidResignActive {
    [self shouldStopBroadcast];
}

- (void)restartPolling
{
    [self.devicesPollTimer invalidate];
    
    self.devicesPollTimer = [NSTimer scheduledTimerWithTimeInterval:kPollInterval
                                                             target:self
                                                           selector:@selector(pollDevices)
                                                           userInfo:nil
                                                            repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.availableWiFis.count == 0) {
        [self showHud];
        
        // First poll should be quicker
        [self shouldStartBroadcastForceUIRefresh:NO];
        [NSTimer scheduledTimerWithTimeInterval:1.5
                                         target:self
                                       selector:@selector(refreshUI)
                                       userInfo:nil
                                        repeats:NO];

        [self restartPolling];
    }

//    [self refreshUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
    self.requestAvailableWiFisProvisionServerProxy = nil;
    
    [self shouldStopBroadcast];
    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = nil;
}

- (NSString*)currentWiFiName
{
    NSDictionary *currentWifi = [self fetchSSIDInfo];
    return currentWifi[@"SSID"];
}

- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
//    NSLog(@"%s: Supported interfaces: %@", ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
//        NSLog(@"%s: %@ => %@", ifnam, info);
        if (info && [info count]) {
            break;
        }
    }
    
    return info;
}

- (void)refreshUI
{
    DLog(@"connected to network: %@", [self fetchSSIDInfo]);
    
    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:@NO];
    
    [self hideHud];
    
    if (self.isScrolling) {
        return;
    }
    
    if (self.alertView) {
        return;
    }
    
    if ((self.sprinkler) && (!self.availableWiFis)) {
        [self showHud];
    }
    
    if (self.startDateWifiJoin) {
        NSTimeInterval since = -[self.startDateWifiJoin timeIntervalSinceNow];
        if (since > kWizard_TimeoutWifiJoin) {
            self.startDateWifiJoin = nil;

            [self hideHud];
            [self hideWifiRebootHud];
            
            [self resetWiFiSetup];

            // The WiFi is home network / another network / Rainmachine AP / or no-network
            NSString *message = @"Connecting the Rainmachine to your home network timed out. Go to Settings and connect back to your Rainmachine in order to restart the setup.";
            if ([self currentWiFiName] == nil) {
                message = @"Connecting the Rainmachine to your home network timed out because your device didn't reconnect to your home network. Go to Settings and connect to your home network in order to continue the setup.";
            }
            self.alertView = [[UIAlertView alloc] initWithTitle:@"Timeout" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = kAlertView_SetupWizard_WifiJoinTimedOut;
            [self.alertView show];

//            [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
            
            return;
        }
    }
    
    DiscoveredSprinklers *newSprinkler = nil;
    if (self.inputSprinklerMAC) {
        for (DiscoveredSprinklers *ds in self.discoveredSprinklers) {
            if ([ds.sprinklerId isEqualToString:self.inputSprinklerMAC]) {
                newSprinkler = ds;
                break;
            }
        }
    } else {
        newSprinkler = [self.discoveredSprinklers firstObject];
        self.inputSprinklerMAC = newSprinkler.sprinklerId;
    }
    
    DiscoveredSprinklers *currentSprinkler = self.sprinkler;
    
    // Once we detect a sprinkler go with it and don't change it anymore
    if ((newSprinkler) && (!self.sprinkler)) {
        self.sprinkler = newSprinkler;
        self.availableWiFis = nil;

        if (self.sprinkler) {
            [self showHud];
            
//                [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
            
            DLog(@"currentSprinkler: %@", currentSprinkler);
            DLog(@"newSprinkler: %@", newSprinkler);
            
            if (self.duringWiFiRestart) {
                [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
            }
            
            NSString *address = self.sprinkler.url;
            NSString *port = [Utils getPort:address];
            address = [Utils getBaseUrl:address];
            if (![NetworkUtilities accessTokenForBaseUrl:address port:port]) {
                [self.loginServerProxy cancelAllOperations];
                self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
                
                // Try to log in automatically
                [self.loginServerProxy loginWithUserName:@"admin" password:@"" rememberMe:YES];
            } else {
                [self requestCurrentWiFi];
            }
        }
    }
    
    self.messageLabel.hidden = (self.firstStart) || (self.duringWiFiRestart);
    
    if (self.sprinkler) {
        self.tableView.hidden = NO;
        [self updateTVHeaderToHidden:(self.availableWiFis == nil)];
//        self.title = self.sprinkler.sprinklerName;
    } else {
        self.tableView.hidden = YES;
        [self updateTVHeaderToHidden:YES];
    }
    
    [self.tableView reloadData];
}

- (void)pollDevices
{
    [self refreshUI];
    [self shouldStartBroadcastForceUIRefresh:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)rowForOtherNetwork
{
    return (self.availableWiFis == nil) ? -1 : (int)(self.availableWiFis.count);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.availableWiFis.count + ([self rowForOtherNetwork] == -1 ? 0 : 1);
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     WiFiCell *cell = nil;
     if (indexPath.row < self.availableWiFis.count) {
         cell = (WiFiCell*)[tableView dequeueReusableCellWithIdentifier:@"WiFiCell" forIndexPath:indexPath];
         WiFi *wifi = self.availableWiFis[indexPath.row];
         cell.wifiTextLabel.text = wifi.SSID;
         
         NSString *imageName = nil;
         float signal = [wifi.signal floatValue];
         int signalDiscreteValue = roundf((3.0 * (signal - kWifiSignalMin)) / (kWifiSignalMax - kWifiSignalMin));
         if (signalDiscreteValue <= 1) {
             imageName = [NSString stringWithFormat:@"icon_wi-fi-%d-bar", signalDiscreteValue];
         } else {
             if (signalDiscreteValue == 2) {
                 imageName = [NSString stringWithFormat:@"icon_wi-fi-%d-bars", signalDiscreteValue];
             } else {
                 imageName = @"icon_wi-fi-full";
             }
         }
         cell.signalImageView.image = [UIImage imageNamed:imageName];
         cell.lockedImageView.image = [wifi.isEncrypted boolValue] ? [UIImage imageNamed:@"icon_wi-fi-locked.png"] : nil;
     } else {
         if (indexPath.row == [self rowForOtherNetwork]) {
             cell = (WiFiCell*)[tableView dequeueReusableCellWithIdentifier:@"WiFiCell" forIndexPath:indexPath];
             cell.wifiTextLabel.text = @"Other...";
             cell.signalImageView.image = nil;
             cell.lockedImageView.image = nil;
         }
     }

     return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.availableWiFis.count ? @"CHOOSE A NETWORK..." : nil;
}

 #pragma mark - Table view delegate
 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
    if (indexPath.row < self.availableWiFis.count) {
        WiFi *wifi = self.availableWiFis[indexPath.row];
        BOOL needsPassword;
        NSString *securityOption = [Utils securityOptionFromSprinklerWiFi:wifi needsPassword:&needsPassword];
        if (needsPassword) {
            self.provisionWiFiVC = [[ProvisionWiFiVC alloc] init];
            self.provisionWiFiVC.SSID = wifi.SSID;
            self.provisionWiFiVC.delegate = self;
            self.provisionWiFiVC.sprinkler = self.sprinkler;

            self.provisionWiFiVC.showSSID = NO;
            self.provisionWiFiVC.securityOption = securityOption;
            UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionWiFiVC];
            [self.navigationController presentViewController:navDevices animated:YES completion:nil];
        } else {
            [self joinWiFi:wifi.SSID encryption:@"none" key:@"" sprinklerId:self.sprinkler.sprinklerId];
        }
    } else {
        // Other...
        self.provisionWiFiVC = [[ProvisionWiFiVC alloc] init];
        self.provisionWiFiVC.securityOption = nil;
        self.provisionWiFiVC.showSSID = YES;
        UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionWiFiVC];
        [self.navigationController presentViewController:navDevices animated:YES completion:nil];
    }
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    // Fail silently when connection is lost: this error appears for ex. when /4/login is requested for a devices connected to a network but still unprovisioned
    if (error.code != NSURLErrorNetworkConnectionLost) {
        [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    }
    
    if (serverProxy == self.requestAvailableWiFisProvisionServerProxy) {
        self.sprinkler = nil;
    }
    
    [self hideHud];
    [self refreshUI];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestCurrentWiFiProxy) {
        self.sprinklerCurrentWiFi = data;
        self.requestCurrentWiFiProxy = nil;
        self.requestDiagProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:NO];
        [self.requestDiagProxy requestDiag];
    }
    else if (serverProxy == self.requestDiagProxy) {
        self.requestDiagProxy = nil;
        
        BOOL hasSprinklerWiFiSetUp = !((self.sprinklerCurrentWiFi[@"ssid"] == nil) || ([self.sprinklerCurrentWiFi[@"ssid"] isKindOfClass:[NSNull class]]));
        if (self.duringWiFiRestart) {
            // We expected for the sprinkler to reconnect to home WiFi, but reconnected back to the sprinkler's AP WiFi
//            if ([self.apNetworkNameOfSprinkler isEqualToString:[self currentWiFiName]]) {
            if (!hasSprinklerWiFiSetUp) {
                self.alertView = [[UIAlertView alloc] initWithTitle:@"WiFi Setup failed" message:@"It seems that the WiFi setup on your sprinkler failed. Press OK and select again your home network." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                self.alertView.tag = kAlertView_SetupWizard_ReconnectedToSprinkler;
                [self.alertView show];

                self.startDateWifiJoin = nil;
            }
            
            [self resetWiFiSetup];
        }
        
        if (!hasSprinklerWiFiSetUp) {
            // Sprinkler hasn't connected yet to any WiFi
            // Continue with the WiFi setup wizard
            [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
            
            self.requestAvailableWiFisProvisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
            [self requestAvailableWiFis];
            
        } else {
            // TODO: here to decide if the name+pass was set up
            // Continue with the RainMachine name setup wizard or with location setup
            //            if (![standaloneMode boolValue]) {
            [self hideWifiRebootHud];
            UINavigationController *navigationController = self.navigationController;
            [self.navigationController popToRootViewControllerAnimated:NO];
            ProvisionNameSetupVC *provisionNameSetupVC = [ProvisionNameSetupVC new];
            provisionNameSetupVC.sprinkler = self.sprinkler;
            [self cancelAllOperations];
            [navigationController pushViewController:provisionNameSetupVC animated:YES];
            //            } else {
            //                // Continue with the location setup
            //                LocationSetupVC *locationSetupVC = [[LocationSetupVC alloc] init];
            //                locationSetupVC.sprinkler = self.sprinkler;
            //                locationSetupVC.delegate = self;
            //                [self cancelAllOperations];
            //                [self.navigationController pushViewController:locationSetupVC animated:YES];
            //            }
        }
    }
    else if (serverProxy == self.requestAvailableWiFisProvisionServerProxy) {
        if ([data isKindOfClass:[NSArray class]]) {
            self.availableWiFis = data;
        }
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(requestAvailableWiFis) userInfo:nil repeats:NO];
    }
    else if (serverProxy == self.joinWifiServerProxy) {
        // The sprinkler retarts, and if the connection to the home wifi succeeds it will get a new url
        self.joinWifiServerProxy = nil;
    }
    
    [self hideHud];
    [self refreshUI];
}

- (void)requestAvailableWiFis
{
    [self.requestAvailableWiFisProvisionServerProxy requestAvailableWiFis];
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit {
    
    NSString *address = self.sprinkler.url;
    NSString *port = [Utils getPort:address];
    address = [Utils getBaseUrl:address];
    
    [NetworkUtilities saveAccessTokenForBaseURL:address port:port loginResponse:(Login4Response*)loginResponse];

    self.loginServerProxy = nil;
    
    [self requestCurrentWiFi];
    
    self.loggedIn = YES;
}

- (void)requestCurrentWiFi
{
    self.requestCurrentWiFiProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
    [self.requestCurrentWiFiProxy requestCurrentWiFi];
}

- (void)loggedOut {
    
    [self hideHud];
    [self.loginServerProxy cancelAllOperations];
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Cannot start setup wizard" message:@"Press a button on your sprinkler." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    self.alertView.tag = kAlertView_SetupWizard_CannotStart;
    [self.alertView show];
    
    [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
    self.sprinkler = nil;
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.alertView = nil;
    if (theAlertView.tag == kAlertView_SetupWizard_CannotStart) {
        self.sprinkler = nil;
        
        [self showHud];
    }
    else if (theAlertView.tag == kAlertView_SetupWizard_WifiJoinTimedOut) {
        // Prevent the user to be able to open the device from the device list because the login token is valid but the device is not usable
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)showHud {
    if ((!self.hud) && (!self.wifiRebootHud)) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.view.userInteractionEnabled = NO;
    }
}

- (void)hideHud {
    if (!self.wifiRebootHud) {
        self.hud = nil;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.view.userInteractionEnabled = YES;
    }
}

- (void)showWifiRebootHud
{
    [self showHud];

    self.wifiRebootHud = self.hud;
    self.wifiRebootHud.labelText = @"Please wait...";
    self.hud = nil;
}

- (void)hideWifiRebootHud
{
    self.wifiRebootHud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

#pragma mark -

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.isScrolling = NO;
}

#pragma mark - 

- (void)joinWiFi:(NSString*)SSID encryption:(NSString*)encryption key:(NSString*)password sprinklerId:(NSString*)sprinklerId
{
    self.startDateWifiJoin = [NSDate date];
    
    self.duringWiFiRestart = YES;
//    self.networkSSIDChoosenForSprinkler = SSID;
//    self.apNetworkNameOfSprinkler = [self currentWifiName];
    
    self.joinWifiServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
    [self.joinWifiServerProxy setWiFiWithSSID:SSID encryption:encryption key:password];

    // After this point we should monitor the wifi change and handle the timeout and if macAddressOfSprinklerWithWiFiSetup is discovered on the new network
    // it means that the network was succesfully set up on the sprinkler and the setup wizard can continue
    // Don't test for sprinkler's current wifi to be the same as the iPhone's wifi, because it would be redundant (the device is discovered
    // only when it's on the same network, and since it was previously connected to the rainmachine's network the wifi change means rainmachine wifi > home wifi)
    
    [self showWifiRebootHud];
    
    [self restartPolling];
}

- (void)shouldStopBroadcast {
    
    [[ServiceManager current] stopBroadcast];
}

- (void)dealloc
{
    [self shouldStopBroadcast];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resetWiFiSetup
{
    self.duringWiFiRestart = NO;
}

- (void)cancelAllOperations
{
    [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
    [self.loginServerProxy cancelAllOperations];
    [self.requestCurrentWiFiProxy cancelAllOperations];
    [self.joinWifiServerProxy cancelAllOperations];
    [self.requestDiagProxy cancelAllOperations];
}

@end
