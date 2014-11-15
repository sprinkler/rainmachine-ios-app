//
//  DevicesVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "DevicesVC.h"
#import "Additions.h"
#import "LoginVC.h"
#import "AddNewDeviceVC.h"
#import "Sprinkler.h"
#import "DiscoveredSprinklers.h"
#import "DevicesCellType1.h"
#import "DevicesCellType2.h"
#import "AddNewCell.h"
#import "ServiceManager.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"
#import "Utils.h"
#import "CloudUtils.h"
#import "LoginVC.h"
#import "SetDelayVC.h"
#import "AddNewDeviceVC.h"
#import "AppDelegate.h"
#import "TimePickerVC.h"
#import "ServerProxy.h"

#define kAlertView_DeleteDevice 1

@interface DevicesVC () {
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *savedSprinklers;
@property (strong, nonatomic) NSDictionary*cloudResponse;
@property (strong, nonatomic) NSDictionary *cloudSprinklers;
@property (strong, nonatomic) NSArray *cloudEmails;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ServerProxy *cloudServerProxy;
@property (strong, nonatomic) NSTimer *networkDevicesTimer;

@end

@implementation DevicesVC

#pragma mark - Init

+ (void)initialize {
    NSDictionary *defaults = @{kCloudProxyFinderURLKey : kCloudProxyFinderURL};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidResignActive) name:@"ApplicationDidResignActive" object:nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    _tableView.allowsSelectionDuringEditing = YES;
    
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType1" bundle:nil] forCellReuseIdentifier:@"DevicesCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType2" bundle:nil] forCellReuseIdentifier:@"DevicesCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
    [self createFooter];
    
    [self updateNavigationbarButtons];
}

// Overwrites BaseViewController's updateTitle
- (void)updateTitle
{
    self.title = @"Devices";
}

- (void)updateNavigationbarButtons
{
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = nil;
    
    if (self.tableView.isEditing) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self shouldStopBroadcast];
    [self.networkDevicesTimer invalidate];
    self.networkDevicesTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.tableView.isEditing) {
        [self refreshSprinklerList];
        [self shouldStartBroadcastForceUIRefresh:NO];
        
        NSDictionary *cloudAccounts = [CloudUtils cloudAccounts];
        self.cloudEmails = [cloudAccounts allKeys];
        
        [self requestCloudSprinklers:cloudAccounts];
    }
    
    [self.tableView reloadData];

    self.networkDevicesTimer = [NSTimer scheduledTimerWithTimeInterval:kNetworkDevicesDiscoveryInterval
                                           target:self
                                         selector:@selector(shouldStartBroadcastTimer)
                                         userInfo:nil
                                          repeats:YES];
}

#pragma mark - Methods

- (NSString*)cloudProxyFinderURL {
#if DEBUG
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey];
#else
    return kCloudProxyFinderURL;
#endif
}

- (void)requestCloudSprinklers:(NSDictionary*)cloudAccounts
{
    if (cloudAccounts.count > 0) {
        self.cloudServerProxy = [[ServerProxy alloc] initWithServerURL:self.cloudProxyFinderURL delegate:self jsonRequest:YES];
        [self.cloudServerProxy requestCloudSprinklers:cloudAccounts];
        [self startHud:nil];
    }
}

- (void)refreshSprinklerList
{
    NSArray *sprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_All aliveDevices:@YES];
    
    // Sort sprinklers into:
    // 1) savedSprinklers array (manually entered or discovered on the network)
    // 2) cloudSprinklers dictionary
    NSMutableArray *networkOrManuallyEnteredSprinklers = [NSMutableArray array];
    NSMutableDictionary *cloudSprinklersDic = [NSMutableDictionary dictionary];
    for (Sprinkler *sprinkler in sprinklers) {
        if (sprinkler.email) {
            sprinkler.isDiscovered = @NO;
            if (!cloudSprinklersDic[sprinkler.email]) {
                cloudSprinklersDic[sprinkler.email] = [NSMutableArray array];
            }
            [cloudSprinklersDic[sprinkler.email] addObject:sprinkler];
        } else {
            [networkOrManuallyEnteredSprinklers addObject:sprinkler];
        }
    }
    self.savedSprinklers = networkOrManuallyEnteredSprinklers;
    self.cloudSprinklers = cloudSprinklersDic;
}

- (void)createFooter {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    label.text = [NSString stringWithFormat:@"Version: %@", version];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = label;
}


- (void)shouldStartBroadcastTimer
{
    [self shouldStartBroadcastForceUIRefresh:YES];
}

- (void)shouldStartBroadcastForceUIRefresh:(BOOL)forceUIRefresh {
    if (!self.tableView.isEditing) {
        [self shouldStopBroadcast];
        
        if (forceUIRefresh) {
            // Process the list of discovered devices before starting a new discovery process
            // We do the processing until here, because otherwise, when no sprinklers in the network, the 'SprinklersDiscovered' callback is not called at all
            [self SprinklersDiscovered];
        }
        
        [[ServiceManager current] startBroadcastForSprinklers:NO];
    }
}

-(void) SprinklersDiscovered
{
    NSArray *discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
 
    // Mark all non-discovered sprinklers as not-alive
    NSArray *localSprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Local aliveDevices:@YES];
    for (Sprinkler *sprinkler in localSprinklers) {
        sprinkler.isDiscovered = @NO;
    }
    
    // Convert the DiscoveredSprinkler objects into Sprinkler objects
    // Update all discovered ones or add them as new sprinklers
    for (int i = 0; i < [discoveredSprinklers count]; i++) {
        DiscoveredSprinklers *discoveredSprinkler = discoveredSprinklers[i];
        NSString *port = [NSString stringWithFormat:@"%d", discoveredSprinkler.port];
        Sprinkler *sprinkler = [[StorageManager current] getSprinkler:discoveredSprinkler.sprinklerName address:[Utils fixedSprinklerAddress:discoveredSprinkler.host] port:port local:@YES email:nil];
        if (!sprinkler) {
            sprinkler = [[StorageManager current] addSprinkler:discoveredSprinkler.sprinklerName ipAddress:discoveredSprinkler.host port:port isLocal:@YES email:nil save:NO];
        }
        sprinkler.isDiscovered = @YES;
    }
    
    [[StorageManager current] saveData];
    
    [self refreshSprinklerList];
    
    [_tableView reloadData];
}

- (void)shouldStopBroadcast {
    
    [[ServiceManager current] stopBroadcast];
}

- (void)appDidBecomeActive {
    [self shouldStartBroadcastForceUIRefresh:NO];
}

- (void)appDidResignActive {
    [self shouldStopBroadcast];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
 }

- (void)shouldStartSilentBroadcast {
    [[ServiceManager current] startBroadcastForSprinklers:YES];
    [self performSelector:@selector(refreshList) withObject:nil afterDelay:2.0];
}

- (void)updateVisibleCellsForEditMode {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
        
        if (![cell isKindOfClass:[DevicesCellType1 class]]) continue;
        
        DevicesCellType1 *deviceCell = (DevicesCellType1*)cell;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:deviceCell];
        deviceCell.disclosureImageView.hidden = (self.tableView.isEditing) || (!deviceCell.sprinkler.isDiscovered.boolValue);
        deviceCell.labelInfo.hidden = self.tableView.isEditing;
        
        if (self.tableView.isEditing && [self tableView:self.tableView canEditRowAtIndexPath:indexPath]) {
            deviceCell.disclosureImageView.hidden = NO;
            deviceCell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    }
}

#pragma mark - Actions

- (void)done
{
    [self done:nil];
}

- (void)done:(NSString*)unit {
    if (self.tableView.isEditing) {
        [self.tableView setEditing:NO animated:YES];
        [self updateVisibleCellsForEditMode];
        [self updateNavigationbarButtons];
        [self shouldStartBroadcastForceUIRefresh:NO];
        return;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate refreshRootViews:unit];
}

- (void)edit {
    [self.tableView setEditing:YES animated:YES];
    [self updateVisibleCellsForEditMode];
    [self updateNavigationbarButtons];
    [self shouldStopBroadcast];
}

- (void)onRefresh:(id)notification {
    [self shouldStartBroadcastForceUIRefresh:NO];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + self.cloudEmails.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.savedSprinklers.count;
    }
    
    if (section < 1 + self.cloudEmails.count) {
        int sprinklersNr = (int)[self.cloudSprinklers[self.cloudEmails[section - 1]] count];
        return sprinklersNr > 0 ? sprinklersNr : 1;
    }
    
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ((section > 0) && (section < 1 + self.cloudEmails.count)) {
        return self.cloudEmails[section - 1];
    }
    
    return nil;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
//    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
//    
//    UILabel *lblView = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 250, 35)];
//    lblView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
//    lblView.backgroundColor = [UIColor clearColor];
//    
//    [headerView addSubview:lblView];
//    
//    return headerView;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 35.0f;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 56;
    }
    
    return 44;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    Sprinkler *sprinkler = tableView.isEditing ? self.remoteSprinklers[indexPath.row] : self.savedSprinklers[indexPath.row];
    if (indexPath.section == 0) {
        Sprinkler *sprinkler = self.savedSprinklers[indexPath.row];
        return (indexPath.section == 0) && (![sprinkler.isLocalDevice boolValue]);
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        BOOL currentSprinklerDeleted = self.savedSprinklers[indexPath.row] == [StorageManager current].currentSprinkler;
        [Utils invalidateLoginForCurrentSprinkler];

        BOOL deleted = [[StorageManager current] deleteSprinkler:self.savedSprinklers[indexPath.row]];
        
        if (currentSprinklerDeleted) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate refreshRootViews:nil];
        } else {
            [self refreshSprinklerList];
            if (deleted) {
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        Sprinkler *sprinkler = self.savedSprinklers[indexPath.row];
        DevicesCellType1 *cell = [self configureSprinklerCellForTableView:tableView indexPath:indexPath sprinkler:sprinkler];
        cell.sprinkler = sprinkler;
        return cell;
    }
    else if (indexPath.section < 1 + self.cloudEmails.count) {
        NSArray *sprinklerArray = self.cloudSprinklers[self.cloudEmails[indexPath.section - 1]];
        Sprinkler *sprinkler = nil;
        if (sprinklerArray.count > 0) {
            sprinkler = sprinklerArray[indexPath.row];
        }
        DevicesCellType1 *cell = [self configureSprinklerCellForTableView:tableView indexPath:indexPath sprinkler:sprinkler];
        cell.sprinkler = sprinkler;
        if (!sprinkler) {
            cell.labelMainSubtitle.text = @"No sprinklers online";
            cell.disclosureImageView.hidden = YES;
        }
        return cell;
    }
    else {
        if (indexPath.row == 0) {
            // Add New Device
            AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
            cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
            [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
            
            [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            
            return cell;
        } else {
            // Add Cloud Account
            AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
            cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
            [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
            
            [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            
            cell.titleLabel.text = @"Add cloud account";
            
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.tableView.isEditing) {
        if ([self tableView:tableView canEditRowAtIndexPath:indexPath]) {
            AddNewDeviceVC *editDeviceVC = [[AddNewDeviceVC alloc] init];
            editDeviceVC.sprinkler = self.savedSprinklers[indexPath.row];
            editDeviceVC.title = @"Edit Device";
            [self.navigationController pushViewController:editDeviceVC animated:YES];
        }
        return;
    }
    
    if (indexPath.section == 0) {
        Sprinkler *sprinkler = self.savedSprinklers[indexPath.row];
        [self sprinklerSelected:sprinkler];
    } else if (indexPath.section < 1 + self.cloudEmails.count) {
        NSArray *sprinklerArray = self.cloudSprinklers[self.cloudEmails[indexPath.section - 1]];
        Sprinkler *sprinkler = nil;
        if (sprinklerArray.count > 0) {
            sprinkler = sprinklerArray[indexPath.row];
            [self sprinklerSelected:sprinkler];
        }
    } else {
        if (indexPath.row == 0) {
            AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
            [self.navigationController pushViewController:addNewDeviceVC animated:YES];
        } else {
            AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
            addNewDeviceVC.cloudUI = YES;
            [self.navigationController pushViewController:addNewDeviceVC animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self shouldStopBroadcast];
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self shouldStartBroadcastForceUIRefresh:NO];
}

- (DevicesCellType1*)configureSprinklerCellForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath sprinkler:(Sprinkler*)sprinkler
{
    DevicesCellType1 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType1" forIndexPath:indexPath];
    cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);

    cell.labelMainTitle.text = sprinkler.name;
    
    // remove https from address
    NSString *adressWithoutPrefix = [sprinkler.address substringWithRange:NSMakeRange(8, [sprinkler.address length] - 8)];
    
    // we don't have to print the default port
    if([sprinkler.port isEqual: @"443"])
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@", adressWithoutPrefix] : sprinkler.address;
    else
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@:%@", adressWithoutPrefix, sprinkler.port] : sprinkler.address;
    
    // TODO: decide upon local/remote type on runtime
    cell.labelInfo.text = @"";
    
    cell.disclosureImageView.hidden = tableView.isEditing || (![sprinkler.isDiscovered boolValue]);
    cell.labelMainSubtitle.enabled = [sprinkler.isDiscovered boolValue];
    cell.labelInfo.hidden = tableView.isEditing;
    
    if (tableView.isEditing && [self tableView:tableView canEditRowAtIndexPath:indexPath]) {
        cell.disclosureImageView.hidden = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    return cell;
}

- (void)sprinklerSelected:(Sprinkler*)sprinkler
{
    [NetworkUtilities restoreCookieForBaseUrl:sprinkler.address port:sprinkler.port];
    int detectedSprinklerMainVersion = 0;
    
    if ([NetworkUtilities isLoginCookieActiveForBaseUrl:sprinkler.address detectedSprinklerMainVersion:&detectedSprinklerMainVersion]) {
        // Automatic login
        [ServerProxy setSprinklerVersionMajor:detectedSprinklerMainVersion
                                        minor:-1
                                     subMinor:-1];
        
        [StorageManager current].currentSprinkler = sprinkler;
        [[StorageManager current] saveData];
        [self done:nil];
    } else {
        LoginVC *login = [[LoginVC alloc] init];
        login.sprinkler = sprinkler;
        
        if ([login.sprinkler.loginRememberMe boolValue] == YES) {
            [Utils clearRememberMeFlagForSprinkler:login.sprinkler];
        }
        
        login.parent = self;
        [self.navigationController pushViewController:login animated:YES];
    }
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self hideHud];
//    NSError *e = nil;
//    NSData *testData = [@"{\"sprinklersByEmail\":[{\"email\":\"me@tremend.ro\",\"sprinklers\":[{\"sprinklerName\":\"sprinkler196\",\"sprinklerId\":\"sprinkler196\",\"sprinklerUrl\":\"54.76.26.90:8443\"}],\"activeCount\":1,\"knownCount\":2,\"authCount\":1}]}" dataUsingEncoding:NSUTF8StringEncoding];
//    self.cloudResponse = [NSJSONSerialization JSONObjectWithData:testData options:NSJSONReadingMutableContainers error:&e];//data;
    
    NSArray *aliveRemoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:@YES];
    for (Sprinkler *sprinkler in aliveRemoteDevices) {
        if (sprinkler.email) {
            // It is a cloud device
            sprinkler.isDiscovered = @NO;
        }
    }
    
    self.cloudResponse = data;
    NSArray *cloudInfos = self.cloudResponse[@"sprinklersByEmail"];
    for (NSDictionary *cloudInfo in cloudInfos) {
        NSString *email = cloudInfo[@"email"];
        for (NSDictionary *sprinklerInfo in cloudInfo[@"sprinklers"]) {
            NSString *fullAddress = [Utils fixedSprinklerAddress:sprinklerInfo[@"sprinklerUrl"] ];
            NSURL *url = [NSURL URLWithString:fullAddress];
            NSString *port = [[url port] stringValue];
            NSString *address = fullAddress;
            if ([port length] > 0) {
                if ([port length] + 1  < [fullAddress length]) {
                    address = [fullAddress substringToIndex:[fullAddress length] - ([port length] + 1)];
                }
            }
            port = port ? port : @"443";
            Sprinkler *sprinkler = [[StorageManager current] getSprinkler:sprinklerInfo[@"sprinklerName"] address:address port:port local:@NO email:email];
            if (!sprinkler) {
                sprinkler = [[StorageManager current] addSprinkler:sprinklerInfo[@"sprinklerName"] ipAddress:address port:port isLocal:@NO email:email save:NO];
            } else {
                if (address) {
                    sprinkler.address = address;
                }
                sprinkler.port = port;
                sprinkler.sprinklerId = sprinklerInfo[@"sprinklerId"];
            }
            
            sprinkler.isDiscovered = @YES;
        }
    }
    
    [[StorageManager current] saveData];
    
    [self refreshSprinklerList];
    
    [self.tableView reloadData];
}

- (void)loggedOut {
}

- (void)loginSucceededAndRemembered:(BOOL)remembered unit:(NSString*)unit {
}

#pragma mark - 

- (void)dealloc
{
    [self shouldStopBroadcast];
}

@end
