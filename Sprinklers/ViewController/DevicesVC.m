//
//  DevicesVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "DevicesVC.h"
#import "DevicesMenuVC.h"
#import "NetworkSettingsVC.h"
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
#import "SetDelayVC.h"
#import "AddNewDeviceVC.h"
#import "AppDelegate.h"
#import "TimePickerVC.h"
#import "ServerProxy.h"
#import "ProvisionLocationSetupVC.h"
#import "ProvisionAvailableWiFisVC.h"
#import "GraphsManager.h"
#import "Login4Response.h"

#define kDebugSettingsNrBeforeCloudServer 6
#define kRequestDiagTimeoutInterval 5

#define kAlertView_DeleteDevice 1001
#define kAlertView_DeleteCloudDevice 1002

@interface DevicesVC () {
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *locallyDiscoveredSprinklers;
@property (strong, nonatomic) NSArray *manuallyEnteredSprinklers;
@property (strong, nonatomic) NSDictionary *cloudResponse;
@property (strong, nonatomic) NSDictionary *cloudSprinklers;
@property (strong, nonatomic) NSMutableArray *cloudSprinklersList;
@property (strong, nonatomic) NSArray *cloudEmails;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ServerProxy *cloudServerProxy;
@property (strong, nonatomic) ServerProxy *diagServerProxy;
@property (strong, nonatomic) ServerProxy *versionServerProxy;
@property (strong, nonatomic) ServerProxy *automaticLoginSprinklerServerProxy;
@property (strong, nonatomic) ServerProxy *requestSettingsDateServerProxy;
@property (strong, nonatomic) NSTimer *networkDevicesTimer;
@property (strong, nonatomic) NSTimer *cloudDevicesTimer;
@property (strong, nonatomic) DevicesMenuVC *devicesMenuVC;
@property (strong, nonatomic) Sprinkler *selectedSprinkler;
@property (assign, nonatomic) BOOL selectingSprinklerInProgress;
@property (strong, nonatomic) ProvisionAvailableWiFisVC *wizardVC;

@property (nonatomic, weak) IBOutlet UITextField *debugTextField;
@property (strong, nonatomic) NSMutableArray *cloudServers;
@property (strong, nonatomic) NSMutableArray *cloudServerNames;
@property (strong, nonatomic) NSMutableArray *cloudEmailValidatorServers;
@property (assign, nonatomic) NSUInteger selectedCloudServerIndex;

@property (assign, nonatomic) BOOL forceUserRefreshActivityIndicator;
@property (assign, nonatomic) int hideHudTimeoutCountDown;

@property (strong, nonatomic) NSDate *startDateResetToDefaults;
@property (strong, nonatomic) Sprinkler *sprinklerResetToDefaults;

@property (strong, nonatomic) Sprinkler *selectedCloudSprinklerToDelete;
@property (strong, nonatomic) NSIndexPath *selectedCloudSprinklerToDeleteIndexPath;

@property (assign, nonatomic) BOOL sprinklerListEmpty;

@end

@implementation DevicesVC

#pragma mark - Init

+ (void)initialize {
    NSDictionary *defaults = @{kCloudProxyFinderURLKey : kCloudProxyFinderStagingURL,
                               kCloudEmailValidatorURLKey : kCloudEmailValidatorStagingURL};
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

    self.hideHudTimeoutCountDown = 0;
    self.sprinklerListEmpty = NO;
    
    [self setDefaultTuningValues];
    
    [self refreshCloudPollingProxy];

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
    
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType1" bundle:nil] forCellReuseIdentifier:@"DevicesCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType2" bundle:nil] forCellReuseIdentifier:@"DevicesCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
    [self createFooter];
    
    [self updateNavigationbarButtons];
}

- (void)refreshCloudPollingProxy
{
    self.cloudServerProxy = [[ServerProxy alloc] initWithServerURL:self.cloudProxyFinderURL delegate:self jsonRequest:YES];
}

- (void)setDefaultTuningValues
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kDebugNewAPIVersion];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDebugLocalDevicesDiscoveryInterval]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:kLocalDevicesDiscoveryInterval] forKey:kDebugLocalDevicesDiscoveryInterval];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDebugCloudDevicesDiscoveryInterval]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:kCloudDevicesDiscoveryInterval] forKey:kDebugCloudDevicesDiscoveryInterval];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:kDeviceGreyOutRetryCount] forKey:kDebugDeviceGreyOutRetryCount];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey]) {
        [[NSUserDefaults standardUserDefaults] setObject:kCloudProxyFinderStagingURL forKey:kCloudProxyFinderURLKey];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kCloudEmailValidatorURLKey]) {
        [[NSUserDefaults standardUserDefaults] setObject:kCloudEmailValidatorStagingURL forKey:kCloudEmailValidatorURLKey];
    }

    self.cloudServers = [NSMutableArray new];
    [self.cloudServers addObject:kCloudProxyFinderStagingURL];
    [self.cloudServers addObject:kCloudProxyFinderURL];
    
    self.cloudServerNames = [NSMutableArray new];
    [self.cloudServerNames addObject:kCloudProxyFinderStagingName];
    [self.cloudServerNames addObject:kCloudProxyFinderName];
    
    self.cloudEmailValidatorServers = [NSMutableArray new];
    [self.cloudEmailValidatorServers addObject:kCloudEmailValidatorStagingURL];
    [self.cloudEmailValidatorServers addObject:kCloudEmailValidatorURL];

    NSString *selectedServer = [[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey];
    selectedServer = [self fixSelectedServer:selectedServer];
    [[NSUserDefaults standardUserDefaults] setObject:selectedServer forKey:kCloudProxyFinderURLKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.selectedCloudServerIndex = [self.cloudServers indexOfObject:selectedServer];
}

- (NSString*)fixSelectedServer:(NSString*)selectedServer
{
    // Workaround done because the port was dropped in the meantime from the server address, so this means that the saved server url might not be valid
    if (([kCloudProxyFinderStagingURL hasPrefix:selectedServer]) || ([selectedServer hasPrefix:kCloudProxyFinderStagingURL])) {
        selectedServer = kCloudProxyFinderStagingURL;
    }
    
    if (([kCloudProxyFinderURL hasPrefix:selectedServer]) || ([selectedServer hasPrefix:kCloudProxyFinderURL])) {
        selectedServer = kCloudProxyFinderURL;
    }

    return selectedServer;
}

- (void)updateNavigationbarButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"devices_menu_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onDisplayDevicesMenu:)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self shouldStopBroadcast];
    
    [self.networkDevicesTimer invalidate];
    self.networkDevicesTimer = nil;

    [self.cloudServerProxy cancelAllOperations];
    [self.cloudDevicesTimer invalidate];
    self.cloudDevicesTimer = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.wizardVC = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [ServerProxy popSprinklerVersion];
    
    if (self.devicesMenuVC) {
        NSMutableSet *deletedSprinklers = [NSMutableSet setWithArray:self.cloudEmails];
        NSMutableSet *secondSet = [NSMutableSet setWithArray:[CloudUtils cloudAccounts].allKeys];
        [deletedSprinklers minusSet:secondSet];
        
        NSMutableDictionary *cloudSprinklersMut = [self.cloudSprinklers mutableCopy];
        NSArray *remoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:nil];
        
        for (NSString *email in deletedSprinklers) {
            // Delete from DB
            for (Sprinkler *sprinkler in remoteDevices) {
                if ([email isEqualToString:sprinkler.email]) {
                    [[StorageManager current] deleteSprinkler:sprinkler];
                }
            }
            
            // Delete from Cloud
            [CloudUtils deleteCloudAccountWithEmail:email];
            [cloudSprinklersMut removeObjectForKey:email];
        }
        
        self.cloudSprinklers = cloudSprinklersMut;
        self.cloudEmails = self.devicesMenuVC.cloudEmails;
        
        BOOL currentSprinklerDeleted = self.devicesMenuVC.currentSprinklerDeleted;
        if ([self.devicesMenuVC.navigationController.topViewController isKindOfClass:[NetworkSettingsVC class]]) {
            NetworkSettingsVC *networkSettingsVC = (NetworkSettingsVC*)self.devicesMenuVC.navigationController.topViewController;
            currentSprinklerDeleted = networkSettingsVC.currentSprinklerDeleted;
        }
        
        if (currentSprinklerDeleted) {
            [Utils invalidateLoginForCurrentSprinkler];
            if (currentSprinklerDeleted) {
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate refreshRootViews:nil selectSettings:NO];
            }
        }
        
        self.devicesMenuVC = nil;
        
        // Poll cloud
        [self pollCloud];
    }
    
    [self refreshSprinklerList];
    [self shouldStartBroadcastForceUIRefresh:NO];
    
    [self.tableView reloadData];
    [self refreshDeviceDiscoveryTimers];
    
    if (self.forceRefreshWhenAppearing) {
        [self onRefresh:nil];
        self.forceRefreshWhenAppearing = NO;
    }
}

- (void)applicationDidEnterInForeground {
    BOOL shouldRefresh = (self.tabBarController.selectedViewController == self.navigationController || !self.tabBarController);
    if (!shouldRefresh) return;
    [self onRefresh:nil];
}

#pragma mark - Methods

- (void)refreshDeviceDiscoveryTimers
{
    [self.networkDevicesTimer invalidate];
    [self.cloudDevicesTimer invalidate];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollLocal) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollCloud) object:nil];
    
    self.networkDevicesTimer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugLocalDevicesDiscoveryInterval] intValue]
                                                                target:self
                                                              selector:@selector(pollLocal)
                                                              userInfo:nil
                                                               repeats:YES];
    
    self.cloudDevicesTimer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugCloudDevicesDiscoveryInterval] intValue]
                                                              target:self
                                                            selector:@selector(pollCloud)
                                                            userInfo:nil
                                                             repeats:YES];
    
    [self performSelector:@selector(pollLocal) withObject:nil afterDelay:2.0];
    [self performSelector:@selector(pollCloud) withObject:nil afterDelay:2.0];
}

- (void)refreshSprinklerList
{
    NSArray *sprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_All aliveDevices:nil];
    
    // Sort sprinklers into:
    // 1) manuallyEnteredSprinklers
    // 2) locallyDiscoveredSprinklers
    // 3) cloudSprinklers dictionary
    NSMutableArray *manuallyEnteredSprinklers = [NSMutableArray array];
    NSMutableArray *locallyDiscoveredSprinklers = [NSMutableArray array];
    NSMutableDictionary *cloudSprinklersDic = [NSMutableDictionary dictionary];
    for (Sprinkler *sprinkler in sprinklers) {
        // Force failed discoveries count to 0 for manually added devices
        if ([Utils isManuallyAddedDevice:sprinkler]) {
            sprinkler.nrOfFailedConsecutiveDiscoveries = @0;
        }
        if ([Utils isDeviceInactive:sprinkler]) continue;
        if ([Utils isCloudDevice:sprinkler]) {
            if (!cloudSprinklersDic[sprinkler.email]) {
                cloudSprinklersDic[sprinkler.email] = [NSMutableArray array];
            }
            [cloudSprinklersDic[sprinkler.email] addObject:sprinkler];
        } else {
            if ([Utils isManuallyAddedDevice:sprinkler]) {
                [manuallyEnteredSprinklers addObject:sprinkler];
            } else if (![Utils localDiscoveryDisabled]){
                [locallyDiscoveredSprinklers addObject:sprinkler];
            }
        }
    }
    
    NSMutableArray *duplicateCloudSprinklers = [NSMutableArray array];
    // Filter out the duplicate sprinklers based on mac: priority have the local ones
    for (NSMutableArray *emailBasedCloudSprinklers in [cloudSprinklersDic allValues]) {
        for (Sprinkler *cloudSprinkler in emailBasedCloudSprinklers) {
            for (Sprinkler *localSprinkler in locallyDiscoveredSprinklers) {
                if ([localSprinkler.mac.lowercaseString isEqualToString:cloudSprinkler.mac.lowercaseString]) {
                    [duplicateCloudSprinklers addObject:cloudSprinkler];
                    break;
                }
            }
        } 
    }
    
    for (Sprinkler *cloudSprinkler in duplicateCloudSprinklers) {
        NSMutableArray *cloudSprinklers = [cloudSprinklersDic[cloudSprinkler.email] mutableCopy];
        [cloudSprinklers removeObject:cloudSprinkler];
        if (cloudSprinklers.count) cloudSprinklersDic[cloudSprinkler.email] = cloudSprinklers;
        else [cloudSprinklersDic removeObjectForKey:cloudSprinkler.email];
    }
    
    self.cloudSprinklersList = [NSMutableArray array];
    for (NSArray *sprinklerArray in [cloudSprinklersDic allValues]) {
        [self.cloudSprinklersList addObjectsFromArray:sprinklerArray];
    }

    self.manuallyEnteredSprinklers = manuallyEnteredSprinklers;
    self.locallyDiscoveredSprinklers = locallyDiscoveredSprinklers;
    self.cloudSprinklers = cloudSprinklersDic;
    
    self.sprinklerListEmpty = (self.manuallyEnteredSprinklers.count + self.locallyDiscoveredSprinklers.count + self.cloudSprinklersList.count == 0);
}

- (void)pollLocal {
    [self shouldStartBroadcastForceUIRefresh:YES];
}

- (void)shouldStartBroadcastForceUIRefresh:(BOOL)forceUIRefresh {
    if (forceUIRefresh) {
        // Process the list of discovered devices before starting a new discovery process
        // We do the processing until here, because otherwise, when no sprinklers in the network, the 'SprinklersDiscovered' callback is not called at all
        [self SprinklersDiscovered];
    }

    [self startBroadcastSilent:YES];
}

- (void)SprinklersDiscovered {
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Local onlySprinklersWithEmail:NO];
    NSArray *discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:nil];
    
    // Mark all non-discovered sprinklers as not-alive
    NSArray *localSprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Local aliveDevices:@YES];
    for (Sprinkler *sprinkler in localSprinklers) {
        sprinkler.isDiscovered = @NO;
//        sprinkler.apFlag = nil;
    }
    
    // Convert the DiscoveredSprinkler objects into Sprinkler objects
    // Update all discovered ones or add them as new sprinklers
    for (int i = 0; i < [discoveredSprinklers count]; i++) {
        DiscoveredSprinklers *discoveredSprinkler = discoveredSprinklers[i];
        NSString *port = [NSString stringWithFormat:@"%d", discoveredSprinkler.port];
        NSString *address = [Utils addressWithoutPrefix:[Utils getBaseUrl:discoveredSprinkler.host]];
        Sprinkler *sprinkler = [[StorageManager current] getSprinkler:discoveredSprinkler.sprinklerId name:discoveredSprinkler.sprinklerName address:address local:@YES email:nil];
        if (!sprinkler) {
            sprinkler = [[StorageManager current] addSprinkler:discoveredSprinkler.sprinklerName ipAddress:address port:port isLocal:@YES email:nil mac:discoveredSprinkler.sprinklerId save:NO];
        }
        sprinkler.address = [Utils fixedSprinklerAddress:discoveredSprinkler.host];
        sprinkler.port = port;
        sprinkler.name = discoveredSprinkler.sprinklerName;
        sprinkler.sprinklerId = discoveredSprinkler.sprinklerId;
        sprinkler.mac = discoveredSprinkler.sprinklerId;  // Update the mac for existing sprinklers too
        sprinkler.isDiscovered = @YES;
        sprinkler.nrOfFailedConsecutiveDiscoveries = @0;
        
        sprinkler.apFlag = discoveredSprinkler.apFlag ? @([discoveredSprinkler.apFlag boolValue]) : nil;
    }
    
    [[StorageManager current] saveData];
    
    [self refreshSprinklerList];
    
    [_tableView reloadData];
    
    self.forceUserRefreshActivityIndicator = NO;
    
    [self hideHud];
}

- (void)startBroadcastSilent:(BOOL)silent {
    if (![Utils localDiscoveryDisabled]) {
        [[ServiceManager current] startBroadcastForSprinklers:silent];
    }
}

- (void)shouldStopBroadcast {
    [[ServiceManager current] stopBroadcast];
}

- (void)appDidBecomeActive {
//    [self shouldStartBroadcastForceUIRefresh:NO];
}

- (void)appDidResignActive {
    [self shouldStopBroadcast];
}

#pragma mark - UI

- (void)updateTitle {
    self.title = @"Devices";
}

- (void)createFooter {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    label.text = [NSString stringWithFormat:@"Version: %@", version];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = label;
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)hideHud {
    if ([self isDuringAutomaticSprinklerLogin]) {
        return;
    }
    
    if ([self isDuringLoginVerification]) {
        return;
    }
    
    if ([self isDuringResetToDefaults]) {
        return;
    }
    
    if (self.hideHudTimeoutCountDown > 0) {
        self.hideHudTimeoutCountDown--;
        return;
    }
    
    if (!self.selectingSprinklerInProgress) {
        if (!self.forceUserRefreshActivityIndicator) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.hud = nil;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Reset to Defaults

- (BOOL)isDuringResetToDefaults
{
    if (!self.startDateResetToDefaults) {
        return NO;
    }
    
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.startDateResetToDefaults];
    return (t <= kTimeout_ResetToDefaults);
}

- (BOOL)isDuringAutomaticSprinklerLogin {
    return (self.automaticLoginSprinklerServerProxy != nil);
}

- (BOOL)isDuringLoginVerification {
    return (self.requestSettingsDateServerProxy != nil);
}

- (void)setResetToDefaultsModeWithSprinkler:(Sprinkler*)sprinkler
{
//    self.startDateResetToDefaults = [NSDate date];
//    self.sprinklerResetToDefaults = sprinkler;
//    [self startHud:[NSString stringWithFormat:@"Resetting \"%@\"", sprinkler.name]];
//
//    [NSTimer scheduledTimerWithTimeInterval:kTimeout_ResetToDefaults
//                                                                target:self
//                                   selector:@selector(resetToDefaults:)
//                                                              userInfo:nil
//                                                               repeats:NO];
}

- (void)resetToDefaults:(id)notif
{
    [self hideHud];

    if ((self.sprinklerResetToDefaults)) {// && (![Utils isDeviceInactive:self.sprinklerResetToDefaults])) {
        LoginVC *login = [[LoginVC alloc] init];
        login.sprinkler = self.sprinklerResetToDefaults;
        login.automaticLoginInfo = @{@"password" : @"", @"username" : @"admin"};
        login.parent = self;
        [self.navigationController pushViewController:login animated:NO];
    }
    
    self.sprinklerResetToDefaults = nil;
    self.startDateResetToDefaults = nil;
}

#pragma mark - Cloud Sprinklers

- (void)pollCloud {
    NSDictionary *cloudAccounts = [CloudUtils cloudAccounts];
    self.cloudEmails = [cloudAccounts allKeys];
    
    [self requestCloudSprinklers:cloudAccounts];
}

- (NSString*)cloudProxyFinderURL {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey];
}

- (void)requestCloudSprinklers:(NSDictionary*)cloudAccounts
{
    if (cloudAccounts.count > 0) {
        [self.cloudServerProxy requestCloudSprinklers:cloudAccounts phoneID:[Utils phoneID]];
    } else {
        [self updateCloudSprinklersFromCloudResponse:nil];
    }
}

- (void)updateCloudSprinklersFromCloudResponse:(NSDictionary*)cloudResponse {
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:YES];
    // Mark all cloud devices is a cloud device as not alive
    NSArray *aliveRemoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:@YES];
    for (Sprinkler *sprinkler in aliveRemoteDevices) {
        if ([Utils isCloudDevice:sprinkler]) {
            sprinkler.isDiscovered = @NO;
        }
    }
    
    self.cloudResponse = cloudResponse;
    NSArray *cloudInfos = self.cloudResponse[@"sprinklersByEmail"];
    for (NSDictionary *cloudInfo in cloudInfos) {
        NSString *email = cloudInfo[@"email"];
        for (NSDictionary *sprinklerInfo in cloudInfo[@"sprinklers"]) {
            NSString *fullAddress = [Utils fixedSprinklerAddress:sprinklerInfo[@"sprinklerUrl"] ];
            NSString *port = [Utils getPort:fullAddress];
            NSString *address = [Utils addressWithoutPrefix:[Utils getBaseUrl:fullAddress]];
            port = port ? port : @"443";
            
            // Add or update the remote sprinkler
            
            Sprinkler *sprinkler = [[StorageManager current] getSprinkler:sprinklerInfo[@"mac"] name:sprinklerInfo[@"name"] address:address local:@NO email:email];
            if (!sprinkler) {
                sprinkler = [[StorageManager current] addSprinkler:sprinklerInfo[@"name"] ipAddress:address port:port isLocal:@NO email:email mac:sprinklerInfo[@"mac"] save:NO];
            }
            if (address) sprinkler.address = address;
            sprinkler.name = sprinklerInfo[@"name"];
            sprinkler.port = port;
            sprinkler.sprinklerId = sprinklerInfo[@"sprinklerId"];
            sprinkler.mac = sprinklerInfo[@"mac"]; // Update the mac for existing sprinklers too
            sprinkler.nrOfFailedConsecutiveDiscoveries = @0;
        }
    }
    
    [[StorageManager current] saveData];
    
    [self refreshSprinklerList];
    
    [self.tableView reloadData];
}

- (void)deleteCloudSprinkler:(Sprinkler*)cloudSprinkler {
    NSString *cloudEmail = [cloudSprinkler.email copy];
    if (!cloudEmail.length) return;
    
    [CloudUtils deleteCloudAccountWithEmail:cloudEmail];
    
    NSMutableArray *cloudEmails = [self.cloudEmails mutableCopy];
    [cloudEmails removeObject:cloudEmail];
    self.cloudEmails = cloudEmails;
    
    NSArray *remoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:nil];
    for (Sprinkler *sprinkler in remoteDevices) {
        if ([cloudEmail isEqualToString:sprinkler.email]) {
            [[StorageManager current] deleteSprinkler:sprinkler];
        }
    }
    
    NSMutableDictionary *cloudSprinklers = [self.cloudSprinklers mutableCopy];
    [cloudSprinklers removeObjectForKey:cloudEmail];
    self.cloudSprinklers = cloudSprinklers;
    
    [self refreshSprinklerList];
    [self shouldStartBroadcastForceUIRefresh:NO];
    
    [self.tableView reloadData];
    
    [self.cloudServerProxy cancelAllOperations];
    [self refreshCloudPollingProxy];
    [self refreshDeviceDiscoveryTimers];
}

#pragma mark - Actions

- (void)done
{
    [self done:nil];
}

- (void)done:(NSString*)unit {
    [[GraphsManager sharedGraphsManager] reregisterAllGraphsReload:YES];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate refreshRootViews:unit selectSettings:NO];
}

- (void)onRefresh:(id)notification {
    
    if (self.forceUserRefreshActivityIndicator) {
        return;
    }
    
    self.forceUserRefreshActivityIndicator = YES;
    
    if ([self isDuringResetToDefaults]) {
        return;
    }
    
    self.locallyDiscoveredSprinklers = [NSArray array];
    self.cloudSprinklersList = [NSMutableArray array];
    self.manuallyEnteredSprinklers = [NSArray array];
    
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Local onlySprinklersWithEmail:NO];
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:NO];
    NSArray *allSprinklers = [[StorageManager current] getAllSprinklersFromNetwork];
    for (Sprinkler *sprinkler in allSprinklers) {
        if ([Utils isManuallyAddedDevice:sprinkler]) continue;
        // Force Sprinklers to disappear from the list at manual refresh
        sprinkler.nrOfFailedConsecutiveDiscoveries = @([Utils deviceGreyOutRetryCount]);
        sprinkler.isDiscovered = @NO;
    }
    
    [[StorageManager current] saveData];

//    [self shouldStartBroadcastForceUIRefresh:NO];
    self.cloudResponse = nil;
    self.cloudEmails = nil;
    self.locallyDiscoveredSprinklers = nil;
    self.manuallyEnteredSprinklers = nil;
    self.cloudSprinklers = nil;
    
    [self pollCloud];

    [self startHud:nil];
    [self.tableView reloadData];
}

- (void)onDisplayDevicesMenu:(id)sender {
    self.devicesMenuVC = [[DevicesMenuVC alloc] init];
    self.devicesMenuVC.cloudResponse = self.cloudResponse;
    self.devicesMenuVC.cloudSprinklers = self.cloudSprinklers;
    self.devicesMenuVC.cloudEmails = [self.cloudEmails mutableCopy];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.devicesMenuVC];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)deviceSetupFinished
{
    self.hideHudTimeoutCountDown = 2;
//    [self shouldStartBroadcastForceUIRefresh:YES];
    [self startHud:nil];
}

#pragma mark - UITableView delegate

- (NSInteger)tvSectionDevices {
    return 0;
}

- (NSInteger)tvSectionDebugSettings {
    if (![Utils localDiscoveryDisabled]) return 1;
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return  1 + (ENABLE_DEBUG_SETTINGS ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self tvSectionDevices]) {
        if (self.sprinklerListEmpty && !self.hud) return 1;
        return self.locallyDiscoveredSprinklers.count + self.cloudSprinklersList.count + self.manuallyEnteredSprinklers.count;
    }
    
    if (section == [self tvSectionDebugSettings]) {
        return kDebugSettingsNrBeforeCloudServer + self.cloudServers.count;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == [self tvSectionDebugSettings]) {
        return @"SETTINGS (DEBUG)";
    }
        
    return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == [self tvSectionDevices] && self.sprinklerListEmpty && !self.hud) return 64.0;
    return 44;
}

- (Sprinkler*)sprinklerToShowForIndexPath:(NSIndexPath*)indexPath {
    Sprinkler *sprinkler = nil;
    
    if (indexPath.section == [self tvSectionDevices]) {
        if (self.sprinklerListEmpty && !self.hud) return nil;
        if (indexPath.row < self.locallyDiscoveredSprinklers.count) {
            sprinkler = self.locallyDiscoveredSprinklers[indexPath.row];
        } else if (indexPath.row < self.locallyDiscoveredSprinklers.count + self.cloudSprinklersList.count) {
            sprinkler = self.cloudSprinklersList[indexPath.row - self.locallyDiscoveredSprinklers.count];
        } else {
            sprinkler = self.manuallyEnteredSprinklers[indexPath.row - self.locallyDiscoveredSprinklers.count - self.cloudSprinklersList.count];
        }
    }
    
    return sprinkler;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == [self tvSectionDevices]) {
        if (self.sprinklerListEmpty && !self.hud) {
            static NSString *EmptySprinklersListCellIdentifier = @"EmptySprinklersListCellIdentifier";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:EmptySprinklersListCellIdentifier];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmptySprinklersListCellIdentifier];
            
            cell.textLabel.text = @"No RainMachines found";
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        } else {
            Sprinkler *sprinkler = [self sprinklerToShowForIndexPath:indexPath];
            DevicesCellType1 *cell = [Utils configureSprinklerCellForTableView:tableView indexPath:indexPath sprinkler:sprinkler canEditRow:NO forceHiddenDisclosure:NO];
            cell.sprinkler = sprinkler;
            return cell;
        }
    }
    else if (indexPath.section == [self tvSectionDebugSettings]) {
        UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Debug"];
        }
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            cell.tintColor = [UIColor colorWithRed:(0.0/255.0) green:(122.0/255.0) blue:(255.0/255.0) alpha:1.0];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.detailTextLabel.text = @"";
        if (indexPath.row == 0) {
            NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
            NSString *build = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
            cell.textLabel.text = @"App Version (Build)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)",version,build];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"Location";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else if (indexPath.row == 2) {
            cell.textLabel.text = @"Use New API Version";
            cell.detailTextLabel.text = nil;
            cell.accessoryType = ([[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            NSLog(@"cellFor:%@", [[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion]);
        }
        else if (indexPath.row == 3) {
            cell.textLabel.text = @"Local Devices Discovery Interval";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kDebugLocalDevicesDiscoveryInterval]];
        }
        else if (indexPath.row == 4) {
            cell.textLabel.text = @"Cloud Devices Discovery Interval";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kDebugCloudDevicesDiscoveryInterval]];
        }
        else if (indexPath.row == 5) {
            cell.textLabel.text = @"Device Grey Out Retry Count";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount]];
        } else {
            cell.textLabel.text = self.cloudServerNames[indexPath.row - kDebugSettingsNrBeforeCloudServer];
            cell.accessoryType = ((indexPath.row - kDebugSettingsNrBeforeCloudServer) == self.selectedCloudServerIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == [self tvSectionDevices]) {
        if (self.sprinklerListEmpty && !self.hud) return;
        
        DevicesCellType1 *selectedCell = (DevicesCellType1*)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
        if (!selectedCell.disclosureImageView.hidden) {
            Sprinkler *sprinkler = [self sprinklerToShowForIndexPath:indexPath];
            [self sprinklerSelected:sprinkler];
        }
    } else if (indexPath.section == [self tvSectionDebugSettings]) {
        if (indexPath.row == 0) {
            // Do nothing
        }
        else if (indexPath.row == 1) {
            ProvisionLocationSetupVC *locationSetupVC = [[ProvisionLocationSetupVC alloc] init];
            [self.navigationController pushViewController:locationSetupVC animated:YES];
        }
        else if (indexPath.row == 2) {
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
            BOOL prevValue = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:!prevValue] forKey:kDebugNewAPIVersion];
            [[NSUserDefaults standardUserDefaults] synchronize];
            selectedCell.accessoryType = (prevValue == NO) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
        } else {
            if (indexPath.row >= kDebugSettingsNrBeforeCloudServer) {
                NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:(self.selectedCloudServerIndex + kDebugSettingsNrBeforeCloudServer) inSection:indexPath.section];
                UITableViewCell *oldSelectedCell = [tableView cellForRowAtIndexPath:oldIndexPath];
                self.selectedCloudServerIndex = indexPath.row - kDebugSettingsNrBeforeCloudServer;
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:(self.selectedCloudServerIndex + kDebugSettingsNrBeforeCloudServer) inSection:indexPath.section];
                UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:newIndexPath];
                
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                [[NSUserDefaults standardUserDefaults] setObject:self.cloudServers[self.selectedCloudServerIndex] forKey:kCloudProxyFinderURLKey];
                [[NSUserDefaults standardUserDefaults] setObject:self.cloudEmailValidatorServers[self.selectedCloudServerIndex] forKey:kCloudEmailValidatorURLKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (oldIndexPath != newIndexPath) {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:oldIndexPath, newIndexPath, nil] withRowAnimation:NO];
                } else {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:oldIndexPath, nil] withRowAnimation:NO];
                }

                [self refreshCloudPollingProxy];
                [self pollCloud];
            } else {
                self.navigationController.view.userInteractionEnabled = NO;
                
                TRPickerInputView *intervalPickerInputView = [TRPickerInputView newPickerInputView];
                
                if (indexPath.row == 3) {
                    intervalPickerInputView.identifier = kDebugLocalDevicesDiscoveryInterval;
                }
                if (indexPath.row == 4) {
                    intervalPickerInputView.identifier = kDebugCloudDevicesDiscoveryInterval;
                }
                if (indexPath.row == 5) {
                    intervalPickerInputView.identifier = kDebugDeviceGreyOutRetryCount;
                }
                
                NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:intervalPickerInputView.identifier];
                intervalPickerInputView.dataSource = self;
                intervalPickerInputView.delegate = self;
                
                self.debugTextField.inputView = intervalPickerInputView;
                
                [intervalPickerInputView selectRow:[value intValue] animated:NO];
                [self.debugTextField becomeFirstResponder];
            }
        }
    }
}

- (void)sprinklerSelected:(Sprinkler*)sprinkler {
    [self.versionServerProxy cancelAllOperations];
    [self.diagServerProxy cancelAllOperations];
    
    self.versionServerProxy = nil;
    self.diagServerProxy = nil;
    
    self.selectedSprinkler = sprinkler;
    self.selectingSprinklerInProgress = YES;
    
    [self startHud:nil];
    self.versionServerProxy = [[ServerProxy alloc] initWithSprinkler:sprinkler delegate:self jsonRequest:NO];
    [self.versionServerProxy requestAPIVersionWithTimeoutInterval:kRequestDiagTimeoutInterval];
}

- (void)presentWizardWithSprinkler:(Sprinkler*)sprinkler
{
    self.wizardVC = [[ProvisionAvailableWiFisVC alloc] init];
    self.wizardVC.inputSprinklerMAC = sprinkler.sprinklerId;
    self.wizardVC.isPartOfWizard = YES;

    [self.navigationController pushViewController:self.wizardVC animated:YES];
//    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:self.wizardVC];
//    [self.navigationController presentViewController:navDevices animated:YES completion:nil];
}

- (void)continueSprinklerSelectionAction:(Sprinkler*)sprinkler diag:(NSDictionary*)diag
{
    BOOL wizardHasRun = [diag[@"wizardHasRun"] boolValue];

    if (diag && !wizardHasRun) {
        [self presentWizardWithSprinkler:sprinkler];
    } else {
        BOOL isAutomaticLogin = NO;
        int detectedSprinklerMainVersion = 0;
        
        NSString *accessToken = [NetworkUtilities accessTokenForBaseUrl:sprinkler.address port:sprinkler.port];
        if (accessToken.length) {
            isAutomaticLogin = YES;
            detectedSprinklerMainVersion = 4; // Automatic login - API 4
            
            // Remove old cookies as API 4 uses access token
            [NetworkUtilities removeCookiesForURL:[NSURL URLWithString:[Utils sprinklerURL:sprinkler]]];
        }
        
        if (!isAutomaticLogin) {
            [NetworkUtilities restoreCookieForBaseUrl:sprinkler.address port:sprinkler.port];
            if ([NetworkUtilities isLoginCookieActiveForBaseUrl:sprinkler.address]) {
                isAutomaticLogin = YES;
                detectedSprinklerMainVersion = 3; // Automatic login - API 3
            }
        }
        
        if (isAutomaticLogin) {
            [ServerProxy setSprinklerVersionMajor:detectedSprinklerMainVersion
                                            minor:-1
                                         subMinor:-1];
            
            // Try to make a request to verify if the cookie or the token is still valid
            self.requestSettingsDateServerProxy = [[ServerProxy alloc] initWithSprinkler:sprinkler delegate:self jsonRequest:NO];
            [self.requestSettingsDateServerProxy requestSettingsDate];
            [self startHud:nil];
        } else {
            [self continueWithNonAutomaticLoginForSprinkler:sprinkler diag:diag];
        }
    }
}

- (void)continueWithNonAutomaticLoginForSprinkler:(Sprinkler*)sprinkler diag:(NSDictionary*)diag {
    if ([Utils isCloudDevice:sprinkler]) {
        [ServerProxy setSprinklerVersionMajor:4 minor:-1 subMinor:-1];
        
        NSString *password = [CloudUtils passwordForCloudAccountWithEmail:sprinkler.email];
        self.automaticLoginSprinklerServerProxy = [[ServerProxy alloc] initWithSprinkler:sprinkler delegate:self jsonRequest:YES];
        [self.automaticLoginSprinklerServerProxy loginWithUserName:sprinkler.email password:password rememberMe:YES];
        
        [self startHud:nil];
    } else if ([Utils isConnectedToRainmachineDevice:sprinkler]) {
        [ServerProxy setSprinklerVersionMajor:4 minor:-1 subMinor:-1];
        
        NSString *password = @"";
        self.automaticLoginSprinklerServerProxy = [[ServerProxy alloc] initWithSprinkler:sprinkler delegate:self jsonRequest:YES];
        [self.automaticLoginSprinklerServerProxy loginWithUserName:nil password:password rememberMe:YES];
        
        [self startHud:nil];
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

- (void)continueWithAutomaticLoginForSprinkler:(Sprinkler*)sprinkler {
    [StorageManager current].currentSprinkler = sprinkler;
    [[StorageManager current] saveData];
    [self done:nil];
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.cloudServerProxy) {
        [self hideHud];
        [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:YES];
    }
    else if (serverProxy == self.diagServerProxy) {
        self.selectingSprinklerInProgress = NO;
        [self hideHud];
        
        BOOL timeout = ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorTimedOut);
        if (timeout) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Timeout" message:@"The sprinkler doesn't respond." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else {
            [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
        }
        
        self.diagServerProxy = nil;
    }
    else if (serverProxy == self.versionServerProxy) {
        self.selectingSprinklerInProgress = NO;
        [self hideHud];

        BOOL timeout = ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorTimedOut);
        if (timeout) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Timeout" message:@"The sprinkler doesn't respond." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else {
            [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
        }
        
        self.versionServerProxy = nil;
    }
    else if (serverProxy == self.requestSettingsDateServerProxy) {
        self.requestSettingsDateServerProxy = nil;
        [self hideHud];
        [self continueWithNonAutomaticLoginForSprinkler:self.selectedSprinkler diag:nil];
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.cloudServerProxy) {
        [self hideHud];
        [self updateCloudSprinklersFromCloudResponse:data];
    }
    else if (serverProxy == self.versionServerProxy) {
        self.versionServerProxy = nil;
        
        NSArray *versionComponents = [Utils parseApiVersion:data];
        NSInteger versionComponentMajor = -1;
        if (versionComponents.count) versionComponentMajor = [[versionComponents firstObject] integerValue];
        
        if (versionComponentMajor == 3) {
            self.selectingSprinklerInProgress = NO;
            [self hideHud];
            [self continueSprinklerSelectionAction:self.selectedSprinkler diag:nil];
        } else {
            self.diagServerProxy = [[ServerProxy alloc] initWithSprinkler:self.selectedSprinkler delegate:self jsonRequest:NO];
            [self.diagServerProxy requestDiagWithTimeoutInterval:kRequestDiagTimeoutInterval];
        }
    }
    else if (serverProxy == self.diagServerProxy) {
        self.selectingSprinklerInProgress = NO;
        [self hideHud];
        
        self.diagServerProxy = nil;
        [self continueSprinklerSelectionAction:self.selectedSprinkler diag:(NSDictionary*)data];
    }
    else if (serverProxy == self.requestSettingsDateServerProxy) {
        self.requestSettingsDateServerProxy = nil;
        [self hideHud];
        [self continueWithAutomaticLoginForSprinkler:self.selectedSprinkler];
    }
}

- (void)loggedOut {
    if ([self isDuringLoginVerification]) {
        self.requestSettingsDateServerProxy = nil;
        [self hideHud];
        [self continueWithNonAutomaticLoginForSprinkler:self.selectedSprinkler diag:nil];
    }
    else if ([self isDuringAutomaticSprinklerLogin]) {
        LoginVC *login = [[LoginVC alloc] init];
        login.sprinkler = self.selectedSprinkler;
        
        [Utils clearRememberMeFlagForSprinkler:login.sprinkler];
        
        login.parent = self;
        [self.navigationController pushViewController:login animated:YES];
        
        self.automaticLoginSprinklerServerProxy = nil;
        
        [self hideHud];
    }
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit {
    if ([self isDuringAutomaticSprinklerLogin]) {
        if ([loginResponse isKindOfClass:[Login4Response class]]) {
            [NetworkUtilities saveAccessTokenForBaseURL:self.selectedSprinkler.address port:self.selectedSprinkler.port loginResponse:(Login4Response*)loginResponse];
        
            self.selectedSprinkler.loginRememberMe = [NSNumber numberWithBool:remembered];
            self.selectedSprinkler.username = self.selectedSprinkler.email;
            [StorageManager current].currentSprinkler = self.selectedSprinkler;
            [[StorageManager current] saveData];
            
            [self hideHud];
        
            [self done:unit];
        
            self.automaticLoginSprinklerServerProxy = nil;
        
            [self hideHud];
        } else {
            [self loggedOut];
        }
    }
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertView_DeleteCloudDevice) {
        [self.tableView reloadRowsAtIndexPaths:@[self.selectedCloudSprinklerToDeleteIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self deleteCloudSprinkler:self.selectedCloudSprinklerToDelete];
        }
        
        self.selectedCloudSprinklerToDelete = nil;
        self.selectedCloudSprinklerToDeleteIndexPath = nil;
    }
}

#pragma mark - Picker input view data source

- (NSInteger)numberOfRowsInPickerView:(TRPickerInputView*)pickerInputView {
    return 121;
}

#pragma mark - Picker input view delegate

- (void)pickerView:(TRPickerInputView*)pickerInputView didSelectRow:(NSInteger)row {
    [self.debugTextField resignFirstResponder];
    self.navigationController.view.userInteractionEnabled = YES;

    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:row] forKey:pickerInputView.identifier];
    
    [self refreshDeviceDiscoveryTimers];

    [self.tableView reloadData];
}

- (void)pickerViewDidCancel:(TRPickerInputView*)pickerInputView {
    [self.debugTextField resignFirstResponder];
    self.navigationController.view.userInteractionEnabled = YES;
}

- (NSString*)pickerView:(TRPickerInputView*)pickerInputView titleForRow:(NSInteger)row {
    return [NSString stringWithFormat:@"%d", (int)row];
}

#pragma mark - 

- (void)dealloc
{
    [self shouldStopBroadcast];
}

@end
