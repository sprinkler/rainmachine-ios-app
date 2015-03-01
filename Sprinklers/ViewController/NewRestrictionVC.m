
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
#import "API4StatusResponse.h"

@interface NewRestrictionVC ()

@property (nonatomic, readonly) NSString *fromTimeString;
@property (nonatomic, readonly) NSString *toTimeString;
@property (nonatomic, readonly) NSDate *fromTime;
@property (nonatomic, readonly) NSDate *toTime;

@property (nonatomic, assign) NSInteger selectedTimeCellIndex;
@property (nonatomic, assign) NSInteger selectedFrequencyIndex;
@property (nonatomic, assign) BOOL isNewRestriction;
@property (nonatomic, assign) BOOL didSave;

@property (nonatomic, strong) ServerProxy *createHourlyRestrictionServerProxy;
@property (nonatomic, strong) ServerProxy *deleteHourlyRestrictionServerProxy;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *discardBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolBar;

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
    
    self.isNewRestriction = (self.restriction == nil);

    self.selectedTimeCellIndex = -1;
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        self.discardBarButtonItem.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        self.saveBarButtonItem.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    }
    
    if (!self.restriction) {
        self.restriction = [HourlyRestriction restriction];
    }
    
    if (!self.showInitialUnsavedAlert) {
        // In the case when 'showInitialUnsavedAlert' is YES, restrictionCopyBeforeSave is set beforehand
        self.restrictionCopyBeforeSave = self.restriction;
    }
    self.selectedFrequencyIndex = ([self.restriction.weekDays isEqualToString:@"1111111"] ? 0 : 1);

    if (self.showInitialUnsavedAlert) {
        [self showUnsavedChangesPopup:nil];
        self.showInitialUnsavedAlert = NO;
    }

    [self refreshToolbar];
    
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCheckCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCheckCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if ([CCTBackButtonActionHelper sharedInstance].delegate) {
        // The back was done using back-swipe gesture
        if ([self hasUnsavedChanged]) {
            [self.parent setUnsavedRestriction:self.restriction withIndex:self.restrictionIndex];
        }
    }
}

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC {
    self.restriction.weekDays = [weekdaysVC.selectedWeekdays componentsJoinedByString:@""];
    [self refreshUI];
}

- (void)timePickerVCWillDissapear:(TimePickerVC*)timePicker {
    if (self.selectedTimeCellIndex == 0) {
        if (timePicker.hour24Format != self.fromHour || timePicker.minutes != self.fromMinutes) {
            self.restriction.interval = [NSString stringWithFormat:@"%d:%d - %d:%d", timePicker.hour24Format, timePicker.minutes, -1, -1];
        }
    }
    else if (self.selectedTimeCellIndex == 1) {
        NSDate *date1 = self.fromTime;
        NSDate *date2 = [self dateFromHour:timePicker.hour24Format minutes:timePicker.minutes];
        if ([date2 timeIntervalSinceDate:date1] < 0.0) {
            [self showNotValidTimeIntervalAlert];
            return;
        }
        
        self.restriction.interval = [NSString stringWithFormat:@"%d:%d - %d:%d", [self fromHour], [self fromMinutes], timePicker.hour24Format, timePicker.minutes];
    }
    
    [self refreshUI];
}

#pragma mark - Methods

- (BOOL)isNewAndUnsaved
{
    return (self.isNewRestriction) && (!self.didSave);
}

- (int)fromHour
{
    return [self extractIntervalPartWithIndex:0];
}

- (int)fromMinutes
{
    return [self extractIntervalPartWithIndex:1];
}

- (int)toHour
{
    return [self extractIntervalPartWithIndex:2];
}

- (int)toMinutes
{
    return [self extractIntervalPartWithIndex:3];
}

- (int)extractIntervalPartWithIndex:(int)intervalPart
{
    int intervalParts[4];

    sscanf([self.restriction.interval UTF8String], "%d:%d - %d:%d", intervalParts+0, intervalParts+1, intervalParts+2, intervalParts+3);
    
    return intervalParts[intervalPart];
}

- (NSArray*)weekdayArray
{
    if (self.selectedFrequencyIndex == 0) {
        return nil;
    }
    
    NSMutableArray *w = [NSMutableArray new];
    
    [self.restriction.weekDays enumerateSubstringsInRange:NSMakeRange(0, self.restriction.weekDays.length)
                                                  options:NSStringEnumerationByComposedCharacterSequences
                                               usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                                   // 3. Add them to a mutable set
                                                   [w addObject:substring];
                                               }];

    return w;
}

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

- (BOOL)didEdit
{
    if ([self isNewAndUnsaved]) {
        return YES;
    }
    return ![self.restrictionCopyBeforeSave isEqualToRestriction:self.restriction];
}

- (BOOL)hasUnsavedChanged
{
    if (self.restrictionCopyBeforeSave) {
        return ![self.restrictionCopyBeforeSave isEqualToRestriction:self.restriction];
    }
    
    return YES;
}

- (void)refreshUI
{
    [self refreshToolbar];
    [self.tableView reloadData];
}

- (void)refreshToolbar
{
    BOOL didEdit = [self didEdit];
   
    UIBarButtonItem* buttonDiscard = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* buttonSave = [[UIBarButtonItem alloc] initWithTitle:@"Save" style: didEdit ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered target:self action:@selector(onSave:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        buttonDiscard.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        
        if (didEdit) {
            buttonSave.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        }
        else
        {
            buttonSave.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        }
    }
    
    //set the toolbar buttons
    self.topToolBar.items = [NSArray arrayWithObjects:flexibleSpace, buttonDiscard, flexibleSpace, buttonSave, flexibleSpace, nil];
}

#pragma mark - Actions

- (void)onCell:(UITableViewCell*)cell checkmarkState:(BOOL)sel {
    RestrictionsCheckCell *restrictionsCheckCell = (RestrictionsCheckCell*)cell;
    restrictionsCheckCell.checkmarkButton.selected = YES;
    self.selectedFrequencyIndex = restrictionsCheckCell.uid;
    if (restrictionsCheckCell.uid == 0) self.restriction.weekDays = @"1111111";
    [self refreshUI];
}

- (IBAction)onDiscard:(id)sender {
    self.selectedTimeCellIndex = -1;
    
    self.restriction = self.restrictionCopyBeforeSave;
    self.selectedFrequencyIndex = ([self.restriction.weekDays isEqualToString:@"1111111"] ? 0 : 1);
    
    [self refreshUI];
}

- (IBAction)onSave:(id)sender {
    if (self.fromHour == -1 || self.fromMinutes == -1 || self.toHour == -1 || self.toMinutes == -1) {
        [self showNotValidTimeIntervalAlert];
        return;
    }
    
    self.restriction.dayStartMinute = [NSNumber numberWithInteger:self.fromHour * 60 + self.fromMinutes];
    self.restriction.minuteDuration = [NSNumber numberWithInteger:(self.toHour - self.fromHour) * 60 + self.toMinutes - self.fromMinutes];

    self.createHourlyRestrictionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.createHourlyRestrictionServerProxy createHourlyRestriction:self.restriction includeUID:NO];
    [self startHud:nil];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.createHourlyRestrictionServerProxy) {
        self.createHourlyRestrictionServerProxy = nil;
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
        
        // Delete the old restriction
        // Because of the sprinkler limitation, the editing is done using a create / delete sequence
        if (![self isNewAndUnsaved]) {
            [self deleteHourlyRestriction:self.restriction];
        }

        API4StatusResponse *theData = (API4StatusResponse*)data;
        HourlyRestriction *newRestriction = [ServerProxy fromJSON:theData.restriction toClass:NSStringFromClass([HourlyRestriction class])];

        self.restriction = newRestriction;
        self.restrictionCopyBeforeSave = newRestriction;
        
        self.didSave = YES;
        
        [self refreshToolbar];
    }
    else if (serverProxy == self.deleteHourlyRestrictionServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
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

- (void)deleteHourlyRestriction:(HourlyRestriction*)restriction {
    self.deleteHourlyRestrictionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.deleteHourlyRestrictionServerProxy deleteHourlyRestriction:restriction];
    [self startHud:nil];
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
        NSArray *weekdayComponents = [self weekdayArray];
        cell.restrictionDescriptionLabel.text = (indexPath.row == 0 ? nil : [Utils daysStringFromWeekdaysFrequency:[weekdayComponents componentsJoinedByString:@","]]);
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
        timePickerVC.timeFormat = [Utils timeIs24HourFormat] ? 0 : 1;
        timePickerVC.parent = self;
        timePickerVC.time = (indexPath.row == 0 ? self.fromTime : self.toTime);
        [timePickerVC refreshTimeFormatConstraint];
        
        [self willPushChildView];
        [self.navigationController pushViewController:timePickerVC animated:YES];
        
        timePickerVC.title = (indexPath.row == 0 ? @"From time" : @"To time");
        self.selectedTimeCellIndex = indexPath.row;
    } else if (indexPath.section == 1) {
        RestrictionsCheckCell *cell = (RestrictionsCheckCell*)[tableView cellForRowAtIndexPath:indexPath];
        
        if (indexPath.row == 1) {
            WeekdaysVC *weekdaysVC = [[WeekdaysVC alloc] init];
            weekdaysVC.selectedWeekdays = [[self weekdayArray] mutableCopy];
            weekdaysVC.parent = self;
            
            [cell onCheck:cell.checkmarkButton];
            
            [self willPushChildView];
            [self.navigationController pushViewController:weekdaysVC animated:YES];
        } else {
            [cell onCheck:cell.checkmarkButton];
        }
    }
}

#pragma mark - CCTBackButtonActionHelper delegate

- (BOOL)cct_navigationBar:(UINavigationBar *)navigationBar willPopItem:(UINavigationItem *)item {
    if ([self hasUnsavedChanged]) {
        
        [self showUnsavedChangesPopup:nil];
        
        return NO;
    }
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    return YES;
}

- (void)willPushChildView
{
    // This prevents the test from viewWillDisappear to pass
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)popWithoutQuestion
{
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showUnsavedChangesPopup:(id)notif
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Leave screen?"
                                                        message:@"There are unsaved changes"
                                                       delegate:self
                                              cancelButtonTitle:@"Leave screen"
                                              otherButtonTitles:@"Stay", nil];
    alertView.tag = kAlertView_UnsavedChanges;
    [alertView show];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_UnsavedChanges) {
        if (theAlertView.cancelButtonIndex == buttonIndex) {
            [self popWithoutQuestion];
        }
    }
}

@end
