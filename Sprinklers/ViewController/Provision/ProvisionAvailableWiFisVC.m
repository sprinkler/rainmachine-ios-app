//
//  AvailableWiFisVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 03/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionAvailableWiFisVC.h"
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
#import "ProvisionLocationSetupVC.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AppDelegate.h"
#import "UpdateManager.h"
#import "DevicesVC.h"
#import "LightLeds.h"
#import "StorageManager.h"

#define kPollInterval 5
#define kWiFisPollInterval 5

const float kWifiSignalMin = -100;
const float kWifiSignalMax = -50;
const float kTimeout = 6;

@interface ProvisionAvailableWiFisVC ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabelPressAButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewRainmachineMini;

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
//@property (strong, nonatomic) NSDictionary *sprinklerCurrentWiFi;
@property (strong, nonatomic) NSDictionary *diagDict;
@property (strong, nonatomic) NSTimer *requestAllAvailableWiFiNetworksTimer;
@property (assign, nonatomic) int devicePollingRefreshSkipCountDown;

@property (strong, nonatomic) ServerProxy *requestAvailableWiFisProvisionServerProxy;
@property (strong, nonatomic) ServerProxy *loginServerProxy;
//@property (strong, nonatomic) ServerProxy *requestCurrentWiFiProxy;
@property (strong, nonatomic) ServerProxy *joinWifiServerProxy;
@property (strong, nonatomic) ServerProxy *requestDiagProxy;
@property (strong, nonatomic) NSDate *startDate;

@property (assign, nonatomic) BOOL isHidden;
@property (assign, nonatomic) BOOL refreshingAvailableWiFis;

@property (strong, nonatomic) NSString *homeWifiSSID;

@end

@implementation ProvisionAvailableWiFisVC

#pragma mark - UI

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
//    [self refreshState];

    self.title = self.isPartOfWizard ? @"Setup" : @"WiFi";

    [self setWizardNavBarForVC:self];

    self.messageLabel.hidden = YES;
    
    self.startDate = [NSDate date];
    
    self.firstStart = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(refreshAvailableWiFis:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)updateTVHeaderToHidden:(BOOL)hidden
{
    if (hidden) {
        self.tableView.tableHeaderView = nil;
    } else {
        self.tableView.tableHeaderView = self.headerView;
    }
}

- (void)appDidBecomeActive
{
//    [self shouldStartBroadcastForceUIRefresh:NO];
    self.sprinkler = nil;

    if (self.availableWiFis.count == 0) {
        [self showHud];
    }
//    [self restartPolling];
//    [self.devicesPollTimer fire];
}

- (void)appDidResignActive {
    [self shouldStopBroadcast];
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
                                       selector:@selector(refreshState)
                                       userInfo:nil
                                        repeats:NO];

        [self restartPolling];
    }

//    [self refreshState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.isPartOfWizard) {
        [[LightLeds sharedLightLeds] disableLightLeds];
        [[LightLeds sharedLightLeds] setSprinklerURL:nil];
    }
    
    [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
    self.requestAvailableWiFisProvisionServerProxy = nil;
    
    [self shouldStopBroadcast];
    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = nil;
    
    self.isHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)rowForOtherNetwork
{
    return (self.availableWiFis == nil) ? -1 : (int)(self.availableWiFis.count);
}

#pragma mark - Setters

- (void)setAvailableWiFis:(NSArray*)availableWiFis {
    if (!availableWiFis) {
        _availableWiFis = nil;
        return;
    }
    
    NSMutableArray *availableWiFisMut = [[NSMutableArray alloc] initWithArray:availableWiFis];
    
    NSSortDescriptor *signalSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"signal" ascending:NO];
    NSSortDescriptor *SSIDSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"SSID" ascending:YES];
    
    [availableWiFisMut sortUsingDescriptors:@[signalSortDescriptor,SSIDSortDescriptor]];
    
    _availableWiFis = availableWiFisMut;
}

#pragma mark - Refresh

- (IBAction)refreshAvailableWiFis:(id)sender {
    if (!self.refreshingAvailableWiFis) {
        self.refreshingAvailableWiFis = YES;
        [self startWiFiPoll];
    }
}

- (void)enableRefreshAvailableWiFisButton:(BOOL)enable {
    self.navigationItem.rightBarButtonItem.enabled = enable;
}

#pragma mark - Table view datasource

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
         cell.wifiTextLabel.text = (wifi.SSID.length ? wifi.SSID : @"Hidden");
         cell.wifiTextLabel.textColor = (wifi.SSID.length ? [UIColor blackColor] : [UIColor lightGrayColor]);
         
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

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo
{
    BOOL isJoinWifiServerProxy = (serverProxy == self.joinWifiServerProxy);
    // Fail silently when connection is lost: this error appears for ex. when /4/login is requested for a devices connected to a network but still unprovisioned
    if (error.code != NSURLErrorNetworkConnectionLost) {
        [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    }
    
    if ((serverProxy == self.requestAvailableWiFisProvisionServerProxy) || (serverProxy == self.requestDiagProxy)) {
        self.sprinkler = nil;
    }
    
    [self hideHud];
    
    if (serverProxy == self.requestAvailableWiFisProvisionServerProxy) {
        [self enableRefreshAvailableWiFisButton:YES];
        self.refreshingAvailableWiFis = NO;
    }
    
    if (!isJoinWifiServerProxy) {
        // Don't refresh state immediately after the wifi join request. Give some time for the sprinkler to restart
        [self refreshState];
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    self.messageLabel.hidden = YES;
    [self showPressAButtonUI:NO];
    
    BOOL isJoinWifiServerProxy = (serverProxy == self.joinWifiServerProxy);
    
//    if (serverProxy == self.requestCurrentWiFiProxy) {
//        self.sprinklerCurrentWiFi = data;
//        self.requestCurrentWiFiProxy = nil;
//        self.requestDiagProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:NO];
//        [self.requestDiagProxy requestDiag];
//    }
    if (serverProxy == self.requestDiagProxy) {
        self.requestDiagProxy = nil;

        self.diagDict = (NSDictionary*)data;

        [self loginWithDefaultPassword];
    }
    else if (serverProxy == self.requestAvailableWiFisProvisionServerProxy) {
        if ([data isKindOfClass:[NSArray class]]) {
            self.availableWiFis = [self wifisListByEliminatingDuplicatesFromList:data];
        }
        [self hideHud];
        [self enableRefreshAvailableWiFisButton:YES];
        self.refreshingAvailableWiFis = NO;
        
    }
    else if (serverProxy == self.joinWifiServerProxy) {
        // The sprinkler retarts, and if the connection to the home wifi succeeds it will get a new url
        self.joinWifiServerProxy = nil;
    }
    
    [self hideHud];

    if (!isJoinWifiServerProxy) {
        // Don't refresh state immediately after the wifi join request. Give some time for the sprinkler to restart
        [self refreshState];
    }
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit
{
    NSString *address = self.sprinkler.url;
    NSString *port = [Utils getPort:address];
    address = [Utils getBaseUrl:address];
    
    [NetworkUtilities saveAccessTokenForBaseURL:address port:port loginResponse:(Login4Response*)loginResponse];

    self.loginServerProxy = nil;
    
    self.loggedIn = YES;
    
    [self continueSetupLogicWithLoggedIn:YES];
}

- (void)loggedOut {
    
    [self hideHud];
    self.loginServerProxy = nil;
    
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
//    [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
//    self.sprinkler = nil;
    
    if (self.isPartOfWizard) {
        [self continueSetupLogicWithLoggedIn:NO];
    } else {
        [self pop];
    }
}

#pragma mark - Wizard logic

- (void)continueSetupLogicWithLoggedIn:(BOOL)loggedIn
{
    BOOL apMode = [self.diagDict[@"wifiMode"] isEqualToString:@"ap"];
    if (loggedIn) {
        if (apMode) {
            // Sprinkler hasn't connected yet to any WiFi. Continue with the WiFi setup wizard
            [self startWiFiPoll];
        } else {
            [self continueWithPasswordAndNameSetupPresentOldPasswordField:NO];
        }
    } else {
        if (apMode) {
//            if (self.alertView.tag != kAlertView_SetupWizard_CancelWizard) {
//                self.alertView = [[UIAlertView alloc] initWithTitle:@"Cannot start setup wizard" message:@"Press a button on your sprinkler." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                self.alertView.tag = kAlertView_SetupWizard_CannotStart;
//                [self.alertView show];
//            }
            self.messageLabel.hidden = YES;
            [self showPressAButtonUI:YES];
            
            [[LightLeds sharedLightLeds] setSprinklerURL:self.sprinkler.url];
            [[LightLeds sharedLightLeds] enableLightLeds];
            
            self.sprinkler = nil;
        } else {
            NSString *address = self.sprinkler.url;
            NSString *port = [Utils getPort:address];
            address = [Utils getBaseUrl:address];
            // Rainmachine pwd was set up, it's sure
            if ([NetworkUtilities accessTokenForBaseUrl:address port:port]) {
                // Token is either deleted, or the setup was continued from another device than the one from which it was started
                [self continueWithLocationSetup];
            } else {
                [self continueWithPasswordAndNameSetupPresentOldPasswordField:YES];
            }
        }
    }

    if (self.duringWiFiRestart) {
        // We expected for the sprinkler to reconnect to home WiFi, but reconnected back to the sprinkler's AP WiFi
        [self resetWiFiSetup];

        if (apMode) {
            self.alertView = [[UIAlertView alloc] initWithTitle:@"WiFi Setup failed" message:@"It seems that the WiFi network setup on your sprinkler failed. Press OK and after the available WiFi list appears select again your home network." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = kAlertView_SetupWizard_ReconnectedToSprinkler;
            [self.alertView show];
            
            [self showHud];
            
            self.startDateWifiJoin = nil;
            
            [self pollDevices];
        }
    }
}

- (void)continueWithLocationSetup
{
    // This cancels also the continuos available wifi networks query
    [self cancelAllOperations];

    ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
    locationSetupVC.sprinkler = self.sprinkler;
//    locationSetupVC.delegate = self;
    locationSetupVC.isPartOfWizard = YES;
    
    [self.navigationController pushViewController:locationSetupVC animated:YES];
}

- (void)continueWithPasswordAndNameSetupPresentOldPasswordField:(BOOL)presentOldPasswordField
{
    // This cancels also the continuos available wifi networks query
    [self cancelAllOperations];
    
    ProvisionNameSetupVC *provisionNameSetupVC = [ProvisionNameSetupVC new];
    provisionNameSetupVC.sprinkler = self.sprinkler;
    provisionNameSetupVC.presentOldPasswordField = presentOldPasswordField;
    [self.navigationController pushViewController:provisionNameSetupVC animated:YES];
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

- (BOOL)didJoinHomeWiFi
{
    return ([[self currentWiFiName] isEqualToString:self.homeWifiSSID]);
}

- (void)pollDevices {
    
    if (self.duringWiFiRestart && self.homeWifiSSID) {
        
        if ([self didJoinHomeWiFi]) {
            self.wifiRebootHud.detailsLabelText = [NSString stringWithFormat:@"Waiting for RainMachine to join\nnetwork %@\n(this may take up to 3 minutes)",self.homeWifiSSID];
            self.devicePollingRefreshSkipCountDown = 0;
        }
    }
    
    if (self.devicePollingRefreshSkipCountDown > 0) {
        self.devicePollingRefreshSkipCountDown--;
        // Quit the method before aprox. 30s passes
        [self shouldStartBroadcastForceUIRefresh:NO];
        return;
    }

    // Handle the timeout for phone joining the WiFi
    if (self.duringWiFiRestart && self.homeWifiSSID) {
        if (![self didJoinHomeWiFi]) {
            // The phone could not join home WiFi (happens after aprox. 30 seconds timeout)

            NSArray *discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:self.isPartOfWizard ? @NO : @YES];
            DiscoveredSprinklers *newSprinkler = [self extractInputSprinklerFromList:discoveredSprinklers];
            NSString *message = nil;
            
            // We are not on home network
            if (newSprinkler) {
                // Case 1.1 The sprinker is still discovered. This means that the phone is still connected the SPK AP
                // TODO: Normally, after this message we should take the user to tge WiFi setup screen again.
                message = [NSString stringWithFormat:@"RainMachine could not join the network %@, please try again", self.homeWifiSSID];
            } else {
                // Case 1.2 The sprinker is not discovered. This means that the phone connected by fault to another WiFi (not home network)
                message = [NSString stringWithFormat:@"You are on the network %@, please go to Settings on your phone and select the network %@", [self currentWiFiName], self.homeWifiSSID];
            }

            self.startDateWifiJoin = nil;
            
            [self hideHud];
            [self hideWifiRebootHud];
            
            [self resetWiFiSetup];
            
            self.forceQuit = YES;
            self.alertView = [[UIAlertView alloc] initWithTitle:@"Timeout" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = kAlertView_SetupWizard_WifiJoinTimedOut;
            [self.alertView show];
            
            return;
        }
    }
    
    [self refreshState];
    [self shouldStartBroadcastForceUIRefresh:NO];
}

- (DiscoveredSprinklers*)extractInputSprinklerFromList:(NSArray*)discoveredSprinklers
{
    DiscoveredSprinklers *s = nil;
    for (DiscoveredSprinklers *ds in discoveredSprinklers) {
        if ([ds.sprinklerId isEqualToString:self.inputSprinklerMAC]) {
            s = ds;
            break;
        }
    }
    
    return s;
}

- (void)refreshState
{
    BOOL timedOut = NO;
    DLog(@"connected to network: %@", [NetworkUtilities currentSSIDInfo]);
    
    if (self.isPartOfWizard) {
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.startDate];
        if (t > kTimeout) {
            timedOut = YES;
            self.startDate = [NSDate date];
            
            [self hideHud];
        }
    }

    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:self.isPartOfWizard ? @NO : @YES];
    
//    [self hideHud];
    
    if (self.isScrolling) {
        return;
    }
    
    if (self.alertView) {
        return;
    }
    
//    if ((self.sprinkler) && (!self.availableWiFis)) {
//        [self showHud];
//    }
    
    if (self.startDateWifiJoin) {
        NSTimeInterval since = -[self.startDateWifiJoin timeIntervalSinceNow];
        // Handle the timeout for SPK joining the WiFi
        if (since > kWizard_TimeoutWifiJoin) {
            // The WiFi is home network / another network / Rainmachine AP / or no-network
            NSString *message = [NSString stringWithFormat:@"RainMachine could not join the network %@. Please go to iOS settings on your phone and connect back to your Rainmachine to continue.", self.homeWifiSSID];
            if ([self currentWiFiName] == nil) {
                message = @"Connecting the Rainmachine to your home network timed out because your device didn't reconnect to your home network. Go to Settings and connect to your home network in order to continue the setup.";
            }
            if (!self.isPartOfWizard) {
                message = [NSString stringWithFormat:@"RainMachine could not join the network %@.", self.homeWifiSSID];
            }
            self.forceQuit = YES;
            self.alertView = [[UIAlertView alloc] initWithTitle:@"Timeout" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.alertView.tag = kAlertView_SetupWizard_WifiJoinTimedOut;
            [self.alertView show];
            
            self.startDateWifiJoin = nil;
            
            [self hideHud];
            [self hideWifiRebootHud];
            
            [self resetWiFiSetup];
            
            //            [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
            
            return;
        }
    }
    
    DiscoveredSprinklers *newSprinkler = nil;
    if (self.inputSprinklerMAC) {
        newSprinkler = [self extractInputSprinklerFromList:self.discoveredSprinklers];
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
            DLog(@"currentSprinkler: %@", currentSprinkler);
            DLog(@"newSprinkler: %@", newSprinkler);
            
            if (self.duringWiFiRestart) {
                if (self.isPartOfWizard) {
                    [NetworkUtilities invalidateLoginForDiscoveredSprinkler:self.sprinkler];
                } else {
                    [StorageManager current].currentSprinkler.address = [Utils fixedSprinklerAddress:self.sprinkler.host];
                    [[StorageManager current] saveData];
                    [self pop];
                }
            }
            
            if (self.isPartOfWizard) {
                [self requestDiag];
            } else {
                if (!self.duringWiFiRestart) {
                    [self startWiFiPoll];
                }
            }
        }
    }
    
    if (self.isPartOfWizard) {
        if (!self.sprinkler) {
            [self showPressAButtonUI:NO];
            self.messageLabel.hidden = (self.firstStart) || (self.duringWiFiRestart) || (self.hud != nil) || (self.wifiRebootHud != nil);
            
            if (timedOut) {
                self.messageLabel.hidden = NO;
            }
        } else {
            self.messageLabel.hidden = YES;
        }
    } else {
        self.messageLabel.hidden = YES;
    }
    
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

- (void)joinWiFi:(NSString*)SSID encryption:(NSString*)encryption key:(NSString*)password sprinklerId:(NSString*)sprinklerId
{
    [self cancelAllOperations];
    
    self.startDateWifiJoin = [NSDate date];
    
    self.duringWiFiRestart = YES;
    self.homeWifiSSID = SSID;
    
    //    self.networkSSIDChoosenForSprinkler = SSID;
    //    self.apNetworkNameOfSprinkler = [self currentWifiName];
    
    self.joinWifiServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
    [self.joinWifiServerProxy setWiFiWithSSID:SSID encryption:encryption key:password];
    
    // After this point we should monitor the wifi change and handle the timeout and if macAddressOfSprinklerWithWiFiSetup is discovered on the new network
    // it means that the network was succesfully set up on the sprinkler and the setup wizard can continue
    // Don't test for sprinkler's current wifi to be the same as the iPhone's wifi, because it would be redundant (the device is discovered
    // only when it's on the same network, and since it was previously connected to the rainmachine's network the wifi change means rainmachine wifi > home wifi)
    
    self.sprinkler = nil;
    
    [self showWifiRebootHud];
    
    // The device discovery will be restarted by method pollDevices. Until then no broadcast discovery message will be sent.
    // Clear all discovered device until this point, because refreshStatus would use the device with the old URL (192.168.13.1)
    [[ServiceManager current] clearDiscoveredSprinklers];
    
    // Give the sprinkler ((devicePollingRefreshSkipCountDown + 1) * 5) seconds to restart and prevent self.sprinkler to get reassigned to a sprinkler which has the current state without wifi set up
    self.devicePollingRefreshSkipCountDown = 5;
    [self restartPolling];
}

- (void)resetWiFiSetup
{
    [self hideWifiRebootHud];
    self.duringWiFiRestart = NO;
    self.homeWifiSSID = nil;
}

- (NSArray*)wifisListByEliminatingDuplicatesFromList:(NSArray*)wifisList {
    NSMutableDictionary *wifisDictionary = [NSMutableDictionary new];
    NSMutableArray *hiddenWifis = [NSMutableArray new];
    
    for (WiFi *wifi in wifisList) {
        if (!wifi.SSID.length) {
            [hiddenWifis addObject:wifi];
            continue;
        }
        
        WiFi *detectedWifi = [wifisDictionary objectForKey:wifi.SSID];
        if (!detectedWifi) [wifisDictionary setObject:wifi forKey:wifi.SSID];
        else if (detectedWifi.signal.floatValue < wifi.signal.floatValue) {
            [wifisDictionary setObject:wifi forKey:wifi.SSID];
        }
    }
    
    NSMutableArray *filteredWifisList = [wifisDictionary.allValues mutableCopy];
    [filteredWifisList addObjectsFromArray:hiddenWifis];
    
    return filteredWifisList;
}

#pragma mark - Requests

- (void)startWiFiPoll
{
    [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];

    [self.requestAllAvailableWiFiNetworksTimer invalidate];
    self.requestAllAvailableWiFiNetworksTimer = [NSTimer scheduledTimerWithTimeInterval:kWiFisPollInterval target:self selector:@selector(requestAllAvailableWiFiNetworks) userInfo:nil repeats:YES];
    [self.requestAllAvailableWiFiNetworksTimer fire];
}

- (void)requestAllAvailableWiFiNetworks
{
    if (!self.isHidden) {
        if (self.sprinkler) {
            [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
            self.requestAvailableWiFisProvisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
            [self.requestAvailableWiFisProvisionServerProxy requestAvailableWiFis];
            
            if (self.availableWiFis.count == 0 || self.refreshingAvailableWiFis) {
                [self showHud];
            }
        }
    }
}

//- (void)requestCurrentWiFi
//{
//    self.requestCurrentWiFiProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
//    [self.requestCurrentWiFiProxy requestCurrentWiFi];
//}

- (void)loginWithDefaultPassword
{
    [self.loginServerProxy cancelAllOperations];
    self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
    
    // Try to log in automatically
    [self.loginServerProxy loginWithUserName:@"admin" password:@"" rememberMe:YES];
}

- (void)requestDiag
{
    [self.requestDiagProxy cancelAllOperations];
    self.requestDiagProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:NO];
    [self.requestDiagProxy requestDiag];

    [self showHud];
}

- (void)cancelAllOperations
{
    [self.requestAllAvailableWiFiNetworksTimer invalidate];
    self.requestAllAvailableWiFiNetworksTimer = nil;
    
    [self.requestAvailableWiFisProvisionServerProxy cancelAllOperations];
    [self.loginServerProxy cancelAllOperations];
    //    [self.requestCurrentWiFiProxy cancelAllOperations];
    [self.joinWifiServerProxy cancelAllOperations];
    [self.requestDiagProxy cancelAllOperations];
}

#pragma mark - UI - HUD, Alert views

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    
    self.alertView = nil;
    
    if (theAlertView.tag == kAlertView_SetupWizard_ReconnectedToSprinkler) {
        [self showHud];
    }
    
    if (theAlertView.tag == kAlertView_SetupWizard_CannotStart) {
        self.sprinkler = nil;
        
        [self showHud];
    }
    else if (theAlertView.tag == kAlertView_SetupWizard_WifiJoinTimedOut) {
        if (self.isPartOfWizard) {
            // Prevent the user to be able to open the device from the device list because the login token is valid but the device is not usable
            [self onCancel:nil];
        } else {
            [StorageManager current].currentSprinkler = nil;
            [[StorageManager current] saveData];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate refreshRootViews:nil selectSettings:NO];
        }
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

- (void)showPressAButtonUI:(BOOL)show
{
    if (self.isPartOfWizard) {
        self.messageLabelPressAButton.hidden = !show;
        self.imageViewRainmachineMini.hidden = !show;
    }
}

- (void)showWifiRebootHud {
    [self showHud];

    self.wifiRebootHud = self.hud;
    self.wifiRebootHud.detailsLabelText = [NSString stringWithFormat:@"Joining network\n%@",self.homeWifiSSID],
    self.wifiRebootHud.detailsLabelFont = [UIFont boldSystemFontOfSize:16.0];
    self.hud = nil;
}

- (void)hideWifiRebootHud {
    self.wifiRebootHud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - Scroll view

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.isScrolling = NO;
}

#pragma mark - Network

- (void)shouldStopBroadcast {
    
    [[ServiceManager current] stopBroadcast];
}

- (void)shouldStartBroadcastForceUIRefresh:(BOOL)forceUIRefresh
{
    //    [self shouldStopBroadcast];
    self.startDate = [NSDate date];
    [[ServiceManager current] startBroadcastForSprinklers:YES];
}

- (NSString*)currentWiFiName
{
    NSDictionary *currentWifi = [NetworkUtilities currentSSIDInfo];
    return currentWifi[@"SSID"];
}

- (void)pop
{
    [self cancelAllOperations];
    [self shouldStopBroadcast];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc
{
    [self cancelAllOperations];
    [self shouldStopBroadcast];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
