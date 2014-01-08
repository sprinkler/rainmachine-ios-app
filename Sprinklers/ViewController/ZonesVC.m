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

@interface ZonesVC () {
    MBProgressHUD *hud;
    NSArray *zones;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

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

    self.serverProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:YES];
    
    [self startHud:nil];
    [self.serverProxy requestZones];
}

#pragma mark - Methods

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (NSString *)getVegetationType:(int)type {
    switch (type) {
        case 0:
            return @"Bushes";
        case 1:
            return @"Grass";
        case 2:
            return @"Magic Beans";
        case 3:
            return @"Dog shit";
        case 4:
            return @"Trees";
        default:
            return @"Trees";
            break;
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    zones = data;
    [_tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return zones.count;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ZoneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZoneCell"];
    
    Zone *zone = zones[indexPath.row];
    
    cell.labelTitle.text = zone.name;
    cell.labelSubtitle.text = [self getVegetationType:zone.vegetation];
    
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

@end
