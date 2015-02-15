//
//  ProvisionDateAndTimeManualVCTableViewController.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ProvisionDateAndTimeManualVC.h"
#import "ProvisionTimezonesListVC.h"
#import "+NSDate.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "SettingsDate.h"
#import "AppDelegate.h"
#import "DevicesVC.h"

#define kPickerAnimationDuration    0.40   // duration for the animation to slide the date picker into view
#define kDatePickerTag              99     // view tag identifiying the date picker view

#define kTitleKey       @"title"   // key for obtaining the data source item's title
#define kDateKey        @"date"    // key for obtaining the data source item's date value

// keep track of which rows have date cells

static NSString *kDateCellID = @"dateCell";     // the cells with the start or end date
static NSString *kDatePickerID = @"datePicker"; // the cell containing the date picker
static NSString *kTimeZoneCell = @"timeZoneCell";     // the remaining cells at the end

@interface ProvisionDateAndTimeManualVC ()

@property (strong, nonatomic) ServerProxy *provisionTimezoneServerProxy;
@property (strong, nonatomic) ServerProxy *provisionDateTimeServerProxy;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) ProvisionDateAndTimeManualVC *provisionDateAndTimeManualVC;

@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

// keep track which indexPath points to the cell with UIDatePicker
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@property (assign) NSInteger pickerCellRowHeight;

@property (nonatomic, strong) IBOutlet UIDatePicker *pickerView;

// this button appears only when the date picker is shown (iOS 6.1.x or earlier)
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation ProvisionDateAndTimeManualVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Date and Time";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(onNext:)];

    self.timeZoneName = [[NSTimeZone localTimeZone] name];
    
    NSMutableDictionary *itemOne = [@{ kTitleKey : @"Date and Time",
                                       kDateKey : [NSDate date] } mutableCopy];
    NSMutableDictionary *itemTwo = [@{ kTitleKey : @"TimeZone" } mutableCopy];
    self.dataArray = @[itemOne, itemTwo];
    
//    self.dateFormatter = [[NSDateFormatter alloc] init];
//    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];    // show short-style date format
//    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateFormatter = [NSDate getDateFormaterFixedFormatParsing];
    [self.dateFormatter setAMSymbol:@"AM"];
    [self.dateFormatter setPMSymbol:@"PM"];
    [self.dateFormatter setDateFormat:@"MM/dd/yy hh:mm a"];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ProvisionDatePickerCell" bundle:nil] forCellReuseIdentifier:kDatePickerID];
    
    // obtain the picker view cell's height, works because the cell was pre-defined in our storyboard
    UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier:kDatePickerID];
    
    self.pickerCellRowHeight = CGRectGetHeight(pickerViewCellToCheck.frame);
    
    self.errorHandlingHelper = [BaseModalProvisionVC new];
    [self.errorHandlingHelper setWizardNavBarForVC:self];
    self.errorHandlingHelper.delegate = self;
    
    // if the local changes while in the background, we need to be notified so we can update the date
    // format in the table view cells
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localeChanged:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
}

- (int)dateRowIndex
{
    return 0;
}

- (int)timezoneRowIndex
{
    if ([self hasInlineDatePicker]) {
        return 2;
    }
    
    return 1;
}

#pragma mark - Locale

/*! Responds to region format or locale changes.
 */
- (void)localeChanged:(NSNotification *)notif
{
    // the user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    [self.tableView reloadData];
}


#pragma mark - Utilities

/*! Returns the major version of iOS, (i.e. for iOS 6.1.3 it returns 6)
 */
NSUInteger DeviceSystemMajorVersion()
{
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _deviceSystemMajorVersion =
        [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] integerValue];
    });
    
    return _deviceSystemMajorVersion;
}

#define EMBEDDED_DATE_PICKER (DeviceSystemMajorVersion() >= 7)

/*! Determines if the given indexPath has a cell below it with a UIDatePicker.
 
 @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
 */
- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell =
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:0]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:kDatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}

/*! Updates the UIDatePicker's value to match with the date of the cell above it.
 */
- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:kDatePickerTag];
        if (targetedDatePicker != nil)
        {
            // we found a UIDatePicker in this cell, so update it's date value
            //
            NSDictionary *itemData = self.dataArray[self.datePickerIndexPath.row - 1];
            [targetedDatePicker setDate:[itemData valueForKey:kDateKey] animated:NO];
        }
    }
}

/*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
 */
- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}

/*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
 
 @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
 */
- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}

/*! Determines if the given indexPath points to a cell that contains the start/end dates.
 
 @param indexPath The indexPath to check if it represents start/end date cell.
 */
- (BOOL)indexPathHasDate:(NSIndexPath *)indexPath
{
    BOOL hasDate = NO;
    
    if (indexPath.row == [self dateRowIndex])
//        ||
//        ([self hasInlineDatePicker]))
    {
        hasDate = YES;
    }
    
    return hasDate;
}

- (BOOL)indexPathHasTimeZone:(NSIndexPath *)indexPath
{
    return (indexPath.row == [self timezoneRowIndex]);
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self indexPathHasPicker:indexPath] ? self.pickerCellRowHeight : self.tableView.rowHeight);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasInlineDatePicker])
    {
        // we have a date picker, so allow for it in the number of rows in this section
        NSInteger numRows = self.dataArray.count;
        return ++numRows;
    }
    
    return self.dataArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Rain Machine Internet Time";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSString *cellID = kTimeZoneCell;
    
    if ([self indexPathHasPicker:indexPath])
    {
        // the indexPath is the one containing the inline date picker
        cellID = kDatePickerID;     // the current/opened date picker cell
    }
    else if ([self indexPathHasDate:indexPath])
    {
        // the indexPath is one that contains the date information
        cellID = kDateCellID;       // the start/end date cells
    }
    else if ([self indexPathHasTimeZone:indexPath])
    {
        cellID = kTimeZoneCell;
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        if ([cellID isEqualToString:kDateCellID]) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        }
        else if ([cellID isEqualToString:kTimeZoneCell]) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        }
    }
    
    if([cellID isEqualToString:kDatePickerID]) {
        UIDatePicker *datePicker = (UIDatePicker*)[cell viewWithTag:1];
        [datePicker addTarget:self action:@selector(dateAction:) forControlEvents:UIControlEventValueChanged];
    }

//    if (indexPath.row == 0)
//    {
//        // we decide here that first cell in the table is not selectable (it's just an indicator)
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    }
    
    // if we have a date picker open whose cell is above the cell we want to update,
    // then we have one more cell than the model allows
    //
    NSInteger modelRow = indexPath.row;
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.row <= indexPath.row)
    {
        modelRow--;
    }
    
    NSDictionary *itemData = self.dataArray[modelRow];
    
    // proceed to configure our cell
    if ([cellID isEqualToString:kDateCellID])
    {
        // we have either start or end date cells, populate their date field
        //
        cell.textLabel.text = [itemData valueForKey:kTitleKey];
        cell.detailTextLabel.text = [self.dateFormatter stringFromDate:[itemData valueForKey:kDateKey]];
    }
    else if ([cellID isEqualToString:kTimeZoneCell])
    {
        // this cell is a non-date cell, just assign it's text label
        //
        cell.textLabel.text = [itemData valueForKey:kTitleKey];
        cell.detailTextLabel.text = self.timeZoneName;
    }
    
    return cell;
}

/*! Adds or removes a UIDatePicker cell below the given indexPath.
 
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
    
    // check if 'indexPath' has an attached date picker below it
    if ([self hasPickerForIndexPath:indexPath])
    {
        // found a picker below it, so remove it
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        // didn't find a picker below it, so we should insert it
        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

/*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
 
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the date picker inline with the table content
    [self.tableView beginUpdates];
    
    BOOL before = NO;   // indicates if the date picker is below "indexPath", help us determine which row to reveal
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row);
    
    // remove any date picker cell if it exists
    if ([self hasInlineDatePicker])
    {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:0]]
                              withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        // hide the old date picker and display the new one
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:0];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:0];
    }
    
    // always deselect the row containing the start or end date
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    
    // inform our date picker of the current date to match the current cell
    [self updateDatePicker];
}

/*! Reveals the UIDatePicker as an external slide-in view, iOS 6.1.x and earlier, called by "didSelectRowAtIndexPath".
 
 @param indexPath The indexPath used to display the UIDatePicker.
 */
- (void)displayExternalDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // first update the date picker's date value according to our model
    NSDictionary *itemData = self.dataArray[indexPath.row];
    [self.pickerView setDate:[itemData valueForKey:kDateKey] animated:YES];
    
    // the date picker might already be showing, so don't add it to our view
    if (self.pickerView.superview == nil)
    {
        CGRect startFrame = self.pickerView.frame;
        CGRect endFrame = self.pickerView.frame;
        
        // the start position is below the bottom of the visible frame
        startFrame.origin.y = CGRectGetHeight(self.view.frame);
        
        // the end position is slid up by the height of the view
        endFrame.origin.y = startFrame.origin.y - CGRectGetHeight(endFrame);
        
        self.pickerView.frame = startFrame;
        
        [self.view addSubview:self.pickerView];
        
        // animate the date picker into view
        [UIView animateWithDuration:kPickerAnimationDuration animations: ^{ self.pickerView.frame = endFrame; }
                         completion:^(BOOL finished) {
                             // add the "Done" button to the nav bar
                             self.navigationItem.rightBarButtonItem = self.doneButton;
                         }];
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == kDateCellID)
    {
        if (EMBEDDED_DATE_PICKER)
            [self displayInlineDatePickerForRowAtIndexPath:indexPath];
        else
            [self displayExternalDatePickerForRowAtIndexPath:indexPath];
    }
    else
    {
        if (cell.reuseIdentifier == kTimeZoneCell) {
            ProvisionTimezonesListVC *timezonesListVC = [[ProvisionTimezonesListVC alloc] init];
            timezonesListVC.delegate = self;
            UINavigationController *navDevices = [[UINavigationController alloc] initWithRootViewController:timezonesListVC];
            [self.navigationController presentViewController:navDevices animated:YES completion:nil];
//            [self.navigationController pushViewController:timezonesListVC animated:YES];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}


#pragma mark - Actions

/*! User chose to change the date by changing the values inside the UIDatePicker.
 
 @param sender The sender for this action: UIDatePicker.
 */
- (IBAction)dateAction:(id)sender
{
    NSIndexPath *targetedCellIndexPath = nil;
    
    if ([self hasInlineDatePicker])
    {
        // inline date picker: update the cell's date "above" the date picker cell
        //
        targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:0];
    }
    else
    {
        // external date picker: update the current "selected" cell's date
        targetedCellIndexPath = [self.tableView indexPathForSelectedRow];
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:targetedCellIndexPath];
    UIDatePicker *targetedDatePicker = sender;
    
    // update our data model
    NSMutableDictionary *itemData = self.dataArray[targetedCellIndexPath.row];
    [itemData setValue:targetedDatePicker.date forKey:kDateKey];
    
    // update the cell's date string
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:targetedDatePicker.date];
}


/*! User chose to finish using the UIDatePicker by pressing the "Done" button
 (used only for "non-inline" date picker, iOS 6.1.x or earlier)
 
 @param sender The sender for this action: The "Done" UIBarButtonItem
 */
- (IBAction)doneAction:(id)sender
{
    CGRect pickerFrame = self.pickerView.frame;
    pickerFrame.origin.y = CGRectGetHeight(self.view.frame);
    
    // animate the date picker out of view
    [UIView animateWithDuration:kPickerAnimationDuration animations: ^{ self.pickerView.frame = pickerFrame; }
                     completion:^(BOOL finished) {
                         [self.pickerView removeFromSuperview];
                     }];
    
    // remove the "Done" button in the navigation bar
    self.navigationItem.rightBarButtonItem = nil;
    
    // deselect the current table cell
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)onNext:(id)sender
{
    // self.selectedLocationAddress contains the selected location
    // self.selectedLocationElevation.elevation contains the elevation of the selected location
    // self.selectedLocationTimezone.timeZoneId contains the timezone of the selected location
    self.provisionTimezoneServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
    [self.provisionTimezoneServerProxy setTimezone:self.timeZoneName];
    [self showHud];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.devicesVC deviceSetupFinished];

    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.errorHandlingHelper handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.provisionTimezoneServerProxy) {
    }
    
    [self hideHud];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    
    if (serverProxy == self.provisionDateTimeServerProxy) {
        [self hideHud];

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Your Rain Machine is set up!" message:@"Now you can go ahead and create your first program." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }

    if (serverProxy == self.provisionTimezoneServerProxy) {
        //    TODO: handle error code

        SettingsDate *settingsDate = [SettingsDate new];
        settingsDate.time_format = @24;
        settingsDate.appDate = [self stringFromDate:[self constructDateFromPicker]];
        self.provisionDateTimeServerProxy = [[ServerProxy alloc] initWithServerURL:self.sprinkler.url delegate:self jsonRequest:YES];
        [self.provisionDateTimeServerProxy setSettingsDate:settingsDate];
    }
    
    [self hideHud];
}

- (void)loggedOut {
    
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login error" message:@"Authentication failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showHud {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.view.userInteractionEnabled = NO;
}

- (void)hideHud {
    self.hud = nil;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.view.userInteractionEnabled = YES;
}

- (void)timeZoneSelected:(NSString*)timezone
{
    self.timeZoneName = timezone;
}

- (NSString*)stringFromDate:(NSDate*)date
{
    return [[self dateFormatterWithTimeFormat:24] stringFromDate:date];
}

- (NSDate*)constructDateFromPicker
{
    NSDate *date = self.dataArray[0][kDateKey];
    NSCalendar* timeCal = [NSCalendar currentCalendar];
    NSDateComponents* timeComp = [timeCal components:(
                                                      NSHourCalendarUnit |
                                                      NSMinuteCalendarUnit
                                                      )
                                            fromDate:date];
    
    NSCalendar* dateCal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [dateCal components:(
                                                      NSMonthCalendarUnit |
                                                      NSYearCalendarUnit |
                                                      NSDayCalendarUnit
                                                      )
                                            fromDate:date];
    
    dateComp.hour = timeComp.hour;
    dateComp.minute = timeComp.minute;
    
    return [dateCal dateFromComponents:dateComp];
}

- (NSDateFormatter*)dateFormatterWithTimeFormat:(int)timeFormat
{
    NSDateFormatter *df = [NSDate getDateFormaterFixedFormatParsing];
    
    // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
    if (timeFormat == 24) {
        if ([ServerProxy usesAPI4]) df.dateFormat = [ServerProxy usesAPI3] ? @"yyyy-M-d H:m:s" : @"yyyy-M-d H:m";
        else df.dateFormat = @"yyyy/M/d H:m"; // H means hours between [0-23]
    }
    else if (timeFormat == 12) {
        if ([ServerProxy usesAPI4]) df.dateFormat = [ServerProxy usesAPI3] ? @"yyyy-M-d K:m:s a" : @"yyyy-M-d K:m a";
        else df.dateFormat = @"yyyy/M/d K:m a"; // K means hours between [0-11]
    }
    
    return df;
}

@end

