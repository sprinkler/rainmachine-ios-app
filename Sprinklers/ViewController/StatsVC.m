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
#import "WeatherData4.h"
#import "MBProgressHUD.h"
#import "SettingsViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "Sprinkler.h"
#import "Utils.h"
#import "UpdateManager.h"
#import "SettingsUnits.h"
#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "ServerResponse.h"
#import "AppDelegate.h"
#import "+NSDate.h"

const float kHomeScreenCellHeight = 63;

@interface StatsVC ()
{
    int timeFormatOfLastUpdate;
}

@property (strong, nonatomic) UIImage *waterImage;
@property (strong, nonatomic) UIImage *waterWavesImage;
@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *unitsServerProxy;
@property (strong, nonatomic) NSString *units; // used in API4
@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *statusTableView;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) RainDelayPoller *rainDelayPoller;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constrainTableBotom;

@end

@implementation StatsVC

#pragma mark - Init

- (id)initWithUnits:(NSString*)units {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if ([ServerProxy usesAPI4]) {
        [self setUnitsText:[Utils sprinklerTemperatureUnits]];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Stats";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self refreshWithCurrentDevice];
    
    self.rainDelayPoller = [[RainDelayPoller alloc] initWithDelegate:self];

    self.waterImage = [Utils waterImage:kHomeScreenCellHeight];
    self.waterWavesImage = [Utils waterWavesImage:kHomeScreenCellHeight];

    [_statusTableView registerNib:[UINib nibWithNibName:@"HomeDataSourceCell" bundle:nil] forCellReuseIdentifier:@"HomeDataSourceCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"HomeScreenCell" bundle:nil] forCellReuseIdentifier:@"HomeScreenCell"];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotSupported:) name:kDeviceNotSupported object:nil];

    //Check if there is only one Sprinkler.
    //If ONE -> do not show Device List.
    //else :
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
    }
    else {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self.serverProxy operationCount] == 0) {
        [self.serverProxy requestWeatherData];
        [self startHud:nil]; // @"Receiving data..."
    }

    [self.rainDelayPoller scheduleNextPoll:0];
    
    [self refreshStatus];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.rainDelayPoller stopPollRequests];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (NSNumber*)temperatureValue:(NSNumber*)t
{
    if ([ServerProxy usesAPI3]) {
        return t;
    }
    
    // API4
    if ([self.units isEqualToString:@"F"]) {
        float fahrenheit = [t floatValue] * 1.8 + 32;
        t = [NSNumber numberWithFloat:fahrenheit];
    }
    
    float roundedT = roundf([t floatValue]);
    
    return [NSNumber numberWithFloat:roundedT];
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

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.statusTableView) {
        return 1;
    }
    return [self.data count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.statusTableView) {
        return 54;
    }
    return kHomeScreenCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.statusTableView) {
        static NSString *CellIdentifier = @"HomeDataSourceCell";
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if ([self.rainDelayPoller rainDelayMode]) {
            [cell setRainDelayUITo:YES withValue:[self.rainDelayPoller.rainDelayData.delayCounter intValue]];
        } else {
            [cell setRainDelayUITo:NO withValue:0];
            
            // This is the old formatting style: <x> hours ago / Yesterday / ...
            // cell.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last update: %@", [StorageManager current].currentSprinkler.lastUpdate ? [[StorageManager current].currentSprinkler.lastUpdate getTimeSinceDate] : @""];
            
            // This is the new date formatting for Last update
            NSDateFormatter *formatter = [NSDate getDateFormaterFixedFormatParsing];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            [formatter setAMSymbol:@"AM"];
            [formatter setPMSymbol:@"PM"];
            if (timeFormatOfLastUpdate == 12) {
                [formatter setDateFormat:@"MM/dd/yy hh:mm a"];
            } else {
                [formatter setDateFormat:@"MM/dd/yy hh:mm"];
            }

            cell.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last update: %@", [StorageManager current].currentSprinkler.lastUpdate ? [formatter stringFromDate:[StorageManager current].currentSprinkler.lastUpdate] : @""];
            
            cell.statusImageView.image = [UIImage imageNamed:([[StorageManager current].currentSprinkler.lastError isEqualToString:@"1"]) ? @"icon_status_warning" : @"icon_status_ok"];
            if ([[StorageManager current].currentSprinkler.lastError isEqualToString:@"1"]) {
                cell.wheatherUpdateLabel.text = @"Wheather update: failure";
            } else {
                cell.wheatherUpdateLabel.text = @"NOAA";
            }

            cell.dataSourceLabel.text = [StorageManager current].currentSprinkler.address;
        }

        return cell;
    }
    
    static NSString *CellIdentifier = @"HomeScreenCell";
    HomeScreenTableViewCell *cell = (HomeScreenTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    BOOL error = NO;
    WeatherData *weatherData = [self.data objectAtIndex:indexPath.row];
    if ([ServerProxy usesAPI3]) {
        error = (weatherData.error) && ([weatherData.error intValue] == 1);
    }
    
    cell.waterPercentage = [weatherData.percentage floatValue] / self.weatherDataMaxPercentage;
    cell.waterImage.image = self.waterImage;
    cell.waterWavesImageView.image = self.waterWavesImage;

    cell.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int)roundf(([ServerProxy usesAPI3] ? 100 : 1) * [weatherData.percentage floatValue])];
    
    BOOL maxtValid = ((!error) && (weatherData.maxt) && ([weatherData.maxt isKindOfClass:[NSNumber class]]) && ([weatherData.maxt intValue] != 32000) && ([weatherData.maxt intValue] != -32000));
    BOOL mintValid = ((!error) && (weatherData.mint) && ([weatherData.mint isKindOfClass:[NSNumber class]]) && ([weatherData.mint intValue] != 32000) && ([weatherData.mint intValue] != -32000));
    
    cell.temperatureLabel.hidden = YES;
    cell.temperatureLabelPart3.hidden = YES;
    
    if ((maxtValid) && (mintValid)) {
        cell.temperatureLabelPart2.font = [UIFont systemFontOfSize:kWheatherValueFontSize];
        cell.temperatureLabelPart2.text = [NSString stringWithFormat:@"%@°%@", [self temperatureValue:weatherData.maxt], weatherData.units];
        cell.temperatureLabelPart4.font = [UIFont systemFontOfSize:kWheatherValueFontSize];
        cell.temperatureLabelPart4.text = [NSString stringWithFormat:@"%@°%@", [self temperatureValue:weatherData.mint], weatherData.units];

    } else {
        if ((!maxtValid) && (!mintValid)) {
            [cell.temperatureLabelPart2 setCustomRMFontWithCode:icon_na size:kWheatherValueCustomFontSize];
            [cell.temperatureLabelPart4 setCustomRMFontWithCode:icon_na size:kWheatherValueCustomFontSize];
        } else {
            if (!maxtValid) {
                [cell.temperatureLabelPart2 setCustomRMFontWithCode:icon_na size:kWheatherValueCustomFontSize];
                cell.temperatureLabelPart4.font = [UIFont systemFontOfSize:kWheatherValueFontSize];
                cell.temperatureLabelPart4.text = [NSString stringWithFormat:@"%@°%@", [self temperatureValue:weatherData.mint], weatherData.units];
            } else {
                // !mintValid
                cell.temperatureLabelPart2.font = [UIFont systemFontOfSize:kWheatherValueFontSize];
                cell.temperatureLabelPart2.text = [NSString stringWithFormat:@"%@°%@", [self temperatureValue:weatherData.maxt], weatherData.units];
                [cell.temperatureLabelPart4 setCustomRMFontWithCode:icon_na size:kWheatherValueCustomFontSize];
            }
        }
    }
    
    if ([weatherData.id intValue] == 0) {
        cell.daylabel.text = @"Today";
        cell.daylabel.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    else {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"LLL d";
        NSDate *dayDate = [[NSDate date] dateByAddingDays:[weatherData.id intValue]];
        cell.daylabel.text = [formatter stringFromDate:dayDate];
        cell.daylabel.textColor = [UIColor blackColor];
    }
    
    UIImage *weatherImage;
    if ([ServerProxy usesAPI3]) {
        weatherImage = [UIImage imageNamed:weatherData.icon];
    } else {
        weatherImage = [Utils weatherImageFromCode:((WeatherData4*)weatherData).icon];
    }
    cell.weatherImage.image = weatherImage;
    
    if ((error) || (!weatherData.percentage)) {
        cell.waterImage.hidden = YES;
        cell.waterWavesImageView.hidden = YES;
        cell.percentageLabel.hidden = YES;
        
        cell.percentageNotAvailableLabel.hidden = NO;

        [cell.percentageNotAvailableLabel setCustomRMFontWithCode:icon_na size:cell.percentageNotAvailableLabel.bounds.size.width];
        cell.percentageNotAvailableLabel.textColor = cell.daylabel.textColor;// [UIColor colorWithRed:153.0 / 255 green:153.0 / 255 blue:153.0 / 255 alpha:1];
    } else {
        cell.waterImage.hidden = (cell.waterPercentage == 0);
        cell.waterWavesImageView.hidden = (cell.waterPercentage == 0);
        cell.percentageLabel.hidden = NO;
        
        cell.percentageNotAvailableLabel.hidden = YES;
    }
    
    return cell;
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
    }
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.unitsServerProxy) {
        self.unitsServerProxy = nil;
    }
    
    [self refreshStatus];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    if (serverProxy == self.unitsServerProxy) {
        [self handleSprinklerNetworkError:nil operation:nil showErrorMessage:YES];
        SettingsUnits *settingsUnits = (SettingsUnits*)data;
        [self setUnitsText:settingsUnits.units];
        self.unitsServerProxy = nil;
        [self.tableView reloadData];
    } else {
        NSArray *dataArray = (NSArray*)data;
        if ([dataArray count] > 0) {
            
            [self handleSprinklerNetworkError:nil operation:nil showErrorMessage:YES];
            
            self.data = dataArray;
            
            [self rescaleDataIfNeeded];
            
            if ([ServerProxy usesAPI3]) {
                WeatherData *lastWeatherData = [self.data lastObject];
                [self storeSprinklerLastUpdateAndError:lastWeatherData];
            } else {
                for (WeatherData4 *weatherData in self.data) {
                    // TODO: fill with real value
                    weatherData.units = self.units;
                }
            }
            
            [self.tableView reloadData];
            [self.statusTableView reloadData];
        } else {
            // For some reason sometimes the server sends wrongly an empty list
            DLog(@"Warning. Empty response received from server (Stats screen).");
        }
    }
}

- (void)loggedOut
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Core Data

- (void)storeSprinklerLastUpdateAndError:(WeatherData*)weather
{
    NSString *dateAsString = weather.lastupdate;
    if ([[dateAsString componentsSeparatedByString:@","] count] == 2) {
        // TODO: remove this hack for API v4
        // In case there are only two date components, we assume that the year is not present and append the current year
        dateAsString = [NSString stringWithFormat:@"%@, %d", dateAsString, (int)[[NSDate date] year]];
    }
    
    // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
    NSDateFormatter *dateFormatter = [NSDate getDateFormaterFixedFormatParsing];
    timeFormatOfLastUpdate = 12;
    // Sprinkler 3.60 support
    [dateFormatter setDateFormat:@"MM/dd/yy K:mm a"];
    NSDate *myDate = [dateFormatter dateFromString:dateAsString];
    if (myDate) {
        timeFormatOfLastUpdate = 12;
    } else {
        // Sprinkler 3.60 support
        [dateFormatter setDateFormat:@"MM/dd/yy H:mm"];
        myDate = [dateFormatter dateFromString:dateAsString];
        if (myDate) {
            timeFormatOfLastUpdate = 24;
        } else {
            // Sprinkler 3.5x support
            [dateFormatter setDateFormat:@"K:mm a, LLL d, yyyy"];
            myDate = [dateFormatter dateFromString:dateAsString];
            if (myDate) {
                timeFormatOfLastUpdate = 12;
            } else {
                // Sprinkler 3.5x support
                [dateFormatter setDateFormat:@"H:mm, LLL d, yyyy"];
                myDate = [dateFormatter dateFromString:dateAsString];
                if (myDate) {
                    timeFormatOfLastUpdate = 24;
                } else {
                    DLog(@"Error: failed parsing string: %@", dateAsString);
                }
            }
        }
    }
    
    [StorageManager current].currentSprinkler.lastUpdate = myDate;
    if (weather.error) {
        [StorageManager current].currentSprinkler.lastError = [NSString stringWithFormat:@"%@", weather.error];
    } else {
        [StorageManager current].currentSprinkler.lastError = nil;
    }
    
    [[StorageManager current] saveData];
}

#pragma mark - Data

- (void)rescaleDataIfNeeded
{
    self.weatherDataMaxPercentage = [ServerProxy usesAPI3] ? 1.0f : 100.0f;
    
    float maxPercentage = FLT_MIN;
    for (WeatherData *weatherData in self.data) {
        if ([weatherData.percentage floatValue] > maxPercentage) {
            maxPercentage = [weatherData.percentage floatValue];
        }
    }
    
    if (maxPercentage > 1) {
        self.weatherDataMaxPercentage = maxPercentage;
    }
}

#pragma mark - Methods

- (void)cancel
{
    [self hideHUD];
    
    [self.serverProxy cancelAllOperations];
    [self.unitsServerProxy cancelAllOperations];
    
    [self.rainDelayPoller cancel];
}

- (void)refreshWithCurrentDevice
{
    self.data = nil;
    [self.tableView reloadData];
    
    if ([StorageManager current].currentSprinkler) {
        self.serverProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:[ServerProxy usesAPI4]];
//        if (![self areUnitsRetrieved]) {
//            self.unitsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
//            [self.unitsServerProxy requestSettingsUnits];
//        }
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.updateManager poll];
    }
}

- (void)setUnitsText:(NSString*)u
{
    self.units = u;
}

#pragma mark - Actions

- (IBAction)next:(id)sender {
    
    StatsTestLevel1VC *stats = [[StatsTestLevel1VC alloc] init];
    [self.navigationController pushViewController:stats animated:YES];
}

- (void)deviceNotSupported:(id)object
{
    [self cancel];
}

#pragma mark - RainDelayPollerDelegate

- (void)setRainDelay
{
    [self hideRainDelayActivityIndicator:NO];

    [self.rainDelayPoller setRainDelay];
}

- (void)hideRainDelayActivityIndicator:(BOOL)hide
{
    HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.setRainDelayActivityIndicator.hidden = hide;
}

- (void)hideHUD
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)rainDelayResponseReceived
{
    [self refreshStatus];
}

- (void)refreshStatus
{
    [self.statusTableView reloadData];
}

@end
