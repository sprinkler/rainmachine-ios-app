//
//  NewRestrictionVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 28/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "NewRestrictionVC.h"
#import "RestrictedHoursVC.h"
#import "WeekdaysVC.h"
#import "TimePickerVC.h"
#import "RestrictionsCell.h"
#import "RestrictionsCheckCell.h"
#import "Additions.h"
#import "Utils.h"
#import "ServerProxy.h"
#import "HourlyRestriction.h"
#import "MBProgressHUD.h"

@interface NewRestrictionVC ()

@property (nonatomic, assign) NSInteger fromHour, fromMinutes;
@property (nonatomic, assign) NSInteger toHour, toMinutes;
@property (nonatomic, readonly) NSString *fromTimeString;
@property (nonatomic, readonly) NSString *toTimeString;
@property (nonatomic, readonly) NSDate *fromTime;
@property (nonatomic, readonly) NSDate *toTime;

@property (nonatomic, assign) NSInteger selectedTimeCellIndex;
@property (nonatomic, assign) NSInteger selectedFrequencyIndex;
@property (nonatomic, strong) NSMutableArray *selectedWeekdays;

@property (nonatomic, strong) ServerProxy *createHourlyRestrictionServerProxy;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *discardBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

- (NSString*)dateStringFromHour:(NSInteger)hour minutes:(NSInteger)minutes;
- (NSDate*)dateFromHour:(NSInteger)hour minutes:(NSInteger)minutes;
- (void)showNotValidTimeIntervalAlert;

@end

#pragma mark -

@implementation NewRestrictionVC {
    MBProgressHUD *hud;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Restriction";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedTimeCellIndex = -1;
    self.selectedFrequencyIndex = 0;
    self.fromHour = 0;
    self.fromMinutes = 1;
    self.toHour = 1;
    self.toMinutes = 1;
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.discardBarButtonItem.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        self.saveBarButtonItem.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    }
    
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCheckCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCheckCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC {
    self.selectedWeekdays = weekdaysVC.selectedWeekdays;
    [self.tableView reloadData];
}

- (void)timePickerVCWillDissapear:(TimePickerVC*)timePicker {
    if (self.selectedTimeCellIndex == 0) {
        if (timePicker.hour24Format != self.fromHour || timePicker.minutes != self.fromMinutes) {
            self.fromHour = timePicker.hour24Format;
            self.fromMinutes = timePicker.minutes;
            self.toHour = -1;
            self.toMinutes = -1;
        }
    }
    else if (self.selectedTimeCellIndex == 1) {
        NSDate *date1 = self.fromTime;
        NSDate *date2 = [self dateFromHour:timePicker.hour24Format minutes:timePicker.minutes];
        if ([date2 timeIntervalSinceDate:date1] < 0.0) {
            [self showNotValidTimeIntervalAlert];
            return;
        }
        
        self.toHour = timePicker.hour24Format;
        self.toMinutes = timePicker.minutes;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Methods

- (NSString*)fromTimeString {
    return [self dateStringFromHour:self.fromHour minutes:self.fromMinutes];
}

- (NSString*)toTimeString {
    return [self dateStringFromHour:self.toHour minutes:self.toMinutes];
}

- (NSDate*)fromTime {
    return [self dateFromHour:self.fromHour minutes:self.fromMinutes];
}

- (NSDate*)toTime {
    return [self dateFromHour:self.toHour minutes:self.toMinutes];
}

- (NSString*)dateStringFromHour:(NSInteger)hour minutes:(NSInteger)minutes {
    if (hour == -1 || minutes == -1) return nil;
    NSString *hourString = [NSString stringWithFormat:@"%ld",(long)hour];
    if (hourString.length == 1) hourString = [@"0" stringByAppendingString:hourString];
    NSString *minutesString = [NSString stringWithFormat:@"%ld",(long)minutes];
    if (minutesString.length == 1) minutesString = [@"0" stringByAppendingString:minutesString];
    return [NSString stringWithFormat:@"%@:%@",hourString,minutesString];
}

- (NSDate*)dateFromHour:(NSInteger)hour minutes:(NSInteger)minutes {
    if (hour == -1 || minutes == -1) return nil;
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    
    dateComponents.hour = hour;
    dateComponents.minute = minutes;
    
    return [calendar dateFromComponents:dateComponents];
}

- (void)showNotValidTimeIntervalAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"Not a valid time interval"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)startHud:(NSString *)text {
    if (hud) return;
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - Actions

- (void)onCell:(UITableViewCell*)cell checkmarkState:(BOOL)sel {
    RestrictionsCheckCell *restrictionsCheckCell = (RestrictionsCheckCell*)cell;
    restrictionsCheckCell.checkmarkButton.selected = YES;
    self.selectedFrequencyIndex = restrictionsCheckCell.uid;
    [self.tableView reloadData];
}

- (IBAction)onDiscard:(id)sender {
    self.selectedTimeCellIndex = -1;
    self.selectedFrequencyIndex = 0;
    self.selectedWeekdays = [NSMutableArray new];
    self.fromHour = 0;
    self.fromMinutes = 1;
    self.toHour = 1;
    self.toMinutes = 1;
    
    [self.tableView reloadData];
}

- (IBAction)onSave:(id)sender {
    if (self.fromHour == -1 || self.fromMinutes == -1 || self.toHour == -1 || self.toMinutes == -1) {
        [self showNotValidTimeIntervalAlert];
        return;
    }
    
    HourlyRestriction *restriction = [[HourlyRestriction alloc] init];
    restriction.dayStartMinute = [NSNumber numberWithInteger:self.fromHour * 60 + self.fromMinutes];
    restriction.minuteDuration = [NSNumber numberWithInteger:(self.toHour - self.fromHour) * 60 + self.toMinutes - self.fromMinutes];
    restriction.weekDays = (self.selectedFrequencyIndex == 0 ? @"1111111" : [self.selectedWeekdays componentsJoinedByString:@""]);
    
    self.createHourlyRestrictionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.createHourlyRestrictionServerProxy createHourlyRestriction:restriction];
    [self startHud:nil];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.createHourlyRestrictionServerProxy) {
        self.createHourlyRestrictionServerProxy = nil;
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.parent handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"Frequency";
    return nil;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 2;
    return 0;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 56.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        static NSString *RestrictionsCellIdentifier = @"RestrictionsCell";
        
        RestrictionsCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictionNameLabel.text = (indexPath.row == 0 ? @"From" : @"To");
        cell.restrictionCenteredNameLabel.text = (indexPath.row == 0 ? @"From" : @"To");
        cell.restrictionDescriptionLabel.text = (indexPath.row == 0 ? self.fromTimeString : self.toTimeString);
        cell.restrictionNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length ? NO : YES);
        cell.restrictionCenteredNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length ? YES : NO);
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        
        return cell;
    }
    else if (indexPath.section == 1) {
        static NSString *RestrictionsCheckCellIdentifier = @"RestrictionsCheckCell";
        
        RestrictionsCheckCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCheckCellIdentifier];
        
        cell.uid = indexPath.row;
        cell.delegate = self;
        cell.accessoryType = (indexPath.row == 0 ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator);
        cell.restrictionNameLabel.text = (indexPath.row == 0 ? @"Every day" : @"Selected days");
        cell.restrictionCenteredNameLabel.text = (indexPath.row == 0 ? @"Every day" : @"Selected days");
        cell.restrictionDescriptionLabel.text = (indexPath.row == 0 ? nil : [Utils daysStringFromWeekdaysFrequency:[self.selectedWeekdays componentsJoinedByString:@","]]);
        cell.restrictionNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length ? NO : YES);
        cell.restrictionCenteredNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length ? YES : NO);
        cell.checkmarkButton.selected = (indexPath.row == self.selectedFrequencyIndex);
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        TimePickerVC *timePickerVC = [[TimePickerVC alloc] initWithNibName:@"TimePickerVC" bundle:nil];
        timePickerVC.timeFormat = 1;
        timePickerVC.parent = self;
        timePickerVC.time = (indexPath.row == 0 ? self.fromTime : self.toTime);
        [timePickerVC refreshTimeFormatConstraint];
        
        [self.navigationController pushViewController:timePickerVC animated:YES];
        
        timePickerVC.title = (indexPath.row == 0 ? @"From time" : @"To time");
        self.selectedTimeCellIndex = indexPath.row;
    }
    else if (indexPath.section == 1) {
        RestrictionsCheckCell *cell = (RestrictionsCheckCell*)[tableView cellForRowAtIndexPath:indexPath];
        [cell onCheck:cell.checkmarkButton];
        
        if (indexPath.row == 1) {
            WeekdaysVC *weekdaysVC = [[WeekdaysVC alloc] init];
            weekdaysVC.selectedWeekdays = self.selectedWeekdays;
            weekdaysVC.parent = self;
            
            [self.navigationController pushViewController:weekdaysVC animated:YES];
        }
    }
}

@end
