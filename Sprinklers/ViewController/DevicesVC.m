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
#import "DevicesCellType3.h"
#import "ServiceManager.h"
#import "StorageManager.h"
#import "MBProgressHUD.h"
#import "LoginVC.h"
#import "AddNewDeviceVC.h"

@interface DevicesVC () {
    NSMutableArray *savedSprinklers;
    NSMutableArray *discoveredSprinklers;
    NSTimer *timer;
    NSTimer *silentTimer;
    MBProgressHUD *hud;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DevicesVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Devices";
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
    }
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
    self.navigationItem.leftBarButtonItem = saveButton;
    
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType1" bundle:nil] forCellReuseIdentifier:@"DevicesCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType2" bundle:nil] forCellReuseIdentifier:@"DevicesCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType3" bundle:nil] forCellReuseIdentifier:@"DevicesCellType3"];
    [self createFooter];
    
    [self shouldStartBroadcast];
    
    if ([StorageManager current].currentSprinkler) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
        self.navigationItem.rightBarButtonItem = closeButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[ServiceManager current] stopBroadcast];
    if (silentTimer)
        [silentTimer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    discoveredSprinklers = [NSMutableArray array];
    savedSprinklers = [NSMutableArray arrayWithArray:[[StorageManager current] getSprinklers]];
    [self.tableView reloadData];
    
    //If <isLoggedIn> (or use any other mechanism to detect LoginVC login, dismiss View.
}

#pragma mark - Methods

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)shouldStartBroadcast {
    [self startHud:nil]; // @"Looking for local sprinklers..."
    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(shouldStopBroadcast) userInfo:nil repeats:NO];
    [[ServiceManager current] startBroadcastForSprinklers:NO];
}

- (void)shouldStopBroadcast {
    [[ServiceManager current] stopBroadcast];
    discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
    [self hideHud];
    
    [_tableView reloadData];
}

- (void)appDidBecomeActive {
// Is current view visible?
//    if (self.navigationController.visibleViewController == self) {
        [self shouldStartBroadcast];
//    }
}

- (void)appDidResignActive {
    [[ServiceManager current] stopBroadcast];
    if (timer) {
        [timer invalidate];
    }
    if (silentTimer) {
        [silentTimer invalidate];
    }
    [self hideHud];
}

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
 }

- (void)shouldStartSilentBroadcast {
    [[ServiceManager current] startBroadcastForSprinklers:YES];
    [self performSelector:@selector(refreshList) withObject:nil afterDelay:2.0];
}

#pragma mark - Actions

- (void)onRefresh:(id)notification {
    [self shouldStartBroadcast];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return savedSprinklers.count;
    }
    
    return discoveredSprinklers.count + 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
    
    UILabel *lblView = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 250, 35)];
    lblView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
    lblView.backgroundColor = [UIColor clearColor];
    
//    if (section == 0) {
//        lblView.text = @"Nice section header 1";
//    }
//    if (section == 1) {
//        lblView.text = @"Nice section header 2";
//    }
  
    [headerView addSubview:lblView];
    
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        DevicesCellType1 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType1" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        Sprinkler *sprinkler = savedSprinklers[indexPath.row];
        cell.labelMainTitle.text = sprinkler.name;
        cell.labelMainSubtitle.text = sprinkler.address;
        
        // TODO: decide upon local/remote type on runtime
        cell.labelInfo.text = @"remote";
    
        return cell;
    }
    
    if (indexPath.section == 1) {
        
        if (indexPath.row < discoveredSprinklers.count) {
            DevicesCellType2 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType2" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            DiscoveredSprinklers *sprinkler = discoveredSprinklers[indexPath.row];
            cell.labelNewDevice.text = sprinkler.sprinklerName;
            cell.detailTextLabel.text = sprinkler.host;
            
            return cell;
        }
        else {
            DevicesCellType3 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType3" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            [cell.plusLabel setCustomRMFontWithCode:icon_Plus size:24];
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        Sprinkler *sprinkler = savedSprinklers[indexPath.row];
        if ([sprinkler.loginRememberMe boolValue]) {
            [StorageManager current].currentSprinkler = savedSprinklers[indexPath.row];
            [[StorageManager current] saveData];
            [self done];
        } else {
            LoginVC *login = [[LoginVC alloc] init];
            login.sprinkler = savedSprinklers[indexPath.row];
            login.parent = self;
            [self.navigationController pushViewController:login animated:YES];
        }
    } else {
        AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
        [self.navigationController pushViewController:addNewDeviceVC animated:YES];
    }
}

@end
