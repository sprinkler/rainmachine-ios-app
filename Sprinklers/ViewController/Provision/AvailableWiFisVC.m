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
}

- (void)refreshUI
{
    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
    
    DiscoveredSprinklers *oldSprinkler = [self.discoveredSprinklers firstObject];
    BOOL areUrlsEqual = [[oldSprinkler url] isEqualToString:[self.sprinkler url]];
    if (!areUrlsEqual) {
        NSLog(@"new sprinkler.url: %@", [self.sprinkler url]);
        NSLog(@"old sprinkler.url: %@", [oldSprinkler url]);
        NSLog(@"equal: %d", areUrlsEqual);

        self.sprinkler = [self.discoveredSprinklers firstObject];

        if (self.sprinkler) {
            [self showHud];
            
            self.loginServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:[ServerProxy usesAPI4]];
            self.provisionServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:NO];

            [self.loginServerProxy loginWithUserName:@"" password:@"" rememberMe:NO];
        }
    }
    
    if (self.sprinkler) {
        self.tableView.hidden = NO;
        self.descriptionLabel.hidden = (self.availableWiFis.count == 0);// ? @"" : @"Connect your Rain Machine to a WiFi network";
        self.messageLabel.hidden = YES;
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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.availableWiFis.count;
}

 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WiFiCell" forIndexPath:indexPath];
     WiFi *wifi = self.availableWiFis[indexPath.row];
     cell.textLabel.text = wifi.SSID;
     
 // Configure the cell...
 
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

     self.provisionWiFiVC = [[ProvisionWiFiVC alloc] init];
     self.provisionWiFiVC.securityOption = @"None";
     self.provisionWiFiVC.showSSID = NO;
     UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.provisionWiFiVC];
     [self.navigationController presentViewController:navDevices animated:YES completion:nil];
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
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
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

- (void)loginSucceededAndRemembered:(BOOL)remembered unit:(NSString*)unit {
    
    self.loginServerProxy = nil;
    
    [self.provisionServerProxy requestAvailableWiFis];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
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

- (void)joinWiFi:(NSString*)SSID encryption:(NSString*)encryption key:(NSString*)password
{
    [self.provisionServerProxy setWiFiWithSSID:SSID encryption:encryption key:password];
}

@end
