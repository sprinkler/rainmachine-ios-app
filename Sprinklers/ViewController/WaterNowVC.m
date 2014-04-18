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
#import "WaterNowZone.h"
#import "MBProgressHUD.h"
#import "WaterZoneListCell.h"
#import "WaterNowLevel1VC.h"
#import "WaterNowZone.h"
#import "Utils.h"
#import "StorageManager.h"
#import "WaterNowCounterHelper.h"

@interface WaterNowVC () {
    UIColor *switchOnOrangeColor;
    UIColor *switchOnGreenColor;
    NSTimeInterval retryInterval;
    int stopAllCounter;
}

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ServerProxy *zonesDetailsServerProxy;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) NSArray *zones;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;
@property (strong, nonatomic) WaterNowCounterHelper *wateringCounterHelper;
@property (strong, nonatomic) WaterNowZone *wateringZone;
@property (strong, nonatomic) NSMutableDictionary *stateChangeObserver;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WaterNowVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.stateChangeObserver = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];

    [self refreshWithCurrentDevice];

    self.wateringCounterHelper = [[WaterNowCounterHelper alloc] initWithDelegate:self];
    
    self.delayedInitialListRefresh = NO;
    
    [_tableView registerNib:[UINib nibWithNibName:@"WaterZoneListCell" bundle:nil] forCellReuseIdentifier:@"WaterZoneListCell"];

    switchOnGreenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    switchOnOrangeColor = [UIColor colorWithRed:kWateringOrangeButtonColor[0] green:kWateringOrangeButtonColor[1] blue:kWateringOrangeButtonColor[2] alpha:1];

    [self refreshStopAllButton];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEdit)];

    if ([StorageManager current].currentSprinkler) {
        [self refreshWithCurrentDevice];
    }
}

- (void)refreshStopAllButton
{
    if (![self areAllStopped]) {
        if (!self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stop All" style:UIBarButtonItemStylePlain target:self action:@selector(stopAll)];
        }
    } else {
        if (self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

- (int)indexOfWateringZone
{
    for (int i = 0; i < [self.zones count]; i++) {
        WaterNowZone *zone = self.zones[i];
        if ([Utils isZoneWatering:zone]) {
            return i;
        }
    }
    
    return -1;
}

- (void)requestDetailsOfZones
{
    for (int i = 0; i < [self.zones count]; i++) {
        WaterNowZone *wateringZoneInList = self.zones[i];
        [self.zonesDetailsServerProxy requestWaterActionsForZone:wateringZoneInList.id];
    }
}

- (BOOL)areAllStopped
{
    for (WaterNowZone *zone in self.zones) {
        BOOL isIdle = [Utils isZoneIdle:zone];
        if (!isIdle) {
            return NO;
        }
    }
    
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resetServerProxies];

    if (self.delayedInitialListRefresh) {
        self.delayedInitialListRefresh = NO;
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self performSelector:@selector(requestListRefreshWithShowingHud:) withObject:[NSNumber numberWithBool:NO] afterDelay:2];
    } else {
        [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:YES]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.wateringCounterHelper stopCounterTimer];
    
    [self hideHud];

    self.lastScheduleRequestError = nil;
    
    [self.pollServerProxy cancelAllOperations];
    [self.postServerProxy cancelAllOperations];
    [self.zonesDetailsServerProxy cancelAllOperations];
    
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)startHud:(NSString *)text {
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    self.hud.labelText = text;
}

- (void)hideHud
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.hud = nil;
}

#pragma mark - Requests

- (void)requestListRefreshWithShowingHud:(NSNumber*)showHud
{
    [self.pollServerProxy requestWaterNowZoneList];
    
    self.lastListRefreshDate = [NSDate date];
    
    if ([showHud boolValue]) {
        [self startHud:nil]; // @"Receiving data..."
    }
}

- (void)scheduleNextListRefreshRequest:(NSTimeInterval)scheduleInterval
{
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

- (void)stopAll
{
    for (WaterNowZone *zone in self.zones) {
        BOOL isIdle = [Utils isZoneIdle:zone];
        if (!isIdle) {
            [self toggleWateringOnZone:zone withCounter:zone.counter];
        }
    }
    
    stopAllCounter = 2;
    
    [self startHud:nil];
}

#pragma mark - Alert view
- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    self.alertView = nil;
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    BOOL showErrorMessage = YES;
    if (serverProxy == self.pollServerProxy) {
        showErrorMessage = NO;
        if (!self.lastScheduleRequestError) {
            retryInterval = 2 * kWaterNowRefreshTimeInterval;
            showErrorMessage = YES;
        }
        self.lastScheduleRequestError = error;
    }
    
    [self handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:showErrorMessage];
    
    if (serverProxy == self.pollServerProxy) {
        
        stopAllCounter = 0;
        [self hideHud];
        
        [self scheduleNextListRefreshRequest:retryInterval];
    
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self handleSprinklerNetworkError:nil showErrorMessage:YES];
    
    if (serverProxy == self.pollServerProxy) {
        
        self.lastScheduleRequestError = nil;
        
        // Preserve the previous values of the counters
        NSArray *previousZonesCopy = [self.zones copy];
        
        self.zones = [self filteredZones:data];

        // Restore the values of the counters
        [self updateZonesStartObservers];
        
        // Restore counters because unpacking the server response destroyed them
        for (int i = 0; i < previousZonesCopy.count; i++) {
            WaterNowZone *z = previousZonesCopy[i];
            int indexInNewList = [self indexOfZoneWithId:z.id];
            [self updateZoneAtIndex:indexInNewList withDetails:z];
        }
        
        if (stopAllCounter > 0) {
            if ([self areAllStopped]) {
                stopAllCounter = 0;
            } else {
                stopAllCounter--;
            }
        }
        
        if (stopAllCounter <= 0) {
            [self hideHud];
        }
        
        [self scheduleNextListRefreshRequest:kWaterNowRefreshTimeInterval];
        
        [self requestDetailsOfZones];
        
        [self refreshStopAllButton];
        
        [self.tableView reloadData];
    }
    else if (serverProxy == self.zonesDetailsServerProxy) {
        WaterNowZone *zone = (WaterNowZone*)data;
        int index = [self indexOfZoneWithId:zone.id];
        [self updateZoneAtIndex:index withDetails:zone];
        
        if ([Utils isZoneWatering:zone]) {
            if (![self.wateringZone.id isEqualToNumber:zone.id]) {
                [self clearStateChangeObserver];
            }
            self.wateringZone = zone;
            [self.wateringCounterHelper updateCounter];
            [self refreshCounterLabel:0];
        } else {
            if (index != -1) {
                NSIndexPath *indexPathOfPendingZone = [NSIndexPath indexPathForRow:index inSection:0];
                if (indexPathOfPendingZone) {
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathOfPendingZone] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
        }
        [self.tableView reloadData];
    }
}

- (void)userStartedAZone
{
    [self clearStateChangeObserver];
}

- (void)loggedOut
{
    [self hideHud];
    
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.zones count];
}

- (void)hide:(BOOL)hide multipartTimeLabels:(WaterZoneListCell *)cell color:(UIColor*)color
{
    cell.timeLabelMultipartBottom.hidden = hide;
    cell.timeLabelMultipartTop.hidden = hide;
    
    cell.timeLabel.hidden = !hide;

    if (hide) {
        cell.timeLabel.textColor = color;
    } else {
        cell.timeLabelMultipartBottom.textColor = color;
        cell.timeLabelMultipartTop.textColor = color;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"WaterZoneListCell";
    WaterZoneListCell *cell = (WaterZoneListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    WaterNowZone *waterNowZone = [self.zones objectAtIndex:indexPath.row];
    BOOL isPending = [Utils isZonePending:waterNowZone];
    BOOL isWatering = [Utils isZoneWatering:waterNowZone];
    BOOL isIdle = [Utils isZoneIdle:waterNowZone];
    //  BOOL unkownState = (!pending) && (!watering);
    
    cell.delegate = self;
    cell.zone = waterNowZone;
    
    cell.zoneNameLabel.text = [Utils fixedZoneName:waterNowZone.name withId:waterNowZone.id];
    cell.descriptionLabel.text = [waterNowZone.type isEqualToString:@"Unknown"] ? @"Other" : waterNowZone.type;
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
        cell.timeLabel.text = [NSString stringWithFormat:@"%d min", [[Utils fixedZoneCounter:cell.zone.counter isIdle:YES] intValue] / 60];
    } else {
        if (isPending) {
            [self hide:NO multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
            cell.timeLabelMultipartTop.text = @"Pending";
            cell.timeLabelMultipartBottom.text = [NSString stringWithFormat:@"%d min", [[Utils fixedZoneCounter:cell.zone.counter isIdle:YES] intValue] / 60];
        } else {
            // Watering
            if (self.wateringZone) {
                [self hide:YES multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                [cell.timeLabel setFont:[UIFont systemFontOfSize:26]];
                cell.timeLabel.text = [NSString formattedTime:[[Utils fixedZoneCounter:self.wateringZone.counter isIdle:isIdle] intValue] usingOnlyDigits:YES];//@"Watering";
            } else {
                // Details (i.e.: counter field) did not yet arrive from the server
                [self hide:YES multipartTimeLabels:cell color:cell.onOffSwitch.onTintColor];
                cell.timeLabel.text = @"";
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WaterNowLevel1VC *waterNowZoneVC = [[WaterNowLevel1VC alloc] init];
    WaterNowZone *waterZone = [self.zones objectAtIndex:indexPath.row];
    if ([Utils isZoneWatering:waterZone]) {
        if ((self.wateringZone) && (self.wateringZone.counter)) {
            waterZone = self.wateringZone;
        }
    }
    waterNowZoneVC.wateringZone = waterZone;
    waterNowZoneVC.parent = self;
    [self.navigationController pushViewController:waterNowZoneVC animated:YES];
}

#pragma mark - Backend

- (NSArray*)filteredZones:(NSArray*)zones
{
    NSMutableArray *rez = [NSMutableArray array];
    for (WaterNowZone *zone in zones) {
        [rez addObject:zone];
    }
    return rez;
}

#pragma mark - Table View Cell callback

- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
{
    //[self.wateringCounterHelper stopCounterTimer];
    
    if ([self.postServerProxy toggleWateringOnZone:zone withCounter:counter]) {
        [self userStartedAZone];
        [self addZoneToStateChangeObserver:zone];
    } else {
        [self removeZoneFromStateChangeObserver:zone];
    }
    
    // insntant refresh on UI, wait later for server response
    if ([zone.state length] == 0)
    {
        zone.state = @"Pending";
    }
    else
    {
        zone.state = @"";
    }
    
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)next:(id)sender {
    WaterNowLevel1VC *waterNowZoneVC = [[WaterNowLevel1VC alloc] init];
    waterNowZoneVC.parent = self;
    [self.navigationController pushViewController:waterNowZoneVC animated:YES];
}

- (void)onEdit
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowSettingsZones object:nil];
}

#pragma mark - Methods

- (void)clearStateChangeObserver
{
    // Keep the "Failed to Start" message until:
    // a. another pending zone becomes active
    // b. user starts another zone or an automatic program starts a zone.
    // c. user walks away from this screen or application is brought back from background.

    [self.stateChangeObserver removeAllObjects];
}

- (void)addZoneToStateChangeObserver:(WaterNowZone*)zone
{
    [self.stateChangeObserver setObject:[NSNumber numberWithInt:1] forKey:zone.id];
}

- (void)removeZoneFromStateChangeObserver:(WaterNowZone*)zone
{
    [self.stateChangeObserver removeObjectForKey:zone.id];
}

- (BOOL)zoneFailedToStart:(WaterNowZone*)zone
{
    NSNumber *counter = [self.stateChangeObserver objectForKey:zone.id];
    if ((counter) && ([counter intValue] == 0)) {
        return [Utils isZoneIdle:zone];
    }
    
    return NO;
}

- (void)updateZonesStartObservers
{
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
        NSNumber *n = [self.stateChangeObserver objectForKey:zoneId];
        NSNumber *newN = [NSNumber numberWithInt:MAX(0, [n intValue] - 1)];
        [self.stateChangeObserver setObject:newN forKey:zoneId];
    }
}

- (void)updateZoneAtIndex:(int)index withDetails:(WaterNowZone*)zone
{
    if (index != -1) {
        WaterNowZone *destZone = self.zones[index];
        destZone.counter = zone.counter;
    }
}

- (int)indexOfZoneWithId:(NSNumber*)theId
{
    for (int i = 0; i < self.zones.count; i++) {
        WaterNowZone *zone = self.zones[i];
        if ([zone.id isEqualToNumber:theId]) {
            return i;
        }
    }
    return -1;
}

- (WaterNowZone*)zoneWithId:(NSNumber*)theId
{
    for (int i = 0; i < self.zones.count; i++) {
        WaterNowZone *zone = self.zones[i];
        if ([zone.id isEqualToNumber:theId]) {
            return zone;
        }
    }
    return nil;
}

- (void)refreshWithCurrentDevice
{
    self.zones = nil;
    
    [self.tableView reloadData];
    [self resetServerProxies];
}

- (void)resetServerProxies
{
    if ([StorageManager current].currentSprinkler) {
        self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        self.zonesDetailsServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - WaterNowCounterHelper callbacks

- (void)refreshCounterLabel:(int)newCounter
{
    int wzi = [self indexOfWateringZone];
    NSIndexPath *indexPathOfWateringZone = [NSIndexPath indexPathForRow:wzi inSection:0];
    if (indexPathOfWateringZone) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPathOfWateringZone] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)showCounterLabel
{
}

- (void)appDidBecomeActive
{
    [self clearStateChangeObserver];
    [self.tableView reloadData];
}

@end
