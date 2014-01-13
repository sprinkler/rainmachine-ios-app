//
//  StatsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "StatsVC.h"
#import "DevicesVC.h"
#import "Additions.h"
#import "StatsTestLevel1VC.h"
#import "HomeScreenTableViewCell.h"
#import "HomeScreenDataSourceCell.h"
#import "ServerProxy.h"
#import "Constants.h"
#import "WeatherData.h"
#import "MBProgressHUD.h"
#import "SettingsViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "Sprinkler.h"
#import "Utils.h"

const float kHomeScreenCellHeight = 66;

@interface StatsVC ()

@property (strong, nonatomic) UIImage *waterImage;
@property (strong, nonatomic) UIImage *waterWavesImage;
@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *dataSourceTableView;
@property (strong, nonatomic) MBProgressHUD *hud;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constrainTableBotom;

@end

@implementation StatsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Stats";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.waterImage = [Utils waterImage:kHomeScreenCellHeight];
    self.waterWavesImage = [Utils waterWavesImage:kHomeScreenCellHeight];

    [_dataSourceTableView registerNib:[UINib nibWithNibName:@"HomeDataSourceCell" bundle:nil] forCellReuseIdentifier:@"HomeDataSourceCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"HomeScreenCell" bundle:nil] forCellReuseIdentifier:@"HomeScreenCell"];

    self.serverProxy = [[ServerProxy alloc] initWithServerURL:TestServerURL delegate:self jsonRequest:NO];

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    //Check if there is only one Sprinkler.
    //If ONE -> do not show Device List.
    //else :
    [self openDevices];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //TODO: Load current sprinkler from SettingsManager here and update content if needed.
    
    [self.serverProxy requestWeatherData];
    [self startHud:nil]; // @"Receiving data..."
    
    [self refreshStatus];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)refreshStatus
{
    [self.dataSourceTableView reloadData];
}

#pragma mark - Alert view

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    self.alertView = nil;
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.dataSourceTableView) {
        return 1;
    }
    return [self.data count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.dataSourceTableView) {
        return 55;
    }
    return kHomeScreenCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.dataSourceTableView) {
        static NSString *CellIdentifier = @"HomeDataSourceCell";
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.dataSourceLabel.text = [StorageManager current].currentSprinkler.address;
        cell.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last update: %@", [StorageManager current].currentSprinkler.lastUpdate ? [[StorageManager current].currentSprinkler.lastUpdate getTimeSinceDate] : @""];
        cell.sprinkler = [StorageManager current].currentSprinkler;
        
        return cell;
    }
    
    static NSString *CellIdentifier = @"HomeScreenCell";
    HomeScreenTableViewCell *cell = (HomeScreenTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    WeatherData *weatherData = [self.data objectAtIndex:indexPath.row];
    cell.waterPercentage = [weatherData.percentage floatValue];
    cell.waterImage.image = self.waterImage;
    cell.waterWavesImageView.image = self.waterWavesImage;
    cell.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)roundf(100 * [weatherData.percentage floatValue])];
    cell.temperatureLabel.text = [NSString stringWithFormat:@"Hi: %@° / Lo: %@°", weatherData.maxt, weatherData.mint];
    if ([weatherData.id intValue] == 0) {
        cell.daylabel.text = @"Today";
    }
    else if ([weatherData.id intValue] == 1) {
        cell.daylabel.text = @"Tomorrow";
    } else {
        cell.daylabel.text = daysOfTheWeek[[weatherData.day intValue]];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIImage *weatherImage = [UIImage imageNamed:[@"main-screen_" stringByAppendingString:weatherData.icon]];
    
    cell.weatherImage.image = weatherImage;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.dataSourceTableView) {
        
        SettingsViewController *settingsViewController = (SettingsViewController*)[[self.tabBarController viewControllers] lastObject];
        self.tabBarController.selectedViewController = settingsViewController;
    }
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    
    [self refreshStatus];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy
{
    NSArray *dataArray = (NSArray*)data;
    if ([dataArray count] > 0) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [self handleGeneralSprinklerError:nil showErrorMessage:YES];
        
        self.data = dataArray;
        
        WeatherData *lastWeatherData = [self.data lastObject];
        
        [self storeLastSprinklerUpdateFromString:lastWeatherData.lastupdate];
        
        [self.tableView reloadData];
        [self.dataSourceTableView reloadData];
    } else {
        DLog(@"Warning. Empty response received from server (Stats screen).");
    }
}

- (void)loggedOut
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Core Data

- (void)storeLastSprinklerUpdateFromString:(NSString*)stringDate
{
    NSString *dateAsString = stringDate;
    if ([[dateAsString componentsSeparatedByString:@","] count] == 2) {
        // TODO: remove this hack
        // In case there are only two date components, we assume that the year is not present
        dateAsString = [NSString stringWithFormat:@"%@, %d", dateAsString, [[NSDate date] year]];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm a, LLL d, yyyy"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSDate *myDate = [dateFormatter dateFromString:dateAsString];
    
    [StorageManager current].currentSprinkler.lastUpdate = myDate;
    [[StorageManager current] saveData];
}

#pragma mark - Methods

- (void)openDevices {
    DevicesVC *devicesVC = [[DevicesVC alloc] init];
    UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:devicesVC];
    [self presentViewController:navDevices animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)next:(id)sender {
    
    StatsTestLevel1VC *stats = [[StatsTestLevel1VC alloc] init];
    [self.navigationController pushViewController:stats animated:YES];
}

@end
