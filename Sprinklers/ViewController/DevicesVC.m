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
@property (strong, nonatomic) NSArray *remoteSprinklers;
@property (strong, nonatomic) NSMutableArray *discoveredSprinklers;
@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation DevicesVC

#pragma mark - Init

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.discoveredSprinklers = [NSMutableArray array];
    [self refreshSprinklerList];
    [self shouldStartBroadcast];
    [self.tableView reloadData];
    
    //If <isLoggedIn> (or use any other mechanism to detect LoginVC login, dismiss View.
}

#pragma mark - Methods

- (void)setSavedSprinklers:(NSArray *)savedSprinklers
{
    _savedSprinklers = savedSprinklers;
    _remoteSprinklers = [Utils remoteSprinklersFilter:_savedSprinklers];
}

- (void)refreshSprinklerList
{
    self.savedSprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_All aliveDevices:@YES];
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SprinklersDiscovered) name:@"SprinklersUpdate" object:nil];
    
    [[ServiceManager current] startBroadcastForSprinklers:NO];
}

-(void) SprinklersDiscovered
{
    self.discoveredSprinklers = [[ServiceManager current] getDiscoveredSprinklers];
 
    // Mark all non-discovered sprinklers as not-alive
    NSArray *localSprinklers = [[StorageManager current] getSprinklersFromNetwork:NetworkType_Local aliveDevices:@YES];
    for (Sprinkler *sprinkler in localSprinklers) {
        sprinkler.isDiscovered = @NO;
    }
    
    // Convert the DiscoveredSprinkler objects into Sprinkler objects
    // Update all discovered ones or add them as new sprinklers
    for (int i = 0; i < [self.discoveredSprinklers count]; i++) {
        DiscoveredSprinklers *discoveredSprinkler = self.discoveredSprinklers[i];
        NSString *port = [NSString stringWithFormat:@"%d", discoveredSprinkler.port];
        Sprinkler *sprinkler = [[StorageManager current] getSprinkler:discoveredSprinkler.sprinklerName address:[Utils fixedSprinklerAddress:discoveredSprinkler.host] port:port local:@YES];
        if (!sprinkler) {
            sprinkler = [[StorageManager current] addSprinkler:discoveredSprinkler.sprinklerName ipAddress:discoveredSprinkler.host port:port isLocal:@YES save:NO];
        }
        sprinkler.isDiscovered = @YES;
    }
    
    [[StorageManager current] saveData];
    
    [self refreshSprinklerList];
    
    // For now, the discovered sprinklers appear directly in the devices list, no need for wifi setup
    self.discoveredSprinklers = nil;

    [_tableView reloadData];
}

- (void)shouldStopBroadcast {
    
    [[ServiceManager current] stopBroadcast];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SprinklersUpdate" object:nil];
}

- (void)appDidBecomeActive {
    [self shouldStartBroadcast];
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

#pragma mark - Actions

- (void)done
{
    [self done:nil];
}

- (void)done:(NSString*)unit {
    if (self.tableView.isEditing) {
        [self.tableView setEditing:NO animated:YES];
        [self updateNavigationbarButtons];
        [self shouldStartBroadcast];
        return;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate refreshRootViews:unit];
}

- (void)edit {
    [self.tableView setEditing:YES animated:YES];
    [self updateNavigationbarButtons];
    [self shouldStopBroadcast];
}

- (void)onRefresh:(id)notification {
    //[self shouldStartBroadcast];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
//        if (tableView.editing) {
//            return self.remoteSprinklers.count;
//        }
        return self.savedSprinklers.count;
    }
    
    return self.discoveredSprinklers.count + 1;
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
        DevicesCellType1 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType1" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
//        Sprinkler *sprinkler = tableView.isEditing ? self.remoteSprinklers[indexPath.row] : self.savedSprinklers[indexPath.row];
        Sprinkler *sprinkler = self.savedSprinklers[indexPath.row];
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

        cell.disclosureImageView.hidden = tableView.isEditing;
        cell.labelInfo.hidden = tableView.isEditing;

        return cell;
    }
    else if (indexPath.section == 1) {
        
        if (indexPath.row < self.discoveredSprinklers.count) {
            // WiFi setup
            DevicesCellType2 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType2" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            DiscoveredSprinklers *sprinkler = self.discoveredSprinklers[indexPath.row];
            cell.labelNewDevice.text = sprinkler.sprinklerName;
            cell.detailTextLabel.text = sprinkler.host;
            
            return cell;
        }
        else {
            // Add New Device
            AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
            
            [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
            
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        Sprinkler *sprinkler = self.savedSprinklers[indexPath.row];
        
        [NetworkUtilities restoreCookieForBaseUrl:sprinkler.address port:sprinkler.port];
        int detectedSprinklerMainVersion = 0;
        
        if ([NetworkUtilities isLoginCookieActiveForBaseUrl:sprinkler.address detectedSprinklerMainVersion:&detectedSprinklerMainVersion]) {
            // Automatic login
            [ServerProxy setSprinklerVersionMajor:detectedSprinklerMainVersion
                                            minor:-1
                                         subMinor:-1];

            [StorageManager current].currentSprinkler = self.savedSprinklers[indexPath.row];
            [[StorageManager current] saveData];
            [self done:nil];
        } else {
            LoginVC *login = [[LoginVC alloc] init];
            login.sprinkler = self.savedSprinklers[indexPath.row];
            
            if ([login.sprinkler.loginRememberMe boolValue] == YES) {
                [Utils clearRememberMeFlagForSprinkler:login.sprinkler];
            }
            
            login.parent = self;
            [self.navigationController pushViewController:login animated:YES];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row < self.discoveredSprinklers.count) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            AddNewDeviceVC *addNewDeviceVC = [[AddNewDeviceVC alloc] init];
            [self.navigationController pushViewController:addNewDeviceVC animated:YES];
            
//            
//            TimePickerVC *timePickerVC = [[TimePickerVC alloc] initWithNibName:@"TimePickerVC" bundle:nil];
//            [timePickerVC refreshTimeFormatConstraint];
//            
//
//            [self.navigationController pushViewController:timePickerVC animated:YES];
            
            
//            SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
//                setDelayVC.moveLabelsLeftOfPicker = YES;
//                setDelayVC.minValuePicker1 = 2;
//                setDelayVC.maxValuePicker1 = 5;
//                setDelayVC.minValuePicker2 = 0;
//                setDelayVC.maxValuePicker2 = 300;
//                setDelayVC.userInfo = @"cycle_and_soak";
//                setDelayVC.titlePicker1 = @"Number of cycles:";
//                setDelayVC.titlePicker2 = @"Soak time:";
//            setDelayVC.valuePicker1 = 5;//self.program.cycles;
//            setDelayVC.valuePicker2 = 5; //self.program.soak;
//                setDelayVC.title = @"Cycles and soak duration";
//            
//            [self.navigationController pushViewController:setDelayVC animated:YES];

        }
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self shouldStopBroadcast];
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self shouldStartBroadcast];
}

- (void)dealloc
{
    [self shouldStopBroadcast];
}

@end
