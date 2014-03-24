//
//  ZonesVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 08/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ZonesVC.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "Additions.h"
#import "MBProgressHUD.h"
#import "Zone.h"
#import "ZoneCell.h"
#import "ZoneVC.h"
#import "Utils.h"

@interface ZonesVC () {
    MBProgressHUD *hud;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *zones;
@property (strong, nonatomic) Zone *unsavedZone;
@property (assign, nonatomic) int unsavedZoneIndex;

@end

@implementation ZonesVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Zones";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_tableView registerNib:[UINib nibWithNibName:@"ZoneCell" bundle:nil] forCellReuseIdentifier:@"ZoneCell"];

    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    
    [self startHud:nil];
    [self.serverProxy requestZones];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.unsavedZone) {
        [self pushVCForZone:self.unsavedZone withIndex:self.unsavedZoneIndex showInitialUnsavedAlert:YES];
        self.unsavedZone = nil;
    }
    
    [self.tableView reloadData];

    [super viewDidAppear:animated];
}

#pragma mark - Methods

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (void)setZone:(Zone*)zone withIndex:(int)i
{
    if (i >= 0) {
        [self.zones replaceObjectAtIndex:i withObject:zone];
    }
}

- (void)setUnsavedZone:(Zone*)zone withIndex:(int)i
{
    self.unsavedZone = zone;
    self.unsavedZoneIndex = i;
}

- (void)pushVCForZone:(Zone*)z withIndex:(int)i showInitialUnsavedAlert:(BOOL)showInitialUnsavedAlert
{
    ZoneVC *zoneVC = [[ZoneVC alloc] init];
    zoneVC.showMasterValve = (i == 0);
    zoneVC.zoneIndex = i;
    zoneVC.zone = z;
    zoneVC.parent = self;
    if (showInitialUnsavedAlert) {
        if (i != -1) {
            zoneVC.zoneCopyBeforeSave = self.zones[i];
        }
    }
    zoneVC.showInitialUnsavedAlert = showInitialUnsavedAlert;
    [self.navigationController pushViewController:zoneVC animated:!showInitialUnsavedAlert];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.zones = [data mutableCopy];
    [_tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.zones.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    
    Zone *zone = self.zones[indexPath.row];
    
    cell.labelTitle.text = [Utils fixedZoneName:zone.name withId:[NSNumber numberWithInt:zone.zoneId]];
    cell.labelSubtitle.text = kVegetationType[zone.vegetation];
    
    if (zone.masterValve) {
        cell.labelAccessory.text = @"Master Valve";
        cell.labelAccessory.textColor = [UIColor colorWithRed:0.850980 green:0.627451 blue:0.415686 alpha:1];
    }
    else {
        if (!zone.active) {
            cell.labelAccessory.text = @"Inactive";
        }
        else {
            cell.labelAccessory.text = @"";
        }
        cell.labelAccessory.textColor = [UIColor lightGrayColor];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self pushVCForZone:self.zones[indexPath.row] withIndex:indexPath.row showInitialUnsavedAlert:NO];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
