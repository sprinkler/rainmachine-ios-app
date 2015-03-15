//
//  RestrictionsVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 07/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsVC.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "Program.h"
#import "MBProgressHUD.h"
#import "Additions.h"
#import "Utils.h"
#import "SettingsVC.h"
#import "ServerResponse.h"
#import "WateringRestrictions.h"
#import "HourlyRestriction.h"
#import "RestrictionsCell.h"
#import "RestrictionsSwitchCell.h"
#import "WeekdaysVC.h"
#import "MonthsVC.h"
#import "PickerVC.h"
#import "RestrictedHoursVC.h"

@interface RestrictionsVC ()

@property (strong, nonatomic) ServerProxy *requestWateringRestrictionsServerProxy;
@property (strong, nonatomic) ServerProxy *requestHourlyRestrictionsServerProxy;
@property (strong, nonatomic) ServerProxy *saveWateringRestrictionsServerProxy;
@property (strong, nonatomic) WateringRestrictions *wateringRestrictions;
@property (strong, nonatomic) NSArray *hourlyRestrictions;
@property (strong, nonatomic) NSArray *hourlyRestrictionDescriptions;
@property (assign, nonatomic) BOOL firstRefreshInProgress;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (void)requestWateringRestrictions;
- (void)saveWateringRestrictions;
- (void)requestHourlyRestrictions;
    
- (NSMutableArray*)weekDaysFrequencyFromRawString:(NSString*)string;
- (NSMutableArray*)monthsFrequencyFromRawString:(NSString*)string;
- (NSString*)descriptionForHourlyRestriction:(HourlyRestriction*)restriction;

- (void)showFreezeProtectTemperaturePickerVC;

@end

@implementation RestrictionsVC {
    MBProgressHUD *hud;
}

#pragma Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Restrictions";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsSwitchCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsSwitchCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCell"];
    
    self.firstRefreshInProgress = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.firstRefreshInProgress) {
        [self requestWateringRestrictions];
        [self requestHourlyRestrictions];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Methods

- (void)requestWateringRestrictions {
    self.requestWateringRestrictionsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestWateringRestrictionsServerProxy requestWateringRestrictions];
    [self startHud:nil];
}

- (void)saveWateringRestrictions {
    self.saveWateringRestrictionsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveWateringRestrictionsServerProxy postWateringRestrictions:self.wateringRestrictions];
    [self startHud:nil];
}

- (void)requestHourlyRestrictions {
    self.requestHourlyRestrictionsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestHourlyRestrictionsServerProxy requestHourlyRestrictions];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    if (hud) return;
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (NSMutableArray*)weekDaysFrequencyFromRawString:(NSString*)string {
    NSMutableArray *weekDaysFrequency = [NSMutableArray array];
    for (NSUInteger index = 0; index < string.length; index++) {
        [weekDaysFrequency addObject:[string substringWithRange:NSMakeRange(index, 1)]];
    }
    return weekDaysFrequency;
}

- (NSMutableArray*)monthsFrequencyFromRawString:(NSString*)string {
    NSMutableArray *monthsFrequency = [NSMutableArray array];
    for (NSUInteger index = 0; index < string.length; index++) {
        [monthsFrequency addObject:[string substringWithRange:NSMakeRange(index, 1)]];
    }
    return monthsFrequency;
}

- (NSString*)daysDescriptionForHourlyRestriction:(HourlyRestriction*)restriction {
    NSArray *weekDaysFrequency = [self weekDaysFrequencyFromRawString:restriction.weekDays];
    return ([weekDaysFrequency indexOfObject:@"0"] == NSNotFound ? @"Every day" : [Utils daysStringFromWeekdaysFrequency:[weekDaysFrequency componentsJoinedByString:@","]]);
}

- (NSString*)timeDescriptionForHourlyRestriction:(HourlyRestriction*)restriction {
    NSArray *timeIntervalComponents = [restriction.interval componentsSeparatedByString:@" - "];
    NSString *startTime = (timeIntervalComponents.count > 0 ? timeIntervalComponents[0] : nil);
    NSString *endTime = (timeIntervalComponents.count > 1 ? timeIntervalComponents[1] : nil);
    
    NSArray *startTimeComponents = [startTime componentsSeparatedByString:@":"];
    NSString *startHour = (startTimeComponents.count > 0 ? startTimeComponents[0] : nil);
    NSString *startMinutes = (startTimeComponents.count > 1 ? startTimeComponents[1] : nil);
    if (startMinutes.length == 1) startMinutes = [@"0" stringByAppendingString:startMinutes];
    
    NSArray *endTimeComponents = [endTime componentsSeparatedByString:@":"];
    NSString *endHour = (endTimeComponents.count > 0 ? endTimeComponents[0] : nil);
    NSString *endMinutes = (endTimeComponents.count > 1 ? endTimeComponents[1] : nil);
    if (endMinutes.length == 1) endMinutes = [@"0" stringByAppendingString:endMinutes];

    if ([Utils timeIs24HourFormat]) {
        return [NSString stringWithFormat:@"%@:%@ - %@:%@",startHour,startMinutes,endHour,endMinutes];
    }
    
    return [NSString stringWithFormat:@"%d:%@ %@ - %d:%@ %@",
            [startHour intValue] % 12,
            startMinutes,
            ([startHour intValue] / 12) == 0 ? @"AM" : @"PM",
            [endHour intValue] % 12,
            endMinutes,
            ([endHour intValue] / 12) == 0 ? @"AM" : @"PM"
            ];
}

- (NSString*)descriptionForHourlyRestriction:(HourlyRestriction*)restriction {
    return [NSString stringWithFormat:@"%@ %@",
            [self daysDescriptionForHourlyRestriction:restriction],
            [self timeDescriptionForHourlyRestriction:restriction]];
}

- (void)showFreezeProtectTemperaturePickerVC {
    NSString *temperatureUnits = [Utils sprinklerTemperatureUnits];
    
    PickerVC *pickerVC = [[PickerVC alloc] init];
    pickerVC.title = @"Do not water under";
    pickerVC.itemsArray = @[@"0", @"2", @"5", @"10"];
    pickerVC.selectedItem = [NSString stringWithFormat:@"%d",(int)self.wateringRestrictions.freezeProtectTemperature];
    pickerVC.parent = self;
    
    if ([temperatureUnits isEqualToString:@"F"]) {
        pickerVC.itemsDisplayStringArray = @[@"32", @"36", @"41", @"50"];
        pickerVC.selectedItemTitle = @"°F";
    } else {
        pickerVC.itemsDisplayStringArray = @[@"0", @"2", @"5", @"10"];
        pickerVC.selectedItemTitle = @"°C";
    }
    
    [self.navigationController pushViewController:pickerVC animated:YES];
}

#pragma mark - Actions

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC {
    self.wateringRestrictions.noWaterInWeekDays = [weekdaysVC.selectedWeekdays componentsJoinedByString:@""];
    [self saveWateringRestrictions];
}

- (void)monthsVCWillDissapear:(MonthsVC*)monthsVC {
    self.wateringRestrictions.noWaterInMonths = [monthsVC.selectedMonths componentsJoinedByString:@""];
    [self saveWateringRestrictions];
}

- (void)pickerVCWillDissapear:(PickerVC*)pickerVC {
    if (!pickerVC.selectedItem.length) return;
    self.wateringRestrictions.freezeProtectEnabled = YES;
    self.wateringRestrictions.freezeProtectTemperature = pickerVC.selectedItem.doubleValue;
    [self saveWateringRestrictions];
}

- (IBAction)onCellSwitch:(RestrictionsSwitchCell*)cell {
    if (cell.uid == 0) self.wateringRestrictions.hotDaysExtraWatering = cell.restrictionEnabledSwitch.on;
    else if (cell.uid == 1) {
        self.wateringRestrictions.freezeProtectEnabled = cell.restrictionEnabledSwitch.on;
        if (self.wateringRestrictions.freezeProtectEnabled) [self showFreezeProtectTemperaturePickerVC];
        else [self saveWateringRestrictions];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestWateringRestrictionsServerProxy) {
        self.wateringRestrictions = (WateringRestrictions*)data;
        self.requestWateringRestrictionsServerProxy = nil;
    }
    
    if (serverProxy == self.requestHourlyRestrictionsServerProxy) {
        self.hourlyRestrictions = (NSArray*)data;
        self.requestHourlyRestrictionsServerProxy = nil;
        
        NSMutableArray *hourlyRestrictionDescriptions = [NSMutableArray new];
        for (HourlyRestriction *hourlyRestriction in self.hourlyRestrictions) {
            [hourlyRestrictionDescriptions addObject:[self descriptionForHourlyRestriction:hourlyRestriction]];
        }
        
        self.hourlyRestrictionDescriptions = hourlyRestrictionDescriptions;
    }
    
    if (serverProxy == self.saveWateringRestrictionsServerProxy) {
        self.saveWateringRestrictionsServerProxy = nil;
        [self requestWateringRestrictions];
        return;
    }
    
    if (!self.requestWateringRestrictionsServerProxy &&
        !self.requestHourlyRestrictionsServerProxy &&
        !self.saveWateringRestrictionsServerProxy) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    if (!self.requestWateringRestrictionsServerProxy && !self.requestHourlyRestrictionsServerProxy) {
        self.firstRefreshInProgress = NO;
    }
    
    [_tableView reloadData];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.firstRefreshInProgress) return 0;
    else return 5;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 56.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *RestrictionsSwitchCellIdentifier = @"RestrictionsSwitchCell";
    static NSString *RestrictionsCellIdentifier = @"RestrictionsCell";
    
    if (indexPath.row == 0) {
        RestrictionsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsSwitchCellIdentifier];
        
        cell.uid = 0;
        cell.delegate = self;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.restrictionNameLabel.text = @"Hot Days";
        cell.restrictionDescriptionLabel.text = @"Allow extra watering";
        cell.restrictionEnabledSwitch.on = self.wateringRestrictions.hotDaysExtraWatering;
        cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        cell.switchTrailingSpaceLayoutConstraint.constant = 37.0;
        
        return cell;
    }
    else if (indexPath.row == 1) {
        RestrictionsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsSwitchCellIdentifier];
    
        double freezeProtectTemperature = self.wateringRestrictions.freezeProtectTemperature;
        NSString *temperatureUnits = [Utils sprinklerTemperatureUnits];
        
        if ([temperatureUnits isEqualToString:@"F"]) {
            freezeProtectTemperature = freezeProtectTemperature * 1.8 + 32;
        }
        
        cell.uid = 1;
        cell.delegate = self;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictionNameLabel.text = @"Freeze Protect";
        cell.restrictionDescriptionLabel.text = [NSString stringWithFormat:@"Do not water under %d°%@",(int)freezeProtectTemperature,temperatureUnits];
        cell.restrictionEnabledSwitch.on = self.wateringRestrictions.freezeProtectEnabled;
        cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        cell.switchTrailingSpaceLayoutConstraint.constant = 4.0;
        
        return cell;
    }
    else if (indexPath.row == 2) {
        RestrictionsCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCellIdentifier];
        
        NSArray *monthsFrequency = [self monthsFrequencyFromRawString:self.wateringRestrictions.noWaterInMonths];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictionNameLabel.text = @"Months";
        cell.restrictionCenteredNameLabel.text = @"Months";
        cell.restrictionDescriptionLabel.text = [Utils monthsStringFromMonthsFrequency:[monthsFrequency componentsJoinedByString:@","]];
        cell.restrictionNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length == 0);
        cell.restrictionCenteredNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length > 0);
        cell.restrictionDescriptionLabel.textColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        
        return cell;
    }
    else if (indexPath.row == 3) {
        RestrictionsCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCellIdentifier];
        
        NSArray *weekDaysFrequency = [self weekDaysFrequencyFromRawString:self.wateringRestrictions.noWaterInWeekDays];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictionNameLabel.text = @"Days";
        cell.restrictionCenteredNameLabel.text = @"Days";
        cell.restrictionDescriptionLabel.text = [Utils daysStringFromWeekdaysFrequency:[weekDaysFrequency componentsJoinedByString:@","]];
        cell.restrictionNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length == 0);
        cell.restrictionCenteredNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length > 0);
        cell.restrictionDescriptionLabel.textColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        
        return cell;
    }
    else if (indexPath.row == 4) {
        RestrictionsCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictionNameLabel.text = @"Hours";
        cell.restrictionCenteredNameLabel.text = @"Hours";
        cell.restrictionDescriptionLabel.text = [self.hourlyRestrictionDescriptions componentsJoinedByString:@"; "];
        cell.restrictionNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length == 0);
        cell.restrictionCenteredNameLabel.hidden = (cell.restrictionDescriptionLabel.text.length > 0);
        cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    
    if (indexPath.row == 0) {
        RestrictionsSwitchCell *cell = (RestrictionsSwitchCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        cell.restrictionEnabledSwitch.on = !cell.restrictionEnabledSwitch.on;
        
        self.wateringRestrictions.hotDaysExtraWatering = cell.restrictionEnabledSwitch.on;
        [self saveWateringRestrictions];
    }
    else if (indexPath.row == 1) {
        [self showFreezeProtectTemperaturePickerVC];
    }
    else if (indexPath.row == 2) {
        MonthsVC *monthsVC = [[MonthsVC alloc] init];
        monthsVC.selectedMonths = [self monthsFrequencyFromRawString:self.wateringRestrictions.noWaterInMonths];
        monthsVC.parent = self;
        monthsVC.viewTitle = @"Restricted Months";
        
        [self.navigationController pushViewController:monthsVC animated:YES];
    }
    else if (indexPath.row == 3) {
        WeekdaysVC *weekdaysVC = [[WeekdaysVC alloc] init];
        weekdaysVC.selectedWeekdays = [self weekDaysFrequencyFromRawString:self.wateringRestrictions.noWaterInWeekDays];
        weekdaysVC.parent = self;
        weekdaysVC.viewTitle = @"Restricted Days";
        
        [self.navigationController pushViewController:weekdaysVC animated:YES];
    }
    else if (indexPath.row == 4) {
        RestrictedHoursVC *restrictedHoursVC = [[RestrictedHoursVC alloc] init];
        restrictedHoursVC.hourlyRestrictions = self.hourlyRestrictions;
        restrictedHoursVC.parent = self;
        
        [self.navigationController pushViewController:restrictedHoursVC animated:YES];
    }
}

@end
