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
#import "LocationSetupVC.h"
#import "CloudAccountsVC.h"
#import "AvailableWiFisVC.h"
#import "GraphsManager.h"

#define kDebugSettingsNrBeforeCloudServer 6

#define kAlertView_DeleteDevice 1

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
@property (strong, nonatomic) NSTimer *networkDevicesTimer;
@property (strong, nonatomic) NSTimer *cloudDevicesTimer;
@property (strong, nonatomic) CloudAccountsVC *cloudAccountsVC;
@property (strong, nonatomic) Sprinkler *selectedSprinkler;

@property (nonatomic, weak) IBOutlet UITextField *debugTextField;
@property (strong, nonatomic) NSMutableArray *cloudServers;
@property (strong, nonatomic) NSMutableArray *cloudServerNames;
@property (assign, nonatomic) NSUInteger selectedCloudServerIndex;

@end

@implementation DevicesVC

#pragma mark - Init

+ (void)initialize {
    NSDictionary *defaults = @{kCloudProxyFinderURLKey : kCloudProxyFinderStagingURL};
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
    
    _tableView.allowsSelectionDuringEditing = YES;
    
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
        [[NSUserDefaults standardUserDefaults] setObject:kCloudProxyFinderURL forKey:kCloudProxyFinderURLKey];
    }

    self.cloudServers = [NSMutableArray new];
    [self.cloudServers addObject:kCloudProxyFinderStagingURL];
    [self.cloudServers addObject:kCloudProxyFinderURL];
    
    self.cloudServerNames = [NSMutableArray new];
    [self.cloudServerNames addObject:kCloudProxyFinderStagingName];
    [self.cloudServerNames addObject:kCloudProxyFinderName];

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

    [self.cloudServerProxy cancelAllOperations];
    [self.cloudDevicesTimer invalidate];
    self.cloudDevicesTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [ServerProxy popSprinklerVersion];
    
    if (self.cloudAccountsVC) {
        NSMutableSet *deletedSprinklers = [NSMutableSet setWithArray:self.cloudEmails];
        NSMutableSet *secondSet = [NSMutableSet setWithArray:self.cloudAccountsVC.cloudEmails];
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
        self.cloudEmails = self.cloudAccountsVC.cloudEmails;
        self.cloudAccountsVC = nil;
    }
    
    if (!self.tableView.isEditing) {
        [self refreshSprinklerList];
        [self shouldStartBroadcastForceUIRefresh:NO];
        
        [self pollCloud];
    }
    
    [self.tableView reloadData];

    [self refreshDeviceDiscoveryTimers];
}

#pragma mark - Methods

- (void)refreshDeviceDiscoveryTimers
{
    [self.networkDevicesTimer invalidate];
    [self.cloudDevicesTimer invalidate];
    
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
    
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(pollLocal) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(pollCloud) userInfo:nil repeats:NO];
}

- (void)pollCloud
{
    NSDictionary *cloudAccounts = [CloudUtils cloudAccounts];
    self.cloudEmails = [cloudAccounts allKeys];
    
    [self requestCloudSprinklers:cloudAccounts];
}

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
        [self.cloudServerProxy requestCloudSprinklers:cloudAccounts];
    }
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
        if ([Utils isCloudDevice:sprinkler]) {
            if (!cloudSprinklersDic[sprinkler.email]) {
                cloudSprinklersDic[sprinkler.email] = [NSMutableArray array];
            }
            [cloudSprinklersDic[sprinkler.email] addObject:sprinkler];
        } else {
            if ([Utils isManuallyAddedDevice:sprinkler]) {
                [manuallyEnteredSprinklers addObject:sprinkler];
            } else {
                [locallyDiscoveredSprinklers addObject:sprinkler];
            }
        }
    }
    
    NSMutableArray *duplicateCloudSprinklers = [NSMutableArray array];
    // Filter out the duplicate sprinklers based on mac: priority have the local ones
    for (NSMutableArray *emailBasedCloudSprinklers in [cloudSprinklersDic allValues]) {
        for (Sprinkler *cloudSprinkler in emailBasedCloudSprinklers) {
            for (Sprinkler *localSprinkler in locallyDiscoveredSprinklers) {
                if ([localSprinkler.mac isEqualToString:cloudSprinkler.mac]) {
                    [duplicateCloudSprinklers addObject:cloudSprinkler];
                    break;
                }
            }
        } 
    }
    
    for (Sprinkler *cloudSprinkler in duplicateCloudSprinklers) {
        [cloudSprinklersDic removeObjectForKey:cloudSprinkler.email];
    }
    
    self.cloudSprinklersList = [NSMutableArray array];
    for (NSArray *sprinklerArray in [cloudSprinklersDic allValues]) {
        [self.cloudSprinklersList addObjectsFromArray:sprinklerArray];
    }

    self.manuallyEnteredSprinklers = manuallyEnteredSprinklers;
    self.locallyDiscoveredSprinklers = locallyDiscoveredSprinklers;
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


- (void)pollLocal
{
    [self shouldStartBroadcastForceUIRefresh:YES];
}

- (void)shouldStartBroadcastForceUIRefresh:(BOOL)forceUIRefresh {
    if (!self.tableView.isEditing) {
        [self shouldStopBroadcast];
        
        if (forceUIRefresh) {
            [self hideHud];
            // Process the list of discovered devices before starting a new discovery process
            // We do the processing until here, because otherwise, when no sprinklers in the network, the 'SprinklersDiscovered' callback is not called at all
            [self SprinklersDiscovered];
        }
        
        [[ServiceManager current] startBroadcastForSprinklers:NO];
    }
}

-(void)SprinklersDiscovered
{
    NSArray *discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklersWithAPFlag:nil];
 
    // Mark all non-discovered sprinklers as not-alive
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Local onlySprinklersWithEmail:NO];
    NSArray *localSprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Local aliveDevices:@YES];
    for (Sprinkler *sprinkler in localSprinklers) {
        sprinkler.isDiscovered = @NO;
        sprinkler.apFlag = nil;
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
        deviceCell.disclosureImageView.hidden = (self.tableView.isEditing);// || (!deviceCell.sprinkler.isDiscovered.boolValue);
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
    
    [[GraphsManager sharedGraphsManager] reregisterAllGraphs];
    
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
    
    [NSTimer scheduledTimerWithTimeInterval:kLocalDevicesDiscoveryInterval_UserStarted
                                                                target:self
                                                              selector:@selector(pollLocal)
                                                              userInfo:nil
                                                               repeats:NO];

    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Local onlySprinklersWithEmail:NO];
    [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:NO];
    NSArray *allSprinklers = [[StorageManager current] getAllSprinklersFromNetwork];
    for (Sprinkler *sprinkler in allSprinklers) {
        sprinkler.isDiscovered = @NO;
    }
    
    [[StorageManager current] saveData];

    [self shouldStartBroadcastForceUIRefresh:NO];
    self.cloudResponse = nil;
    self.cloudEmails = nil;
    self.locallyDiscoveredSprinklers = nil;
    self.manuallyEnteredSprinklers = nil;
    self.cloudSprinklers = nil;
    
    [self startHud:nil];
    [self.tableView reloadData];
}

#pragma mark - UITableView delegate

- (NSInteger)tvSectionManuallyEnteredDevices
{
    return 0;
}

- (NSInteger)tvSectionDiscoveredDevices
{
    return [self tvSectionManuallyEnteredDevices] + 1;
}

- (NSInteger)tvSectionAddDevice
{
    return [self tvSectionDiscoveredDevices] + 1;
}

- (NSInteger)tvSectionCloud
{
    return [self tvSectionAddDevice] + 1;
}

- (NSInteger)tvNewRainMachineSetup
{
    return [self tvSectionCloud] + 1;
}

- (NSInteger)tvSectionDebugSettings
{
    return [self tvNewRainMachineSetup] + 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Manually added sprinklers
    // Discovered + Cloud Sprinklers
    // Add Device
    // Cloud
    // New Rain Machine Setup
    // Debug Settings
    return (([self tvSectionManuallyEnteredDevices] == -1) ? 0 : 1) + 4 + (ENABLE_DEBUG_SETTINGS ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self tvSectionManuallyEnteredDevices]) {
        return self.manuallyEnteredSprinklers.count;
    }
    
    if (section == [self tvSectionDiscoveredDevices]) {
        return self.locallyDiscoveredSprinklers.count + self.cloudSprinklersList.count;
    }
    
    if (section == [self tvSectionDebugSettings]) {
        return kDebugSettingsNrBeforeCloudServer + self.cloudServers.count;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == [self tvSectionManuallyEnteredDevices]) {
        if ([self tableView:tableView numberOfRowsInSection:section] > 0) {
            return @"MANUALLY ENTERED";
        }
    }
    
    if (section == [self tvSectionDiscoveredDevices]) {
        if ([self tableView:tableView numberOfRowsInSection:section] > 0) {
            return @"DISCOVERED LOCALLY & CLOUD";
        }
    }
    
    if (section == [self tvSectionDebugSettings]) {
        return @"SETTINGS (DEBUG)";
    }
        
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView titleForHeaderInSection:section]) {
        return 38;
    }

    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 56;
    }
    
    return 44;
}

- (Sprinkler*)sprinklerToShowForIndexPath:(NSIndexPath*)indexPath
{
    Sprinkler *sprinkler = nil;
    if (indexPath.section == [self tvSectionManuallyEnteredDevices]) {
        sprinkler = self.manuallyEnteredSprinklers[indexPath.row];
    } else if (indexPath.section == [self tvSectionDiscoveredDevices]) {
        if (indexPath.row < self.locallyDiscoveredSprinklers.count) {
            sprinkler = self.locallyDiscoveredSprinklers[indexPath.row];
        } else {
            sprinkler = self.cloudSprinklersList[indexPath.row - self.locallyDiscoveredSprinklers.count];
        }
    }
    
    return sprinkler;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Sprinkler *sprinkler = [self sprinklerToShowForIndexPath:indexPath];

    if (sprinkler) {
        BOOL isDeviceEditable = [Utils isManuallyAddedDevice:sprinkler] || ([Utils isDeviceInactive:sprinkler]);
        return isDeviceEditable;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        Sprinkler *sprinkler = [self sprinklerToShowForIndexPath:indexPath];
        
        BOOL currentSprinklerDeleted = sprinkler == [StorageManager current].currentSprinkler;
        [Utils invalidateLoginForCurrentSprinkler];

        BOOL deleted = [[StorageManager current] deleteSprinkler:sprinkler];
        
        if (currentSprinklerDeleted) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate refreshRootViews:nil];
        } else {
            [self refreshSprinklerList];
            if (deleted) {
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Sprinkler *sprinkler = [self sprinklerToShowForIndexPath:indexPath];

    if ((indexPath.section == [self tvSectionDiscoveredDevices]) || (indexPath.section == [self tvSectionManuallyEnteredDevices])) {
        DevicesCellType1 *cell = [Utils configureSprinklerCellForTableView:tableView indexPath:indexPath sprinkler:sprinkler canEditRow:[self tableView:tableView canEditRowAtIndexPath:indexPath] forceHiddenDisclosure:NO];
        cell.sprinkler = sprinkler;
        return cell;
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
    else {
        if (indexPath.section == [self tvSectionAddDevice]) {
            // Add New Device
            AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
            cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
            [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
            
            [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            
            return cell;
        } else {
            if (indexPath.section == [self tvSectionCloud]) {
                // Add Cloud Account
                UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
                if (!cell) {
                    cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Debug"];
                }

                cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
                
                cell.textLabel.text = @"Cloud";
                cell.detailTextLabel.text = @"";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                return cell;
            } else if (indexPath.section == [self tvNewRainMachineSetup]) {
                UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:@"Debug"];
                if (!cell) {
                    cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Debug"];
                }
                cell.selectionStyle = (self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
                cell.textLabel.text = @"New Rain Machine";
                cell.detailTextLabel.text = @"setup";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                return cell;

            } else {
                // Should not happen
                assert(0);
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.tableView.isEditing) {
        if ([self tableView:tableView canEditRowAtIndexPath:indexPath]) {
            AddNewDeviceVC *editDeviceVC = [[AddNewDeviceVC alloc] init];
            editDeviceVC.sprinkler = [self sprinklerToShowForIndexPath:indexPath];
            editDeviceVC.title = @"Edit Device";
            [self.navigationController pushViewController:editDeviceVC animated:YES];
        }
        return;
    }
    
    if ((indexPath.section == [self tvSectionDiscoveredDevices]) || (indexPath.section == [self tvSectionManuallyEnteredDevices])) {
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
            LocationSetupVC *locationSetupVC = [[LocationSetupVC alloc] init];
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
    } else {
        if (indexPath.section == [self tvSectionAddDevice]) {
            AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
            [self.navigationController pushViewController:addNewDeviceVC animated:YES];
        } else {
            if (indexPath.section == [self tvSectionCloud]) {
                self.cloudAccountsVC = [[CloudAccountsVC alloc] init];
                self.cloudAccountsVC.cloudResponse = self.cloudResponse;
                self.cloudAccountsVC.cloudSprinklers = self.cloudSprinklers;
                self.cloudAccountsVC.cloudEmails = [self.cloudEmails mutableCopy];
                
                [self.navigationController pushViewController:self.cloudAccountsVC animated:YES];
            } else if (indexPath.section == [self tvNewRainMachineSetup]) {
                AvailableWiFisVC *detailVC = [[AvailableWiFisVC alloc] init];
                [self.navigationController pushViewController:detailVC animated:YES];
            }
            else {
                // Should not happen
                assert(0);
            }
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

- (void)sprinklerSelected:(Sprinkler*)sprinkler
{
    self.selectedSprinkler = sprinkler;
    
    [self startHud:nil];
    self.versionServerProxy = [[ServerProxy alloc] initWithSprinkler:sprinkler delegate:self jsonRequest:YES];
    [self.versionServerProxy requestAPIVersion];
}

- (void)continueSprinklerSelectionAction:(Sprinkler*)sprinkler diag:(NSDictionary*)diag
{
    BOOL wizardHasRun = [diag[@"wizardHasRun"] boolValue];

    if (diag && !wizardHasRun) {
        AvailableWiFisVC *detailVC = [[AvailableWiFisVC alloc] init];
        detailVC.inputSprinklerMAC = sprinkler.sprinklerId;
        [self.navigationController pushViewController:detailVC animated:YES];
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
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {

    [self hideHud];

    if (serverProxy == self.cloudServerProxy) {
        [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:YES];
    }
    else if (serverProxy == self.diagServerProxy) {
        [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
        self.diagServerProxy = nil;
    }
    else if (serverProxy == self.versionServerProxy) {
        [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
        self.versionServerProxy = nil;
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.cloudServerProxy) {
        [self hideHud];
    //    NSError *e = nil;
    //    NSData *testData = [@"{\"sprinklersByEmail\":[{\"email\":\"dragos@oriunde.com\",\"sprinklers\":[{\"name\":\"sprinkler196\",\"mac\":\"2180:1f:02:1b:d7:4f\",\"sprinklerUrl\":\"54.76.26.90:8443\"}],\"activeCount\":1,\"knownCount\":2,\"authCount\":1}]}" dataUsingEncoding:NSUTF8StringEncoding];
    //    data = [NSJSONSerialization JSONObjectWithData:testData options:NSJSONReadingMutableContainers error:&e];
        
        // The cloud is continuosly pulled, so if the table finished editing the cloud state will refresh at the next timer poll
        if (!self.tableView.isEditing) {
            [[StorageManager current] increaseFailedCountersForDevicesOnNetwork:NetworkType_Remote onlySprinklersWithEmail:YES];
            // Mark all cloud devices is a cloud device as not alive
            NSArray *aliveRemoteDevices = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Remote aliveDevices:@YES];
            for (Sprinkler *sprinkler in aliveRemoteDevices) {
                if ([Utils isCloudDevice:sprinkler]) {
                    sprinkler.isDiscovered = @NO;
                }
            }
            
            self.cloudResponse = data;
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
                    } else {
                        if (address) {
                            sprinkler.address = address;
                        }
                        sprinkler.name = sprinklerInfo[@"name"];
                    }
                    
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
    }
    else if (serverProxy == self.versionServerProxy) {
        self.versionServerProxy = nil;
        
        NSArray *versionComponents = [Utils parseApiVersion:data];
        NSInteger versionComponentMajor = -1;
        if (versionComponents.count) versionComponentMajor = [[versionComponents firstObject] integerValue];
        
        if (versionComponentMajor == 3) {
            [self continueSprinklerSelectionAction:self.selectedSprinkler diag:nil];
        } else {
            self.diagServerProxy = [[ServerProxy alloc] initWithSprinkler:self.selectedSprinkler delegate:self jsonRequest:NO];
            [self.diagServerProxy requestDiag];
        }
    }
    else if (serverProxy == self.diagServerProxy) {
        self.diagServerProxy = nil;
        [self continueSprinklerSelectionAction:self.selectedSprinkler diag:(NSDictionary*)data];
    }
}

- (void)loggedOut {
}

- (void)loginSucceededAndRemembered:(BOOL)remembered loginResponse:(id)loginResponse unit:(NSString*)unit {
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
