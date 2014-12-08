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

const float kWifiSignalMin = -70;
const float kWifiSignalMax = -30;

@interface AvailableWiFisVC ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) NSArray *discoveredSprinklers;
@property (strong, nonatomic) DiscoveredSprinklers *sprinkler;
@property (strong, nonatomic) ServerProxy *provisionServerProxy;
@property (strong, nonatomic) ServerProxy *loginServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSArray *availableWiFis;
@property (strong, nonatomic) NSTimer *devicesPollTimer;
@property (strong, nonatomic) ProvisionWiFiVC *provisionWiFiVC;

@end

@implementation AvailableWiFisVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"WiFiCell" bundle:nil] forCellReuseIdentifier:@"WiFiCell"];

    self.descriptionLabel.backgroundColor = self.tableView.backgroundColor;
    self.view.backgroundColor = self.descriptionLabel.backgroundColor;
    
    [ServerProxy setSprinklerVersionMajor:4 minor:0 subMinor:0];

    // Do any additional setup after loading the view from its nib.
    [self refreshUI];

    [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(refreshUI)
                                   userInfo:nil
                                    repeats:YES];
    
    self.title = @"New RainMachine";
}

- (void)refreshUI
{
    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
    
    DiscoveredSprinklers *oldSprinkler = [self.discoveredSprinklers firstObject];
    BOOL areUrlsEqual = [[oldSprinkler url] isEqualToString:[self.sprinkler url]];
    if (!areUrlsEqual) {
        self.sprinkler = [self.discoveredSprinklers firstObject];

        if (self.sprinkler) {
            [self showHud];
            
            self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
            self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];

            // Try to log in automatically
            [self.loginServerProxy loginWithUserName:@"" password:@"" rememberMe:NO];
        }
    }
    
    if (self.sprinkler) {
        self.tableView.hidden = NO;
        self.descriptionLabel.hidden = (self.availableWiFis == nil);
        self.messageLabel.hidden = YES;
        self.title = self.sprinkler.sprinklerName;
    } else {
        self.tableView.hidden = YES;
        self.descriptionLabel.hidden = YES;
        self.messageLabel.hidden = NO;
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                     target:self
                                   selector:@selector(pollDevices)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.devicesPollTimer invalidate];
    self.devicesPollTimer = nil;
}

- (void)pollDevices
{
    [[ServiceManager current] startBroadcastForSprinklers:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
         cell.textLabel.text = wifi.SSID;
         
         NSString *imageName = nil;
         float signal = [wifi.signal floatValue];
         int signalDiscreteValue = (3 * (signal - kWifiSignalMin)) / (kWifiSignalMax - kWifiSignalMin);
         if (signalDiscreteValue <= 2) {
             imageName = [NSString stringWithFormat:@"icon_wi-fi-%d-bar", (int)signalDiscreteValue];
         } else {
             imageName = [wifi.isEncrypted boolValue] ? @"icon_wi-fi-full" : nil;
         }
         cell.signalImageView.image = [UIImage imageNamed:imageName];
     } else {
         if (indexPath.row == [self rowForOtherNetwork]) {
             cell = (WiFiCell*)[tableView dequeueReusableCellWithIdentifier:@"WiFiCell" forIndexPath:indexPath];
             cell.textLabel.text = @"Other...";
         }
     }
     
     return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.availableWiFis.count ? @"CHOOSE A NETWORK..." : nil;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


 #pragma mark - Table view delegate
 
 // In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 // Navigation logic may go here, for example:
 // Create the next view controller.

     [tableView deselectRowAtIndexPath:indexPath animated:YES];
     
     if (indexPath.row < self.availableWiFis.count) {
         WiFi *wifi = self.availableWiFis[indexPath.row];
         BOOL needsPassword;
         NSString *securityOption = [Utils securityOptionFromSprinklerWiFi:wifi needsPassword:&needsPassword];
         self.provisionWiFiVC = [[ProvisionWiFiVC alloc] init];
         self.provisionWiFiVC.SSID = wifi.SSID;
         self.provisionWiFiVC.delegate = self;
         self.provisionWiFiVC.sprinkler = self.sprinkler;
         if (needsPassword) {
             self.provisionWiFiVC.showSSID = NO;
             self.provisionWiFiVC.securityOption = securityOption;
         } else {
             self.provisionWiFiVC.securityOption = @"None";
             self.provisionWiFiVC.loginAutomatically = YES;
         }
         UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionWiFiVC];
         [self.navigationController presentViewController:navDevices animated:YES completion:nil];
     } else {
         self.provisionWiFiVC = [[ProvisionWiFiVC alloc] init];
         self.provisionWiFiVC.securityOption = nil;
         self.provisionWiFiVC.showSSID = YES;
         UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionWiFiVC];
         [self.navigationController presentViewController:navDevices animated:YES completion:nil];
     }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

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
    
    if (serverProxy == self.provisionServerProxy) {
        self.availableWiFis = data;
    }
    
    [self hideHud];
    
    [self refreshUI];
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
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - 

@end
