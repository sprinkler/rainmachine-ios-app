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

@interface WaterNowVC () {
    UIColor *switchOnOrangeColor;
    UIColor *switchOnGreenColor;
    NSTimeInterval retryInterval;
}

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ServerProxy *pollServerProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) NSArray *zones;
@property (strong, nonatomic) NSDate *lastListRefreshDate;
@property (strong, nonatomic) NSError *lastScheduleRequestError;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WaterNowVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWithCurrentDevice) name:kNewSprinklerSelected object:nil];

    [_tableView registerNib:[UINib nibWithNibName:@"WaterZoneListCell" bundle:nil] forCellReuseIdentifier:@"WaterZoneListCell"];

    switchOnGreenColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
    switchOnOrangeColor = [UIColor colorWithRed:kWateringOrangeButtonColor[0] green:kWateringOrangeButtonColor[1] blue:kWateringOrangeButtonColor[2] alpha:1];
    
    UIBarButtonItem *stopAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop All" style:UIBarButtonItemStylePlain target:self action:@selector(stopAll)];
    self.navigationItem.rightBarButtonItem = stopAllButton;
    
    if ([StorageManager current].currentSprinkler) {
        [self refreshWithCurrentDevice];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self requestListRefreshWithShowingHud:[NSNumber numberWithBool:YES]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.pollServerProxy cancelAllOperations];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
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
    
    [self handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:showErrorMessage];
    
    if (serverProxy == self.pollServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [self scheduleNextListRefreshRequest:retryInterval];
    
        retryInterval *= 2;
        retryInterval = MIN(retryInterval, kWaterNowMaxRefreshInterval);
    }
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self handleGeneralSprinklerError:nil showErrorMessage:YES];
    
    if (serverProxy == self.pollServerProxy) {
        self.lastScheduleRequestError = nil;
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        self.zones = [self filteredZones:data];
        
        [self scheduleNextListRefreshRequest:kWaterNowRefreshTimeInterval];
        
        [self.tableView reloadData];
    }
}

- (void)loggedOut
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self handleLoggedOutSprinklerError];

    [StorageManager current].currentSprinkler = nil;
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.zones count];
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
    cell.descriptionLabel.text = waterNowZone.type;
    cell.onOffSwitch.on = isWatering || isPending;
    
    cell.onOffSwitch.onTintColor = isPending ? switchOnOrangeColor : (isWatering ? switchOnGreenColor : [UIColor grayColor]);
    cell.timeLabel.textColor = cell.onOffSwitch.onTintColor;
    
    cell.timeLabel.text = isIdle ? @"" : (isPending ? @"Pending" : @"Watering");
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WaterNowLevel1VC *waterNowZoneVC = [[WaterNowLevel1VC alloc] init];
    WaterNowZone *waterZone = [self.zones objectAtIndex:indexPath.row];
    waterNowZoneVC.waterZone = waterZone;
    [self.navigationController pushViewController:waterNowZoneVC animated:YES];
}

#pragma mark - Backend

- (NSArray*)filteredZones:(NSArray*)zones
{
    NSMutableArray *rez = [NSMutableArray array];
    for (WaterNowZone *zone in zones) {
        // Skip the Master Valve
        if ([zone.id intValue] != 1) {
            [rez addObject:zone];
        }
    }
    return rez;
}

#pragma mark - Table View Cell callback

- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
{
    [self.postServerProxy toggleWateringOnZone:zone withCounter:counter];
}

#pragma mark - Actions

- (IBAction)next:(id)sender {
    WaterNowLevel1VC *water = [[WaterNowLevel1VC alloc] init];
    [self.navigationController pushViewController:water animated:YES];
}

#pragma mark - Methods

- (void)refreshWithCurrentDevice
{
    self.zones = nil;
    [self.tableView reloadData];

    if ([StorageManager current].currentSprinkler) {
        self.pollServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
