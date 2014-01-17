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
    
    [self.serverProxy requestWeatherData];
    [self startHud:nil]; // @"Receiving data..."
    
    [self refreshStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.serverProxy cancelAllOperations];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
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
    BOOL error = (weatherData.error) && ([weatherData.error intValue] == 1);
   
    cell.waterPercentage = [weatherData.percentage floatValue];
    cell.waterImage.image = self.waterImage;
    cell.waterWavesImageView.image = self.waterWavesImage;
    cell.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)roundf(100 * [weatherData.percentage floatValue])];
    BOOL maxtValid = ((error) || (!weatherData.maxt));
    BOOL mintValid = ((error) || (!weatherData.mint));

    if ((maxtValid) && (mintValid)) {
        cell.temperatureLabelPart2.hidden = YES;
        cell.temperatureLabelPart3.hidden = YES;
        cell.temperatureLabelPart4.hidden = YES;
        cell.temperatureLabel.text = [NSString stringWithFormat:@"Hi: %@° / Lo: %@°", weatherData.maxt, weatherData.mint];
    } else {
        cell.temperatureLabelPart2.hidden = NO;
        cell.temperatureLabelPart3.hidden = NO;
        cell.temperatureLabelPart4.hidden = NO;
        
        if ((!maxtValid) && (!mintValid)) {
            cell.temperatureLabel.text = @"Hi:";
            [cell.temperatureLabelPart2 setCustomRMFontWithCode:icon_na size:30];
            cell.temperatureLabelPart3.text = @"Lo:";
            [cell.temperatureLabelPart4 setCustomRMFontWithCode:icon_na size:30];
        } else {
            if (!maxtValid) {
                cell.temperatureLabel.text = @"Hi:";
                [cell.temperatureLabelPart2 setCustomRMFontWithCode:icon_na size:30];
                cell.temperatureLabelPart3.text = @"/ Lo: ";
                cell.temperatureLabelPart4.font = [UIFont systemFontOfSize:13];
                cell.temperatureLabelPart4.text = [NSString stringWithFormat:@"%@°", weatherData.mint];
            } else {
                // !mintValid
                cell.temperatureLabel.text = @"Hi: ";
                cell.temperatureLabelPart2.font = [UIFont systemFontOfSize:13];
                cell.temperatureLabelPart2.text = [NSString stringWithFormat:@"%@°", weatherData.maxt];
                cell.temperatureLabelPart3.text = @"/ Lo:";
                [cell.temperatureLabelPart4 setCustomRMFontWithCode:icon_na size:30];
            }
        }
    }
    
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
    
    if ((error) || (!weatherData.percentage)) {
        cell.waterImage.hidden = YES;
        cell.waterWavesImageView.hidden = YES;
        cell.percentageLabel.hidden = YES;
        
        cell.notAvailableLabel.hidden = NO;

        [cell.notAvailableLabel setCustomRMFontWithCode:icon_na size:cell.notAvailableLabel.bounds.size.width];
        cell.notAvailableLabel.textColor = cell.daylabel.textColor;// [UIColor colorWithRed:153.0 / 255 green:153.0 / 255 blue:153.0 / 255 alpha:1];
    } else {
        cell.waterImage.hidden = NO;
        cell.waterWavesImageView.hidden = NO;
        cell.percentageLabel.hidden = NO;
        
        cell.notAvailableLabel.hidden = YES;
    }
    
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
        [self rescaleDataIfNeeded];
        
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
        // TODO: remove this hack for API v4
        // In case there are only two date components, we assume that the year is not present and append the current year
        dateAsString = [NSString stringWithFormat:@"%@, %d", dateAsString, [[NSDate date] year]];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm a, LLL d, yyyy"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSDate *myDate = [dateFormatter dateFromString:dateAsString];
    
    [StorageManager current].currentSprinkler.lastUpdate = myDate;
    [[StorageManager current] saveData];
}

#pragma mark - Data

- (void)rescaleDataIfNeeded
{
    float maxPercentage = FLT_MIN;
    for (WeatherData *weatherData in self.data) {
        if ([weatherData.percentage floatValue] > maxPercentage) {
            maxPercentage = [weatherData.percentage floatValue];
        }
    }

    if (maxPercentage > 1) {
        for (WeatherData *weatherData in self.data) {
            weatherData.percentage = [NSNumber numberWithFloat:[weatherData.percentage floatValue] / maxPercentage];
        }
    }
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
