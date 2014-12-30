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
#import <SystemConfiguration/CaptiveNetwork.h>

#define kPollInterval 6

const float kWifiSignalMin = -100;
const float kWifiSignalMax = -50;

@interface AvailableWiFisVC ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) NSArray *discoveredSprinklers;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) ServerProxy *provisionServerProxy;
@property (strong, nonatomic) ServerProxy *loginServerProxy;
@property (strong, nonatomic) ServerProxy *requestCurrentWiFiProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) MBProgressHUD *wifiRebootHud;
@property (strong, nonatomic) NSArray *availableWiFis;
@property (strong, nonatomic) NSTimer *devicesPollTimer;
@property (strong, nonatomic) ProvisionWiFiVC *provisionWiFiVC;
@property (assign, nonatomic) BOOL isScrolling;
@property (strong, nonatomic) UILabel *headerView;

@end

@implementation AvailableWiFisVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isScrolling = NO;

    [self.tableView registerNib:[UINib nibWithNibName:@"WiFiCell" bundle:nil] forCellReuseIdentifier:@"WiFiCell"];

    self.view.backgroundColor = self.tableView.backgroundColor;
    
    [ServerProxy setSprinklerVersionMajor:4 minor:0 subMinor:0];
    
    self.headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 46)];
    self.headerView.text = @"Connect your Rain Machine to a WiFi network";
    self.headerView.textColor = [UIColor darkGrayColor];
    self.headerView.numberOfLines = 0;
    self.headerView.textAlignment = NSTextAlignmentCenter;

    // Do any additional setup after loading the view from its nib.
    [self refreshUI];

    self.title = @"New RainMachine";
}

- (void)updateTVHeaderToHidden:(BOOL)hidden
{
    if (hidden) {
        self.tableView.tableHeaderView = nil;
    } else {
        self.tableView.tableHeaderView = self.headerView;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self restartPolling];
    
    [self.devicesPollTimer fire];
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
    
    [self refreshUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = nil;
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
    if (self.isScrolling) {
        return;
    }
    
#if DEBUG
    NSLog(@"connected to network: %@", [self fetchSSIDInfo]);
#endif
    
    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:NO];

    DiscoveredSprinklers *newSprinkler = [self.discoveredSprinklers firstObject];
    DiscoveredSprinklers *currentSprinkler = self.sprinkler;
    BOOL areUrlsEqual = [[newSprinkler url] isEqualToString:[currentSprinkler url]];
    if (!areUrlsEqual) {
        self.sprinkler = newSprinkler;

        if (self.sprinkler) {
            [self showHud];
            
            self.requestCurrentWiFiProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
            [self.requestCurrentWiFiProxy requestCurrentWiFi];
        }
    }
    
    if (self.sprinkler) {
        self.tableView.hidden = NO;
        [self updateTVHeaderToHidden:(self.availableWiFis == nil)];
        self.messageLabel.hidden = YES;
        self.title = self.sprinkler.sprinklerName;
    } else {
        self.tableView.hidden = YES;
        [self updateTVHeaderToHidden:YES];
        self.messageLabel.hidden = NO;
    }
    
    [self.tableView reloadData];
}

- (void)pollDevices
{
    [self refreshUI];

    [[ServiceManager current] startBroadcastForSprinklers:NO];
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
                 imageName = [wifi.isEncrypted boolValue] ? @"icon_wi-fi-full" : nil;
             }
         }
         cell.signalImageView.image = [UIImage imageNamed:imageName];
         cell.lockedImageView.image = [UIImage imageNamed:@"icon_wi-fi-locked.png"];
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
    
    if (serverProxy == self.provisionServerProxy) {
//        self.provisionServerProxy = nil;
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.requestCurrentWiFiProxy) {
        NSDictionary *currentWifi = data;
        if ((currentWifi[@"ssid"] == nil) || ([currentWifi[@"ssid"] isKindOfClass:[NSNull class]])) {
            // Continue with the WiFi setup wizard
            self.requestCurrentWiFiProxy = nil;
            self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
            self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
            
            // Try to log in automatically
            [self.loginServerProxy loginWithUserName:@"" password:@"" rememberMe:YES];
        } else {
            // Continue with the RainMachine name setup wizard
            [self hideWifiRebootHud];
            // If view is started from the Device menu, just continue the name setup of the found rain machine.
            // Otherwise, make sure that we continue with the setup of the current device
            BOOL doNameSetup = YES;
            if (self.macAddressOfSprinklerWithWiFiSetup) {
                doNameSetup = [self.macAddressOfSprinklerWithWiFiSetup isEqualToString:[self.sprinkler sprinklerId]];
            }
            if (doNameSetup) {
                NSLog(@"*****");
                UINavigationController *navigationController = self.navigationController;
                [self.navigationController popToRootViewControllerAnimated:NO];
                ProvisionNameSetupVC *provisionNameSetupVC = [ProvisionNameSetupVC new];
                provisionNameSetupVC.sprinkler = self.sprinkler;
                [navigationController pushViewController:provisionNameSetupVC animated:YES];
            } else {
                // TODO: timeout
            }
        }
    }
    
    if (serverProxy == self.provisionServerProxy) {
        self.availableWiFis = data;
        [self hideHud];
        [self refreshUI];
    }
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit {
    
    NSString *address = self.sprinkler.url;
    if ([address hasSuffix:@"/"]) {
        address = [address substringToIndex:address.length - 1];
    }
    NSString *port = [Utils getPort:address];
    if ([port length] > 0) {
        if ([port length] + 1  < [address length]) {
            address = [address substringToIndex:[address length] - ([port length] + 1)];
        }
    }
    [NetworkUtilities saveAccessTokenForBaseURL:address port:port loginResponse:(Login4Response*)loginResponse];

    self.loginServerProxy = nil;
    
    [self.provisionServerProxy requestAvailableWiFis];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    
    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = nil;
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
    self.macAddressOfSprinklerWithWiFiSetup = self.sprinkler.sprinklerId;
    [self.provisionServerProxy setWiFiWithSSID:SSID encryption:encryption key:password];

    [self showWifiRebootHud];
    self.sprinkler = nil;
    
//    [self refreshUI];
    [self restartPolling];
}

@end
