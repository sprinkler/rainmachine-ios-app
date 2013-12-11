//
//  SPHomeViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 04/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SPHomeViewController.h"
#import "+UIImage.h"
#import "SPConstants.h"
#import "SPHomeScreenTableViewCell.h"
#import "SPHomeScreenDataSourceCell.h"
#import "SPServerProxy.h"
#import "SPConstants.h"
#import "SPWeatherData.h"
#import "SPMainScreenViewController.h"
#import "MBProgressHUD.h"
#import "SPSettingsViewController.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "+NSDate.h"

const int kLoggedOut_AlertViewTag = 1;
const int kError_AlertViewTag = 2;

@interface SPHomeViewController ()

@end

const float kHomeScreenCellHeight = 66;

@implementation SPHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
      [self createWaterImage];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
  
  self = [super initWithCoder:decoder];
  if (self) {
    // Custom initialization
    [self createWaterImage];
  }
  return self;
}

#pragma mark - UI

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.serverProxy = [[SPServerProxy alloc] initWithServerURL:SPTestServerURL delegate:self];
  [self.serverProxy requestWeatherData];
  [self startHud:@"Receiving data..."];
  
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

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (theAlertView.tag == kLoggedOut_AlertViewTag) {
    [self.navigationController popToRootViewControllerAnimated:NO];
  }
  
  self.alertView = nil;
}

# pragma mark - Water image generation

- (void)createWaterImage
{
  float kLineWidth = 1;// * [[UIScreen mainScreen] scale];
//  float kWaterWavesWidth = 12;
  float kWaveAmplitude = 0.5 * [[UIScreen mainScreen] scale];
  CAShapeLayer *layer = [CAShapeLayer layer];
  layer.strokeColor = [UIColor colorWithRed:kWaterImageStrokeColor[0] green:kWaterImageStrokeColor[1] blue:kWaterImageStrokeColor[2] alpha:1].CGColor;
  //  stationLayer.backgroundColor = [CBUtils CGColorFromNSColor:[NSColor redColor]];
  layer.fillColor = [UIColor colorWithRed:kWaterImageFillColor[0] green:kWaterImageFillColor[1] blue:kWaterImageFillColor[2] alpha:1].CGColor;
  layer.lineWidth = kLineWidth;
  layer.lineCap = kCALineCapRound;
  layer.lineJoin = kCALineJoinRound;

  layer.frame = CGRectMake(0, 0, 6 + 2 * kLineWidth + 2 * kWaveAmplitude, kHomeScreenCellHeight * [[UIScreen mainScreen] scale]);

  float x = layer.frame.size.width - 1 - kWaveAmplitude - kLineWidth / 2;
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, -kLineWidth, kLineWidth);
  CGPathAddLineToPoint(path, NULL, x, kLineWidth);
//  CGPathAddLineToPoint(path, NULL, layer.frame.size.width - 1, layer.frame.size.height - 1);
  
  float verticalWavesNumber = 9;
  float maxY = layer.frame.size.height - kLineWidth;
  for (int y = kLineWidth; y <= maxY; y++) {
    float angle = -M_PI + (M_PI * verticalWavesNumber * (y - kLineWidth)) / (maxY - kLineWidth);
    float dx = kWaveAmplitude * sinf(angle);
    CGPathAddLineToPoint(path, NULL, x + dx, y);
  }
  CGPathAddLineToPoint(path, NULL, -kLineWidth, maxY);

  CGPathCloseSubpath(path);
  
  layer.path = path;

  CGPathRelease(path);

  UIImage *image = [UIImage imageFromLayer:layer];
  UIEdgeInsets insets = UIEdgeInsetsMake(0, 2, 0, 2 * kLineWidth + 2 * kWaveAmplitude);
  self.waterImage = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    SPHomeScreenDataSourceCell *cell = (SPHomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    SPMainScreenViewController *tabBarController = (SPMainScreenViewController*)self.tabBarController;
    cell.dataSourceLabel.text = tabBarController.sprinkler.address;
    cell.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last update: %@", [tabBarController.sprinkler.lastUpdate getTimeSinceDate]];
    cell.sprinkler = tabBarController.sprinkler;
    
    return cell;
  }
  
  static NSString *CellIdentifier = @"HomeScreenCell";
  SPHomeScreenTableViewCell *cell = (SPHomeScreenTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  SPWeatherData *weatherData = [self.data objectAtIndex:indexPath.row];
  cell.waterPercentage = [weatherData.percentage floatValue];
  cell.waterImage.image = self.waterImage;
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
  UIImage *weatherImage = [UIImage imageNamed:[NSString stringWithFormat:@"weather_%@", weatherData.icon]];
  
  if (!weatherImage) {
    // TODO: remove this line
    weatherImage = [UIImage imageNamed:@"weather_4"];
  }
  cell.weatherImage.image = weatherImage;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (tableView == self.dataSourceTableView) {
    
    SPSettingsViewController *settingsViewController = (SPSettingsViewController*)[[self.tabBarController viewControllers] lastObject];
    self.tabBarController.selectedViewController = settingsViewController;
  }
}

#pragma mark - Communication callbacks

- (void)serverErrorReceived:(NSError*)error
{
  [MBProgressHUD hideHUDForView:self.view animated:YES];

  [self storeSprinklerError:[error localizedDescription]];

  [self refreshStatus];
  
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Network error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  self.alertView.tag = kError_AlertViewTag;
  [self.alertView show];
}

- (void)serverResponseReceived:(id)data
{
  [MBProgressHUD hideHUDForView:self.view animated:YES];

  [self storeSprinklerError:nil];
  
  self.data = data;
  
  SPWeatherData *lastWeatherData = [self.data lastObject];
  
  [self storeLastSprinklerUpdateFromString:lastWeatherData.lastupdate];

  [self.tableView reloadData];
  [self.dataSourceTableView reloadData];
}

- (void)loginSucceeded
{
}

- (void)loggedOut
{
  [MBProgressHUD hideHUDForView:self.view animated:YES];

  [self storeSprinklerError:@"Logged out"];
  
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Logged out" message:@"You've been logged out by the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  self.alertView.tag = kLoggedOut_AlertViewTag;
  [self.alertView show];
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
  [dateFormatter setDateFormat:@"HH:mm, LLL d, yyyy"];
  [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
  NSDate *myDate = [dateFormatter dateFromString:dateAsString];
  
  SPMainScreenViewController *tabBarController = (SPMainScreenViewController*)self.tabBarController;
  tabBarController.sprinkler.lastUpdate = myDate;
  [[StorageManager current] saveData];
}

- (void)storeSprinklerError:(NSString*)errorMessage
{
  SPMainScreenViewController *tabBarController = (SPMainScreenViewController*)self.tabBarController;
  tabBarController.sprinkler.lastError = errorMessage;
  [[StorageManager current] saveData];
}

@end
