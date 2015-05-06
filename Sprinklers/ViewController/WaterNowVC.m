//
//  WaterNowVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "WaterNowVC.h"
#import "Additions.h"
#import "DevicesVC.h"
#import "WaterNowLevel1VC.h"
#import "ServerProxy.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "WaterZoneListCell.h"
#import "ZoneCell.h"
#import "WaterNowLevel1VC.h"
#import "WaterNowZone.h"
#import "WaterNowZone4.h"
#import "Utils.h"
#import "StorageManager.h"
#import "CounterHelper.h"
#import "DBZone.h"
#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "HomeScreenDataSourceCell.h"
#import "RMSwitch.h"
#import "Zone.h"
#import "ZoneVC.h"

@interface WaterNowVC () {
    UIColor *switchOnOrangeColor;
    UIColor *switchOnGreenColor;
    NSTimeInterval retryInterval;
    int scheduleIntervalResetCounter;
    int stopAllCounter;
}

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ServerProxy *zonesDetailsServerProxy;
@property (strong, nonatomic) ServerProxy *zonesPropertiesServerProxy;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) ServerProxy *stopAllServerProxy;
@property (strong, nonatomic) NSArray *zones;
@property (strong, nonatomic) NSArray *filteredZones;
@property (strong, nonatomic) NSArray *zoneProperties;
@property (strong, nonatomic) NSArray *activeZoneProperties;
@property (strong, nonatomic) NSArray *inactiveZoneProperties;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) CounterHelper *wateringCounterHelper;
@property (strong, nonatomic) WaterNowZone *wateringZone;
@property (strong, nonatomic) NSMutableDictionary *stateChangeObserver;
@property (strong, nonatomic) RainDelayPoller *rainDelayPoller;

@property (strong, nonatomic) Zone *unsavedZone;
@property (assign, nonatomic) int unsavedZoneIndex;

@property (weak, nonatomic) IBOutlet UITableView *statusTableView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusTableViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *rainDelayMessage;

@end

@implementation WaterNowVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.stateChangeObserver = [NSMutableDictionary dictionary];
        scheduleIntervalResetCounter = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self resetServerProxies];
    [self setupRainDelayMode:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotSupported:) name:kDeviceNotSupported object:nil];
    
    [self refreshWithCurrentDevice];

    self.rainDelayPoller = [[RainDelayPoller alloc] initWithDelegate:self];
    self.wateringCounterHelper = [[CounterHelper alloc] initWithDelegate:self interval:1];
    self.delayedInitialListRefresh = NO;
    
    [_statusTableView registerNib:[UINib nibWithNibName:@"HomeDataSourceCell" bundle:nil] forCellReuseIdentifier:@"HomeDataSourceCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"WaterZoneListCell" bundle:nil] forCellReuseIdentifier:@"WaterZoneListCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"ZoneCell" bundle:nil] forCellReuseIdentifier:@"ZoneCell"];

    switchOnGreenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    switchOnOrangeColor = [UIColor colorWithRed:kWateringOrangeButtonColor[0] green:kWateringOrangeButtonColor[1] blue:kWateringOrangeButtonColor[2] alpha:1];

    [self refreshNavBarButtons];
    
    if ([StorageManager current].currentSprinkler) {
        [self refreshWithCurrentDevice];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.delayedInitialListRefresh) {
        [self setDensePollingInterval];
        
        self.delayedInitialListRefresh = NO;
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self performSelector:@selector(requestListRefreshWithShowingHud:) withObject:[NSNumber numberWithBool:NO] afterDelay:2];
    } else {
        [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:YES]];
    }
    
    [self.rainDelayPoller scheduleNextPoll:0];
    [self requestZonesProperties];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.unsavedZone) {
        [self pushZonePropertiesVCForZone:self.unsavedZone withIndex:self.unsavedZoneIndex showInitialUnsavedAlert:YES];
        self.unsavedZone = nil;
    }
    
    [self.tableView reloadData];
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.wateringCounterHelper stopCounterTimer];
    
    [self hideHud];
    
    self.lastScheduleRequestError = nil;
    
    [self.pollServerProxy cancelAllOperations];
    [self.postServerProxy cancelAllOperations];
    [self.stopAllServerProxy cancelAllOperations];
    [self.zonesDetailsServerProxy cancelAllOperations];
    [self.zonesPropertiesServerProxy cancelAllOperations];
    
    self.pollServerProxy = nil;
    
    [self.rainDelayPoller stopPollRequests];
    
    if (self.tabBarController.selectedViewController != self.navigationController && self.navigationController.topViewController == self) {
        self.editing = NO;
        [self refreshEditButton];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)appDidBecomeActive {
    [self clearStateChangeObserver];
    [self.tableView reloadData];
}

#pragma mark - UI

- (void)refreshNavBarButtons {
    [self refreshStopAllButton];
    [self refreshEditButton];
}

- (void)refreshEditButton {
    if ([self.rainDelayPoller rainDelayMode]) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        if (self.isEditing) self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onEdit)];
        else self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEdit)];
    }
}

- (void)refreshStopAllButton {
    BOOL leftBarButtonActive = ![self areAllStopped];
    
    if ([self.rainDelayPoller rainDelayMode]) {
        leftBarButtonActive = NO;
    }
    
    if (self.isEditing) {
        leftBarButtonActive = NO;
    }

    if (leftBarButtonActive) {
        if (!self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stop All" style:UIBarButtonItemStylePlain target:self action:@selector(stopAll)];
        }
    } else {
        if (self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

- (void)startHud:(NSString *)text {
    if (!self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.hud = nil;
}

#pragma mark - Query zones

- (int)indexOfWateringZone {
    for (int i = 0; i < [self.filteredZones count]; i++) {
        WaterNowZone *zone = self.filteredZones[i];
        if ([Utils isZoneWatering:zone]) {
            return i;
        }
    }
    
    return -1;
}

- (BOOL)areAllStopped {
    for (WaterNowZone *zone in self.filteredZones) {
        BOOL isIdle = [Utils isZoneIdle:zone];
        if (!isIdle) {
            return NO;
        }
    }
    
    return YES;
}

- (NSArray*)filteredZonesFromZones:(NSArray*)zones {
    if ([ServerProxy usesAPI3]) return zones;
    if (!self.zoneProperties.count) return nil;
    
    NSMutableArray *zonesArray = [NSMutableArray arrayWithArray:zones];
    
    // Remove the master valve and inactive zones
    
    for (WaterNowZone4 *zone in zones) {
        Zone *zoneProperties = [self zonePropertiesForWaterNowZone:zone];
        if (zoneProperties.masterValve || !zoneProperties.active) [zonesArray removeObject:zone];
    }
    
    return zonesArray;
}

- (Zone*)zonePropertiesForWaterNowZone:(WaterNowZone4*)zone {
    for (Zone *zoneProperties in self.zoneProperties) {
        if (zone.uid.intValue == zoneProperties.zoneId) {
            return zoneProperties;
        }
    }
    return nil;
}

- (int)indexOfZoneWithId:(NSNumber*)theId fromZonesArray:(NSArray*)zones {
    for (int i = 0; i < zones.count; i++) {
        WaterNowZone *zone = zones[i];
        if ([zone.id isEqualToNumber:theId]) {
            return i;
        }
    }
    return -1;
}

- (WaterNowZone*)zoneWithId:(NSNumber*)theId {
    for (int i = 0; i < self.filteredZones.count; i++) {
        WaterNowZone *zone = self.filteredZones[i];
        if ([zone.id isEqualToNumber:theId]) {
            return zone;
        }
    }
    return nil;
}

- (void)setDensePollingInterval {
    // Poll more often for a couple of times after a user action
    scheduleIntervalResetCounter = 3;
    retryInterval = kWaterNowRefreshTimeInterval_AfterUserAction;
}

#pragma mark - Unsaved zones

- (void)setZone:(Zone*)zone withIndex:(int)i {
    if (i >= 0) {
        NSMutableArray *zoneProperties = [self.zoneProperties mutableCopy];
        [zoneProperties replaceObjectAtIndex:i withObject:zone];
        self.zoneProperties = zoneProperties;
    }
}

- (void)setUnsavedZone:(Zone*)zone withIndex:(int)i {
    self.unsavedZone = zone;
    self.unsavedZoneIndex = i;
}

#pragma mark - Requests

- (void)requestListRefreshWithShowingHud:(NSNumber*)showHud {
    if (scheduleIntervalResetCounter <= 0) {
        retryInterval = kWaterNowRefreshTimeInterval;
    } else {
        scheduleIntervalResetCounter--;
    }
    
    self.pollServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.pollServerProxy requestWaterNowZoneList];
    
    self.lastListRefreshDate = [NSDate date];
    
    if ([showHud boolValue]) {
        [self startHud:nil]; // @"Receiving data..."
    }
}

- (void)scheduleNextListRefreshRequest:(NSTimeInterval)scheduleInterval {
    if (self.isViewLoaded && self.view.window) {
        // viewController is visible
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.lastListRefreshDate];
        if (t >= scheduleInterval) {
            [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:NO]];
        } else {
            [self performSelector:@selector(requestListRefreshWithShowingHud:) withObject:[NSNumber numberWithBool:NO] afterDelay:scheduleInterval - t];
        }
    }
}

- (void)stopAll {
    if ([ServerProxy usesAPI3]) {
        if ([Utils isDevice357Plus]) {
            [self.postServerProxy stopAllWateringZones];
        } else {
            for (WaterNowZone *zone in self.filteredZones) {
                BOOL isIdle = [Utils isZoneIdle:zone];
                if (!isIdle) {
                    [self toggleWateringOnZone:zone withCounter:zone.counter];
                }
            }
        }
    } else {
        [self.pollServerProxy cancelAllOperations];
        [self.zonesDetailsServerProxy cancelAllOperations];
        
        self.pollServerProxy = nil;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [self.stopAllServerProxy stopAllPrograms4];
        
        self.wateringZone = nil;
        for (WaterNowZone *zone in self.filteredZones) {
            [self userStoppedZone:zone];
            [self removeZoneFromStateChangeObserver:zone];
        }
    }
    
    stopAllCounter = 2;
    
    [self startHud:nil];
}

- (void)requestDetailsOfZones {
    for (int i = 0; i < [self.filteredZones count]; i++) {
        WaterNowZone *wateringZoneInList = self.filteredZones[i];
        [self.zonesDetailsServerProxy requestWaterActionsForZone:wateringZoneInList.id];
    }
}

- (void)requestZonesProperties {
    self.zonesPropertiesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.zonesPropertiesServerProxy requestZones];
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_ResumeRainDelay) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            [self setRainDelay];
        }
    } else {
        [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    }
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    BOOL showErrorMessage = YES;
    if (serverProxy == self.pollServerProxy) {
        showErrorMessage = NO;
        if (!self.lastScheduleRequestError) {
            retryInterval = 2 * kWaterNowRefreshTimeInterval;
            showErrorMessage = YES;
        }
        self.lastScheduleRequestError = error;
    }
    
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:showErrorMessage];
    
    if (serverProxy == self.pollServerProxy) {
        self.pollServerProxy = nil;
        
        stopAllCounter = 0;
        [self hideHud];
        
        [self scheduleNextListRefreshRequest:retryInterval];
    
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
    
    if (serverProxy == self.stopAllServerProxy) {
        
        stopAllCounter = 0;
        [self hideHud];
        [self scheduleNextListRefreshRequest:retryInterval];
    }
    
    if (serverProxy == self.zonesPropertiesServerProxy) {
        self.zonesPropertiesServerProxy = nil;
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:nil operation:nil showErrorMessage:YES];
    
    if (serverProxy == self.pollServerProxy) {
        self.pollServerProxy = nil;
        self.lastScheduleRequestError = nil;
        
        if (![self isUserTrackingASwitch]) {
        
            self.zones = data;
            if (!self.zonesPropertiesServerProxy && self.zoneProperties) {
                [self setFilteredZones:[self filteredZonesFromZones:self.zones]];
            }
            
            [self updateStopAllCounterAndDecrease:YES];
            [self requestDetailsOfZones];
            
            if (!self.zonesPropertiesServerProxy) {
                [self.tableView reloadData];
            }
            
            if ([ServerProxy usesAPI4]) {
                for (int i = 0; i < self.filteredZones.count; i++) {
                    if ([Utils isZoneWatering:self.filteredZones[i]]) {
                        [self clearStateChangeObserver];
                        self.wateringZone = self.filteredZones[i];
                        [self.wateringCounterHelper updateCounter];
                        [self refreshCounterLabel:0];
                        break;
                    }
                }
                
                [self updateStopAllCounterAndDecrease:NO];
            }
        }
        
        [self scheduleNextListRefreshRequest:retryInterval];
    }
    else if (serverProxy == self.zonesDetailsServerProxy) {
        WaterNowZone *zone = (WaterNowZone*)data;
        int index = [self indexOfZoneWithId:zone.id fromZonesArray:self.filteredZones];
        if (index != -1) {
            [self updateZoneAtIndex:index withCounterFromZone:zone setState:YES];

            if ([Utils isZoneWatering:zone]) {
                [self clearStateChangeObserver];
                self.wateringZone = self.filteredZones[index];
                [self.wateringCounterHelper updateCounter];
                [self refreshCounterLabel:0];
                
                // Force whole table reload because the "Failed to Start" labelled cell should also be updated
                [self.tableView reloadData];
            } else {
                if (index != -1) {
                    NSIndexPath *indexPathOfPendingZone = [NSIndexPath indexPathForRow:index inSection:0];
                    if (indexPathOfPendingZone) {
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathOfPendingZone] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }
            }
            
            [self updateStopAllCounterAndDecrease:NO];
        }
    }
    else if (serverProxy == self.postServerProxy) {
        [self.wateringCounterHelper updateCounter];
        [self.tableView reloadData];
    }
    else if (serverProxy == self.stopAllServerProxy) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self requestListRefreshWithShowingHud:@YES];
        [self.wateringCounterHelper updateCounter];
        [self.tableView reloadData];
    }
    else if (serverProxy == self.zonesPropertiesServerProxy) {
        NSMutableArray *activeZoneProperties = [NSMutableArray new];
        NSMutableArray *inactiveZoneProperties = [NSMutableArray new];
        
        for (Zone *zoneProperties in (NSArray*)data) {
            if (zoneProperties.active) [activeZoneProperties addObject:zoneProperties];
            else [inactiveZoneProperties addObject:zoneProperties];
        }
        
        self.zoneProperties = data;
        self.activeZoneProperties = activeZoneProperties;
        self.inactiveZoneProperties = inactiveZoneProperties;
        self.zonesPropertiesServerProxy = nil;
        
        if (!self.pollServerProxy && self.zones) {
            [self setFilteredZones:[self filteredZonesFromZones:self.zones]];
            [self.tableView reloadData];
            [self hideHud];
        }
    }

    [self refreshStopAllButton];
}

- (void)loggedOut {
    [self hideHud];
    [self handleLoggedOutSprinklerError];
}

- (void)userStoppedZone:(WaterNowZone*)zone {
    int index = [self indexOfZoneWithId:zone.id fromZonesArray:self.filteredZones];

    WaterNowZone *zoneInList = self.filteredZones[index];
    zoneInList.state = @"Idle";
    
    [self updateCounterFromDBForZone:zoneInList];
    [self.tableView reloadData];
}

- (void)userStartedZone:(WaterNowZone*)zone {
    int index = [self indexOfZoneWithId:zone.id fromZonesArray:self.filteredZones];
    
    WaterNowZone *zoneInList = self.filteredZones[index];
    zoneInList.state = @"Pending";
    zoneInList.counter = zone.counter;
    
    [[StorageManager current] setZoneCounter:zone];
    
    [self clearStateChangeObserver];
    [self.tableView reloadData];
}

- (void)cancelAllTrackings {
    if (self.isEditing) return;
    
    NSArray *visibleCells = [self.tableView visibleCells];
    for (WaterZoneListCell *cell in visibleCells) {
        assert(cell.onOffSwitch.selected == NO);
        [cell.onOffSwitch cancelTrackingWithEvent:nil];
        cell.onOffSwitch.highlighted = NO;
    }
}

- (BOOL)isUserTrackingASwitch {
    if (self.isEditing) return NO;
    
    NSArray *visibleCells = [self.tableView visibleCells];
    for (WaterZoneListCell *cell in visibleCells) {
        if (cell.onOffSwitch.isUnderUserTracking) {
            return YES;
        }
    }
    
    return NO;
}

- (void)updateStopAllCounterAndDecrease:(BOOL)decreaseCounter {
    if (stopAllCounter > 0) {
        if ([self areAllStopped]) {
            stopAllCounter = 0;
        } else {
            if (decreaseCounter) {
                stopAllCounter--;
            }
        }
    }
    
    if (stopAllCounter <= 0 && !self.zonesPropertiesServerProxy && !self.pollServerProxy && self.filteredZones) {
        [self hideHud];
    }
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.statusTableView) {
        return 1;
    }
    if (self.isEditing) return self.zoneProperties.count;
    else return self.filteredZones.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.statusTableView) {
        return 54;
    }
    return 60;
}

- (void)hide:(BOOL)hide multipartTimeLabels:(WaterZoneListCell *)cell color:(UIColor*)color {
    cell.timeLabelMultipartBottom.hidden = hide;
    cell.timeLabelMultipartTop.hidden = hide;
    
    cell.timeLabel.hidden = !hide;

    if (hide) {
        // Set text to nil because constraints work even if the view is hidden (and the text influences the view size)
        cell.timeLabelMultipartBottom.text = nil;
        cell.timeLabelMultipartTop.text = nil;
        
        cell.timeLabel.textColor = color;
    } else {
        // Set text to nil because constraints work even if the view is hidden (and the text influences the view size)
        cell.timeLabel.text = nil;

        cell.timeLabelMultipartBottom.textColor = color;
        cell.timeLabelMultipartTop.textColor = color;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *theCell = nil;
    
    if (tableView == self.statusTableView) {
        static NSString *CellIdentifier = @"HomeDataSourceCell";
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if ([self.rainDelayPoller rainDelayMode]) {
            [cell setRainDelayUITo:YES withValue:[self.rainDelayPoller.rainDelayData.delayCounter intValue]];
        } else {
            [cell setRainDelayUITo:NO withValue:0];
        }
        
        theCell = cell;
    } else {
        if (self.isEditing) {
            ZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
            Zone *zone = self.zoneProperties[indexPath.row];
            
            if (zone.masterValve) {
                cell.labelAccessory.text = @"Master Valve";
                cell.labelAccessory.textColor = [UIColor colorWithRed:kMasterValveOrangeColor[0] green:kMasterValveOrangeColor[1] blue:kMasterValveOrangeColor[2] alpha:1];
                
                cell.labelTitle.hidden = YES;
                cell.labelSubtitle.hidden = YES;
                cell.middleLabelTitle.hidden = NO;
                cell.middleLabelTitle.text = [Utils fixedZoneName:zone.name withId:[NSNumber numberWithInt:zone.zoneId]];
            }
            else {
                cell.labelTitle.hidden = NO;
                cell.labelSubtitle.hidden = NO;
                cell.middleLabelTitle.hidden = YES;
                cell.labelTitle.text = [Utils fixedZoneName:zone.name withId:[NSNumber numberWithInt:zone.zoneId]];
                cell.labelSubtitle.text = [ServerProxy usesAPI3] ? kVegetationType[zone.vegetation] : kVegetationTypeAPI4[zone.vegetation];
                
                if (!zone.active) {
                    cell.labelAccessory.text = @"Inactive";
                }
                else {
                    cell.labelAccessory.text = @"";
                }
                cell.labelAccessory.textColor = [UIColor lightGrayColor];
            }
            
            theCell = cell;
        }
        else {
            static NSString *CellIdentifier = @"WaterZoneListCell";
            WaterZoneListCell *cell = (WaterZoneListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            WaterNowZone *waterNowZone = [self.filteredZones objectAtIndex:indexPath.row];
            BOOL isPending = [Utils isZonePending:waterNowZone];
            BOOL isWatering = [Utils isZoneWatering:waterNowZone];
            BOOL isIdle = [Utils isZoneIdle:waterNowZone];
            //  BOOL unkownState = (!pending) && (!watering);
            
            cell.onOffSwitch.cell = cell;
            
            cell.delegate = self;
            cell.zone = waterNowZone;
            
            cell.zoneNameLabel.text = [Utils fixedZoneName:waterNowZone.name withId:waterNowZone.id];
            if ([ServerProxy usesAPI3]) {
                cell.descriptionLabel.text = [waterNowZone.type isEqualToString:@"Unknown"] ? @"Other" : waterNowZone.type;
            } else {
                WaterNowZone4 *waterNowZone4 = (WaterNowZone4 *)waterNowZone;
                Zone *zoneProperties = [self zonePropertiesForWaterNowZone:waterNowZone4];
                cell.descriptionLabel.text = [Utils vegetationTypeToString:zoneProperties.vegetation];
            }
            cell.onOffSwitch.on = isWatering || isPending;
            
            cell.onOffSwitch.onTintColor = isPending ? switchOnOrangeColor : (isWatering ? switchOnGreenColor : [UIColor grayColor]);
            
            if ([self zoneFailedToStart:cell.zone]) {
                [self hide:NO multipartTimeLabels:cell color:[UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1]];
                cell.timeLabelMultipartTop.text = @"Failed";
                cell.timeLabelMultipartBottom.text = @"to start";
            }
            else if (isIdle) {
                [self hide:YES multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                [cell.timeLabel setFont:[UIFont systemFontOfSize:18]];
                if ([ServerProxy usesAPI3]) {
                    cell.timeLabel.text = [NSString stringWithFormat:@"%d min", [Utils fixedRoundedToMinutesZoneCounter:cell.zone.counter isIdle:YES]];
                } else {
                    cell.timeLabel.text = [NSString stringWithFormat:@"%@ min", [Utils fixedFormattedMinutesAndSecondsFromZoneCounter:cell.zone.counter isIdle:YES]];
                }
            } else {
                if (isPending) {
                    [self hide:NO multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                    cell.timeLabelMultipartTop.text = @"Pending";
                    cell.timeLabelMultipartBottom.text = [NSString formattedTime:[[Utils fixedZoneCounter:cell.zone.counter isIdle:isIdle] intValue] usingOnlyDigits:YES];
                    if ([cell.timeLabelMultipartBottom.text isEqualToString:@"00:00"]) {
                        cell.timeLabelMultipartBottom.text = @"";
                    }
                } else {
                    // Watering
                    if (self.wateringZone) {
                        [self hide:YES multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                        [cell.timeLabel setFont:[UIFont systemFontOfSize:26]];
                        cell.timeLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue] usingOnlyDigits:YES];//@"Watering";
                        if ([cell.timeLabel.text isEqualToString:@"00:00"]) {
                            cell.timeLabel.text = @"";
                        }
                    } else {
                        // Details (i.e.: counter field) did not yet arrive from the server
                        [self hide:YES multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                        cell.timeLabel.text = @"";
                    }
                }
            }
            
            theCell = cell;
        }
    }
    
    return theCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.statusTableView) {
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:indexPath];
        if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Resume sprinkler operation?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Resume", nil];
            alertView.tag = kAlertView_ResumeRainDelay;
            [alertView show];
        }
    } else {
        if (self.isEditing) [self pushZonePropertiesVCForZone:self.zoneProperties[indexPath.row] withIndex:(int)indexPath.row showInitialUnsavedAlert:NO];
        else [self pushWaterNowZoneVCForZone:self.filteredZones[indexPath.row]];
    }
}

- (void)pushZonePropertiesVCForZone:(Zone*)z withIndex:(int)i showInitialUnsavedAlert:(BOOL)showInitialUnsavedAlert {
    ZoneVC *zoneVC = [[ZoneVC alloc] init];
    zoneVC.showMasterValve = (i == 0);
    zoneVC.zoneIndex = i;
    zoneVC.zone = z;
    zoneVC.parent = self;

    if (showInitialUnsavedAlert) {
        if (i != -1) {
            zoneVC.zoneCopyBeforeSave = self.zoneProperties[i];
        }
    }
    
    zoneVC.showInitialUnsavedAlert = showInitialUnsavedAlert;
    [self.navigationController pushViewController:zoneVC animated:!showInitialUnsavedAlert];
}

- (void)pushWaterNowZoneVCForZone:(WaterNowZone*)waterZone {
    WaterNowLevel1VC *waterNowZoneVC = nil;
    if ([ServerProxy usesAPI3]) waterNowZoneVC = [[WaterNowLevel1VC alloc] initWithNibName:@"WaterNowLevel1VC" bundle:nil];
    else waterNowZoneVC = [[WaterNowLevel1VC alloc] initWithNibName:@"WaterNowLevel1VC_SPK2" bundle:nil];
    
    if ([Utils isZoneWatering:waterZone]) {
        if ((self.wateringZone) && (self.wateringZone.counter)) {
            waterZone = self.wateringZone;
        }
    }
    waterNowZoneVC.wateringZone = waterZone;
    waterNowZoneVC.parent = self;
    [self.navigationController pushViewController:waterNowZoneVC animated:YES];
}

#pragma mark - Table View Cell callback

- (void)setWateringOnZone:(WaterNowZone*)zone toState:(int)state withCounter:(NSNumber*)counter {
    [self internalSetWateringOnZone:zone toState:state toggle:NO withCounter:counter];
}

- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter {
    [self internalSetWateringOnZone:zone toState:1 toggle:YES withCounter:counter];
}

- (void)internalSetWateringOnZone:(WaterNowZone*)zone toState:(int)state toggle:(BOOL)toggle withCounter:(NSNumber*)counter {
    [self.pollServerProxy cancelAllOperations];
    [self.zonesDetailsServerProxy cancelAllOperations];
    
    self.pollServerProxy = nil;
    
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self setDensePollingInterval];
    
    [self performSelector:@selector(requestListRefreshWithShowingHud:) withObject:[NSNumber numberWithBool:NO] afterDelay:retryInterval];
    
    zone.counter = counter;

    BOOL succeededWatering = NO;
    if (toggle) {
        succeededWatering = [self.postServerProxy toggleWateringOnZone:zone withCounter:counter];
    } else {
        succeededWatering = [self.postServerProxy setWateringOnZone:zone toState:state withCounter:counter];
    }

    if ([ServerProxy usesAPI3]) {
        // Force instant refresh on UI, wait later for server response
        if ([zone.state length] == 0)
        {
            zone.state = @"Pending";
        }
        else
        {
            zone.state = @"";
        }
    }
    
    if (succeededWatering) {
        [self userStartedZone:zone];
        [self addZoneToStateChangeObserver:zone];
    } else {
        if ((self.wateringZone) && ([zone.id isEqualToNumber:self.wateringZone.id])) {
            self.wateringZone = nil;
        }
        [self userStoppedZone:zone];
        [self removeZoneFromStateChangeObserver:zone];
    }
    
    [self refreshStopAllButton];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)deviceNotSupported:(id)object {
    [self cancel];
}

- (IBAction)next:(id)sender {
    WaterNowLevel1VC *waterNowZoneVC = nil;
    if ([ServerProxy usesAPI3]) waterNowZoneVC = [[WaterNowLevel1VC alloc] initWithNibName:@"WaterNowLevel1VC" bundle:nil];
    else waterNowZoneVC = [[WaterNowLevel1VC alloc] initWithNibName:@"WaterNowLevel1VC_SPK2" bundle:nil];
    
    waterNowZoneVC.parent = self;
    [self.navigationController pushViewController:waterNowZoneVC animated:YES];
}

- (void)onEdit {
    self.editing = !self.isEditing;
    
    [self refreshEditButton];
    [self refreshStopAllButton];
    
    [self.tableView reloadData];
}

#pragma mark - Methods

- (void)cancel
{
    [self hideHud];
    
    [self.zonesDetailsServerProxy cancelAllOperations];
    [self.pollServerProxy cancelAllOperations];
    [self.postServerProxy cancelAllOperations];
    [self.stopAllServerProxy cancelAllOperations];
    [self.zonesPropertiesServerProxy cancelAllOperations];
    
    [self.rainDelayPoller cancel];
    
    self.pollServerProxy = nil;
    self.zonesPropertiesServerProxy = nil;
}

- (void)setFilteredZones:(NSArray*)filteredZones {
    NSArray *previousZonesCopy = [self.filteredZones copy];
    
    _filteredZones = filteredZones;
    
    [self updateZonesStartObservers];
    [self updateZonesCounters:previousZonesCopy];
    
    BOOL isWateringZone = NO;
    
    for (int i = 0; i < self.filteredZones.count; i++) {
        WaterNowZone *zone = self.filteredZones[i];
        if ([Utils isZoneWatering:zone]) {
            self.wateringZone = zone;
            isWateringZone = YES;
            break;
        }
    }
    
    if (!isWateringZone) {
        self.wateringZone = nil;
        [self.wateringCounterHelper updateCounter];
    }
}

- (void)updateZonesCounters:(NSArray*)previousZonesCopy {
    if ([ServerProxy usesAPI3]) {
        // Restore counters because unpacking the server response destroyed them
        for (int i = 0; i < self.filteredZones.count; i++) {
            WaterNowZone *currentZ = self.filteredZones[i];
            int indexInPrevList = [self indexOfZoneWithId:currentZ.id fromZonesArray:previousZonesCopy];
            WaterNowZone *prevZ = (indexInPrevList != -1) ? previousZonesCopy[indexInPrevList] : self.filteredZones[i];
            
            BOOL isWatering = [Utils isZoneWatering:currentZ];
            BOOL prevIsIdle = [Utils isZoneIdle:prevZ];
            
            if ((isWatering) && (prevIsIdle)) {
                // If the watering flag was set just now and the counter value is 0 in sourceZone,
                // reset the counter because otherwise we will start counting down from the dbValue which is not always the desired start value
                prevZ.counter = nil;
            }
            
            // Restore previous state if current is empty
            [self updateZoneAtIndex:i withCounterFromZone:prevZ setState:NO];
        }
    } else {
        for (int i = 0; i < self.filteredZones.count; i++) {
            WaterNowZone *currentZ = self.filteredZones[i];
            int indexInPrevList = [self indexOfZoneWithId:currentZ.id fromZonesArray:previousZonesCopy];
            WaterNowZone *prevZ = (indexInPrevList != -1) ? previousZonesCopy[indexInPrevList] : self.filteredZones[i];
            WaterNowZone *destZone = currentZ;
            BOOL isIdle = [Utils isZoneIdle:destZone];
            
            if (isIdle) {
                [self updateCounterFromDBForZone:destZone];
            }
            
            destZone.counter = [Utils fixedZoneCounter:destZone.counter isIdle:isIdle];

            // Restore previous state if current is empty
            [self updateZoneAtIndex:i withCounterFromZone:prevZ setState:NO];
        }
    }
}

- (void)clearStateChangeObserver {
    // Keep the "Failed to Start" message until:
    // a. another pending zone becomes active
    // b. user starts another zone or an automatic program starts a zone.
    // c. user walks away from this screen or application is brought back from background.

    [self.stateChangeObserver removeAllObjects];
}

- (void)addZoneToStateChangeObserver:(WaterNowZone*)zone {
    int stateObserverCountdown = 1;
    [self.stateChangeObserver setObject:[NSNumber numberWithInt:stateObserverCountdown] forKey:zone.id];
}

- (void)removeZoneFromStateChangeObserver:(WaterNowZone*)zone {
    [self.stateChangeObserver removeObjectForKey:zone.id];
}

- (BOOL)zoneFailedToStart:(WaterNowZone*)zone {
    NSNumber *counter = [self.stateChangeObserver objectForKey:zone.id];
    if ((counter) && ([counter intValue] == 0)) {
        return [Utils isZoneIdle:zone];
    }
    
    return NO;
}

- (void)updateZonesStartObservers {
    NSMutableArray *zoneWhichStarted = [NSMutableArray array];
    
    for (NSNumber *zoneId in self.stateChangeObserver) {
        WaterNowZone *zone = [self zoneWithId:zoneId];
        if ((zone) && (![Utils isZoneIdle:zone])) {
            // Zone started
            [zoneWhichStarted addObject:zone];
        }
    }
    
    for (WaterNowZone *zone in zoneWhichStarted) {
        [self removeZoneFromStateChangeObserver:zone];
    }
    
    for (NSNumber *zoneId in [self.stateChangeObserver allKeys]) {
        // Decrement counter value
        NSNumber *n = [self.stateChangeObserver objectForKey:zoneId];
        NSNumber *newN = [NSNumber numberWithInt:MAX(0, [n intValue] - 1)];
        [self.stateChangeObserver setObject:newN forKey:zoneId];
    }
}

- (void)updateZoneAtIndex:(int)index withCounterFromZone:(WaterNowZone *)sourceZone setState:(BOOL)setState {
    if (index != -1) {
        if ([ServerProxy usesAPI3]) {
            WaterNowZone *destZone = self.filteredZones[index];
            destZone.counter = sourceZone.counter;
            if (setState) {
                destZone.state = sourceZone.state;
            }
            
            BOOL isIdle = [Utils isZoneIdle:destZone];
            
            if (isIdle) {
                [self updateCounterFromDBForZone:destZone];
            }
            
            destZone.counter = [Utils fixedZoneCounter:destZone.counter isIdle:isIdle];
        }
    }
}

- (void)updateCounterFromDBForZone:(WaterNowZone*)zone {
    DBZone *dbZone = [[StorageManager current] zoneWithId:zone.id];
    zone.counter = dbZone.counter;
}

- (void)refreshWithCurrentDevice {
    self.filteredZones = nil;
    self.zones = nil;
    
    [self.tableView reloadData];
    [self resetServerProxies];
}

- (void)resetServerProxies {
    if ([StorageManager current].currentSprinkler) {
        self.zonesDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        self.postServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        self.stopAllServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - WaterNowCounterHelper callbacks

- (BOOL)isCounteringActive {
    return [Utils isZoneWatering:self.wateringZone];
}

- (int)counterValue {
    return [self.wateringZone.counter intValue];
}

- (void)setCounterValue:(int)value {
    if (stopAllCounter == 0) {
        self.wateringZone.counter = [NSNumber numberWithInt:value];
        [self refreshCounterLabel:value];
    }
}

- (void)refreshCounterLabel:(int)newCounter {
    int wzi = [self indexOfWateringZone];
    NSIndexPath *indexPathOfWateringZone = [NSIndexPath indexPathForRow:wzi inSection:0];
    if (indexPathOfWateringZone) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathOfWateringZone] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)showCounterLabel {
}

#pragma mark - RainDelayPollerDelegate

- (void)setRainDelay {
    [self hideRainDelayActivityIndicator:NO];
    [self.rainDelayPoller setRainDelay];
}

- (void)hideRainDelayActivityIndicator:(BOOL)hide {
    HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.setRainDelayActivityIndicator.hidden = hide;
}

- (void)hideHUD {
    if (self.pollServerProxy || self.zonesPropertiesServerProxy) return;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)rainDelayResponseReceived {
    [self refreshStatus];
}

- (void)refreshStatus {
    [self setupRainDelayMode:[self.rainDelayPoller rainDelayMode]];
    [self.statusTableView reloadData];
}

- (void)setupRainDelayMode:(BOOL)rainDelayMode {
    [self refreshNavBarButtons];
    self.tableView.hidden = rainDelayMode;
    self.statusTableViewHeightConstraint.constant = rainDelayMode ? 54 : 0;
    self.statusTableView.hidden = !rainDelayMode;
    self.rainDelayMessage.hidden = !rainDelayMode;
}

@end
