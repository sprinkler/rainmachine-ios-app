//
//  DailyProgramVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramVC.h"
#import "BaseLevel2ViewController.h"
#import "Program.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "ButtonCell.h"
#import "ProgramCellType1.h"
#import "ProgramCellType2.h"
#import "ProgramCellType3.h"
#import "ProgramCellType4.h"
#import "ProgramCellType5.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"
#import "+NSString.h"
#import "ServerResponse.h"
#import "ProgramsVC.h"
#import "ProgramWateringTimes.h"
#import "WeekdaysVC.h"
#import "SetDelayVC.h"
#import "TimePickerVC.h"
#import "+UIDevice.h"
#import "StartStopProgramResponse.h"

#define kAlertViewTag_InvalidProgram 1
#define kAlertViewTag_UnsavedChanges 2

@interface ProgramVC ()
{
    MBProgressHUD *hud;
    BOOL setRunNowActivityIndicator;
    BOOL runNowButtonEnabledState;
    BOOL resignKeyboard;
    
    BOOL isNewProgram;
    
    int runNowSectionIndex;
    int nameSectionIndex;
    int activeSectionIndex;
    int ignoreWeatherDataSectionIndex;
    int frequencySectionIndex;
    int startTimeSectionIndex;
    int cycleSoakAndStationDelaySectionIndex;
    int wateringTimesSectionIndex;
}

@property (strong, nonatomic) ServerProxy *getProgramListServerProxy;
@property (strong, nonatomic) ServerProxy *runNowServerProxy;
@property (strong, nonatomic) ServerProxy *postSaveServerProxy;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *frequencyEveryXDays;
@property (strong, nonatomic) NSString *frequencyWeekdays;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;

@end

@implementation ProgramVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Program";
    
    isNewProgram = (self.program == nil);
    
    if (!self.showInitialUnsavedAlert) {
        // In the case when 'showInitialUnsavedAlert' is YES, programCopyBeforeSave is set beforehand
        self.programCopyBeforeSave = self.program;
    }
    
    if (self.program) {
        runNowSectionIndex = -1;
        nameSectionIndex = 0;
        activeSectionIndex = 1;
        ignoreWeatherDataSectionIndex = 2;
        frequencySectionIndex = 3;
        startTimeSectionIndex = 4;
        cycleSoakAndStationDelaySectionIndex = 5;
        wateringTimesSectionIndex = 6;
        
        if ((![Utils isDevice357Plus]) && ([self.program.state isEqualToString:@"stopped"])) {
            // 3.55 and 3.56 can only Stop programs
            [self createTwoButtonToolbar];
        }
    } else {
        runNowSectionIndex = -1;
        nameSectionIndex = 0;
        activeSectionIndex = 1;
        ignoreWeatherDataSectionIndex = 2;
        frequencySectionIndex = 3;
        startTimeSectionIndex = 4;
        cycleSoakAndStationDelaySectionIndex = 5;
        wateringTimesSectionIndex = 6;
    
        [self createTwoButtonToolbar];
    }
    
    [self refreshToolBarButtonTitles];
    
    if (!self.program) {
        self.program = [Program program];
        self.program.timeFormat = [self.parent serverTimeFormat];
    }
    
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType1" bundle:nil] forCellReuseIdentifier:@"ProgramCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType2" bundle:nil] forCellReuseIdentifier:@"ProgramCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType3" bundle:nil] forCellReuseIdentifier:@"ProgramCellType3"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType4" bundle:nil] forCellReuseIdentifier:@"ProgramCellType4"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType5" bundle:nil] forCellReuseIdentifier:@"ProgramCellType5"];
    [_tableView registerNib:[UINib nibWithNibName:@"ButtonCell" bundle:nil] forCellReuseIdentifier:@"ButtonCell"];

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];

    if ([self.program.weekdays containsString:@"INT"]) {
        self.frequencyEveryXDays = self.program.weekdays;
    } else {
        self.frequencyEveryXDays = @"INT 2"; // Default value
    }
    
    if ([self.program.weekdays containsString:@","]) {
        self.frequencyWeekdays = self.program.weekdays;
    } else {
        self.frequencyWeekdays = @"0,0,0,0,0,0,0";
    }
    
    if (self.showInitialUnsavedAlert) {
        [self showUnsavedChangesPopup:nil];
        self.showInitialUnsavedAlert = NO;
    }
}

- (void)refreshToolBarButtonTitles
{
    self.startButtonItem.title = [self.program.state isEqualToString:@"stopped"] ? @"Start" : @"Stop";
}

- (void)createTwoButtonToolbar
{
    UIBarButtonItem* buttonDiscard = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* buttonSave = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(onSave:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        buttonDiscard.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        buttonSave.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
    }
    
    //set the toolbar buttons
    self.topToolbar.items = [NSArray arrayWithObjects:flexibleSpace, buttonDiscard, flexibleSpace, buttonSave, flexibleSpace, nil];
    self.startButtonItem = nil;
}

- (void)createThreeButtonToolbar
{
    UIBarButtonItem* buttonDiscard = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* buttonSave = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(onSave:)];
    UIBarButtonItem* buttonStart = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStyleDone target:self action:@selector(onStartOrStop:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        buttonDiscard.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        buttonSave.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        buttonStart.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
    }
    
    //set the toolbar buttons
    self.topToolbar.items = [NSArray arrayWithObjects:flexibleSpace, buttonDiscard, flexibleSpace, buttonSave, flexibleSpace, buttonStart, flexibleSpace, nil];
    self.startButtonItem = buttonStart;
}

- (void)willPushChildView
{
    // This prevents the test from viewWillDisappear to pass
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([CCTBackButtonActionHelper sharedInstance].delegate) {
        // The back was done using back-swipe gesture
        if ([self hasUnsavedChanged]) {
            [self.parent setUnsavedProgram:self.program withIndex:self.programIndex];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
}

- (void)updateRunNowButtonActiveStateTo:(BOOL)state setActivityIndicator:(BOOL)setActivityIndicator
{
//    setRunNowActivityIndicator = setActivityIndicator;
//    runNowButtonEnabledState = state;

    if (setActivityIndicator) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
    self.startButtonItem.enabled = state;
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
    NSString *invalidProgramStateMessage = [self checkProgramValidity];
    
    if (invalidProgramStateMessage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot save program"
                                                            message:invalidProgramStateMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = kAlertViewTag_InvalidProgram;
        [alertView show];
    } else {
        if (!self.postSaveServerProxy) {
            self.postSaveServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
            [self.postSaveServerProxy saveProgram:self.program];
            
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
}

- (void)popWithoutQuestion
{
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDiscard:(id)sender {
    self.program = self.programCopyBeforeSave;
    [self.tableView reloadData];
}

- (IBAction)onStartOrStop:(id)sender {
    self.runNowServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    [self.runNowServerProxy runNowProgram:self.program];
    
    [self updateRunNowButtonActiveStateTo:NO setActivityIndicator:YES];
//    self.program.state = @"running";
    
//    [self.tableView reloadData];
}

// onRunNow
- (void)onCellButton
{
}

- (void)onCellSwitch:(id)object
{
    if ([object isKindOfClass:[ProgramCellType5 class]]) {
        ProgramCellType5 *cell = (ProgramCellType5*)object;
        if (cell.cycleAndSoak) {
            if ((cell.theSwitch.on) && ((self.program.cycles == 0) && (self.program.soak == 0)) ) {
                [self showSection4Screen:0];
            } else {
                self.program.csOn = cell.theSwitch.on;
            }
        } else {
            if ((cell.theSwitch.on) && ((self.program.delay == 0)) ) {
                [self showSection4Screen:1];
            } else {
                self.program.delayOn = cell.theSwitch.on;
            }
        }
    }
    else if ([object isKindOfClass:[ProgramCellType2 class]]) {
        ProgramCellType2 *cell = (ProgramCellType2*)object;
        if (cell.ignoreWeatherDataCellType) {
            self.program.ignoreWeatherData = cell.theSwitch.on;
        } else {
            self.program.active = cell.theSwitch.on;
        }
    }
}

- (void)onCell:(UITableViewCell*)theCell checkmarkState:(BOOL)sel
{
    ProgramCellType3 *cell = (ProgramCellType3*)theCell;
    
    [self checkFrequencyWithIndex:cell.index];
    
    [self.tableView reloadData];
}

- (void)cellTextFieldChanged:(NSString*)text
{
    self.program.name = text;
}

- (void)save
{
}

- (void)setDelayVCOver:(SetDelayVC*)setDelayVC
{
    if ([setDelayVC.userInfo isKindOfClass:[NSString class]]) {
        if ([setDelayVC.userInfo isEqualToString:@"cycle_and_soak"]) {
            self.program.cycles = setDelayVC.valuePicker1;
            self.program.soak = setDelayVC.valuePicker2;
            self.program.csOn = !((_program.cycles == 0) && (_program.soak == 0));
//            if (self.program.csOn) {
//                [self requestCycleAndSoakServerProxyWithProgramId:_program.programId cycles:_program.cycles soak:_program.soak cs_on:_program.csOn];
//            }
        } else if ([setDelayVC.userInfo isEqualToString:@"station_delay"]) {
            self.program.delay = setDelayVC.valuePicker1;
            self.program.delayOn = !((_program.delay == 0));
//            if (self.program.delayOn) {
//                [self requestStationDelay:_program.programId delay:_program.delay delay_on:_program.delayOn];
//            }
        } else if ([setDelayVC.userInfo isEqualToString:@"interval_frequency"]) {
            self.frequencyEveryXDays = [NSString stringWithFormat:@"INT %d", setDelayVC.valuePicker1];
            self.program.weekdays = self.frequencyEveryXDays;
            }
    } else if ([setDelayVC.userInfo isKindOfClass:[NSDictionary class]]) {
        NSString *name = [setDelayVC.userInfo objectForKey:@"name"];
         if ([name isEqualToString:@"zoneDelay"]) {
             NSNumber *zoneId = [setDelayVC.userInfo objectForKey:@"zoneId"];
             ProgramWateringTimes *programWateringTime = self.program.wateringTimes[[zoneId intValue]];
             programWateringTime.minutes = setDelayVC.valuePicker1;
         }
    }
    
    [self.tableView reloadData];
}

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC
{
    self.frequencyWeekdays = [weekdaysVC.selectedWeekdays componentsJoinedByString:@","];
    self.program.weekdays = self.frequencyWeekdays;
    
    [self.tableView reloadData];
}

- (void)timePickerVCWillDissapear:(TimePickerVC*)timePickerVCC
{
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [cal components:(
                                                  NSDayCalendarUnit |
                                                  NSMonthCalendarUnit |
                                                  NSYearCalendarUnit
                                                  )
                                        fromDate:self.program.startTime];
    
    dateComp.hour = [timePickerVCC hour24Format];
    dateComp.minute = [timePickerVCC minutes];
    
    self.program.startTime = [cal dateFromComponents:dateComp];
    [self.tableView reloadData];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return wateringTimesSectionIndex + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == nameSectionIndex) {
        return @"Name";
    }
    else if (section == frequencySectionIndex) {
        return @"Frequency";
    }
    else if (section == wateringTimesSectionIndex) {
        if ([self.program.wateringTimes count] > 0 ) {
            return @"Watering Time";
        }
    }
    return nil;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == frequencySectionIndex) {
//        return 34.0;
//    }
//    else if (section == wateringTimesSectionIndex) {
//        return 34.0;
//    }
//    return 22.0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == runNowSectionIndex) {
        return 1;
    }
    else if (section == nameSectionIndex) {
        return 1;
    }
    else if (section == activeSectionIndex) {
        return 1;
    }
    else if (section == ignoreWeatherDataSectionIndex) {
        return 1;
    }
    else if (section == frequencySectionIndex) {
        return 5;
    }
    else if (section == startTimeSectionIndex) {
        return 1;
    }
    else if (section == cycleSoakAndStationDelaySectionIndex) {
        return 2;
    }
    else if (section == wateringTimesSectionIndex) {
        return self.program.wateringTimes.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == runNowSectionIndex) {
        return 60;
    }
    else if (indexPath.section == nameSectionIndex) {
        return 54;
    }
    else if (indexPath.section == activeSectionIndex) {
        return 54;
    }
    else if (indexPath.section == ignoreWeatherDataSectionIndex) {
        return 54;
    }
    else if (indexPath.section == frequencySectionIndex) {
        return 48;
    }
    else if (indexPath.section == cycleSoakAndStationDelaySectionIndex) {
        return 54;
    }
    else if (indexPath.section == wateringTimesSectionIndex) {
        return 48;
    }
    
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == runNowSectionIndex) {
        static NSString *CellIdentifier = @"ButtonCell";
        ButtonCell *cell = (ButtonCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        BOOL isStopped = [self.program.state isEqualToString:@"stopped"];
        [cell.button setCustomBackgroundColorFromComponents:isStopped ? kSprinklerBlueColor : kWateringRedButtonColor];
        [cell.button setTitle:isStopped ? @"Run Now" : @"Stop" forState:UIControlStateNormal];
        
        if (setRunNowActivityIndicator) {
            cell.buttonActivityIndicator.hidden = runNowButtonEnabledState;
        }
        cell.button.enabled = runNowButtonEnabledState;
        cell.button.alpha = runNowButtonEnabledState ? 1 : 0.66;
        
        return cell;
    }
    else if (indexPath.section == nameSectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType1";
        ProgramCellType1 *cell = (ProgramCellType1*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            cell.theTextField.tintColor = [UIColor blackColor];
        }
        cell.theTextField.enabled = [Utils isDevice357Plus];
        cell.theTextField.text = self.program.name;
        cell.delegate = self;
        if (resignKeyboard) {
            [cell.theTextField resignFirstResponder];
        }
        return cell;
    }
    else if (indexPath.section == activeSectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType2";
        ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.theSwitch.on = self.program.active;
        cell.theTextLabel.text = @"Active";
        cell.theDetailLabel.text = nil;
        cell.delegate = self;
        cell.ignoreWeatherDataCellType = NO;
        return cell;
    }
    else if (indexPath.section == ignoreWeatherDataSectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType2";
        ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.theSwitch.on = self.program.ignoreWeatherData;
        cell.theTextLabel.text = @"Ignore weather data";
        cell.theDetailLabel.text = nil;
        cell.delegate = self;
        cell.ignoreWeatherDataCellType = YES;
        return cell;
    }
    else if (indexPath.section == frequencySectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType3";
        ProgramCellType3 *cell = (ProgramCellType3*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.theCenteredTextLabel.hidden = NO;
        cell.theTextLabel.hidden = YES;
        cell.theDetailTextLabel.hidden = YES;
        
        BOOL check = NO;
        if (indexPath.row == 0) {
            check = [self.program.weekdays isEqualToString:@"D"];
            cell.theCenteredTextLabel.text = @"Daily";
            cell.index = 0;
        }
        else if (indexPath.row == 1) {
            check = [self.program.weekdays isEqualToString:@"ODD"];
            cell.theCenteredTextLabel.text = @"Odd days";
            cell.index = 1;
        }
        else if (indexPath.row == 2) {
            check = [self.program.weekdays isEqualToString:@"EVD"];
            cell.theCenteredTextLabel.text = @"Even days";
            cell.index = 2;
        }
        else if (indexPath.row == 3) {
            check = [self.program.weekdays containsString:@"INT"];
            int nrDays;
            sscanf([self.frequencyEveryXDays UTF8String], "INT %d", &nrDays);
            cell.theCenteredTextLabel.text = [NSString stringWithFormat:@"Every %d days", nrDays];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.index = 3;
        }
        else if (indexPath.row == 4) {
            check = [self.program.weekdays containsString:@","];
            cell.theTextLabel.text = @"Weekdays";
            cell.theCenteredTextLabel.text = @"Weekdays";
            cell.theDetailTextLabel.text = [Utils daysStringFromWeekdaysFrequency:self.frequencyWeekdays];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if ([cell.theDetailTextLabel.text length] > 0) {
                cell.theCenteredTextLabel.hidden = YES;
                cell.theTextLabel.hidden = NO;
                cell.theDetailTextLabel.hidden = NO;
            }
            cell.index = 4;
        }

        cell.checkmark.selected = check;
        
        return cell;
    }
    
    else if (indexPath.section == startTimeSectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType4";
        ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSString *startHourAndMinute = [Utils formattedTime:_program.startTime forTimeFormat:_program.timeFormat];
        cell.theTextLabel.text = @"START TIME";
        cell.timeLabel.text = startHourAndMinute;
        cell.timeLabel.textColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
        return cell;
    }

    else if (indexPath.section == cycleSoakAndStationDelaySectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType5";
        ProgramCellType5 *cell = (ProgramCellType5*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        if (indexPath.row == 0) {
            cell.theSwitch.on = self.program.csOn;
            cell.theTextLabel.text = @"Cycle & Soak";
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d cycles / %d min soak", self.program.cycles, self.program.soak];
            cell.cycleAndSoak = YES;
        }
        else if (indexPath.row == 1) {
            cell.theSwitch.on = self.program.delayOn;
            cell.theTextLabel.text = @"Station Delay";
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d min", self.program.delay];
            cell.cycleAndSoak = NO;
        }
        if (!cell.theActivityIndicator.hidden) {
            [cell.theActivityIndicator startAnimating];
        } else {
            [cell.theActivityIndicator stopAnimating];
        }
        return cell;
    }
    
    else if (indexPath.section == wateringTimesSectionIndex) {
        static NSString *CellIdentifier = @"ProgramCellType4";
        ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
        cell.theTextLabel.text = [Utils fixedZoneName:programWateringTime.name withId:[NSNumber numberWithInt:programWateringTime.wtId]];
        cell.timeLabel.text = [NSString stringWithFormat:@"%d min", programWateringTime.minutes];
        cell.timeLabel.textColor = [UIColor blackColor];
        return cell;
    }
    
    return nil;
}

- (void)showSection4Screen:(int)row
{
    SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
    if (row == 0) {
        setDelayVC.minValuePicker1 = 2;
        setDelayVC.maxValuePicker1 = 5;
        setDelayVC.minValuePicker2 = 0;
        setDelayVC.maxValuePicker2 = 300;
        setDelayVC.userInfo = @"cycle_and_soak";
        setDelayVC.titlePicker1 = @"Cycles";
        setDelayVC.titlePicker2 = @"Soak time";
        setDelayVC.valuePicker1 = self.program.cycles;
        setDelayVC.valuePicker2 = self.program.soak;
        setDelayVC.title = @"Cycles and soak duration";
    }
    else if (row == 1) {
        setDelayVC.minValuePicker1 = 0;
        setDelayVC.maxValuePicker1 = 300;
        setDelayVC.userInfo = @"station_delay";
        setDelayVC.titlePicker1 = @"minutes";
        setDelayVC.valuePicker1 = self.program.delay;
        setDelayVC.title = @"Station delay duration";
    }
    
    setDelayVC.parent = self;
    
    [self willPushChildView];
    [self.navigationController pushViewController:setDelayVC animated:YES];
}

- (void)checkFrequencyWithIndex:(int)index
{
    if (index == 0) {
        self.program.weekdays = @"D";
    }
    else if (index == 1) {
        self.program.weekdays = @"ODD";
    }
    else if (index == 2) {
        self.program.weekdays = @"EVD";
    }
    else if (index == 3) {
        self.program.weekdays = _frequencyEveryXDays;
    }
    else if (index == 4) {
        self.program.weekdays = _frequencyWeekdays;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == nameSectionIndex) {
        ProgramCellType1 *cell = (ProgramCellType1 *)[tableView cellForRowAtIndexPath:indexPath];
        [cell.theTextField becomeFirstResponder];
    }
    else if (indexPath.section == activeSectionIndex) {
        ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.theSwitch.on = !cell.theSwitch.on;
        self.program.active = cell.theSwitch.on;
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.25];
    }
    else if (indexPath.section == ignoreWeatherDataSectionIndex) {
        ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.theSwitch.on = !cell.theSwitch.on;
        self.program.ignoreWeatherData = cell.theSwitch.on;
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.25];
    }
    else if (indexPath.section == frequencySectionIndex) {
        [self checkFrequencyWithIndex:(int)indexPath.row];
        if (indexPath.row == 3) {
            int nrDays;
            sscanf([self.frequencyEveryXDays UTF8String], "INT %d", &nrDays);

            SetDelayVC *setIntervalFrequencyVC = [[SetDelayVC alloc] init];
            setIntervalFrequencyVC.parent = self;
            setIntervalFrequencyVC.userInfo = @"interval_frequency";
            setIntervalFrequencyVC.titlePicker1 = @"days";
            setIntervalFrequencyVC.valuePicker1 = nrDays;
            setIntervalFrequencyVC.title = @"Set days frequency";

            [self willPushChildView];
            [self.navigationController pushViewController:setIntervalFrequencyVC animated:YES];
        }
        else if (indexPath.row == 4) {
            WeekdaysVC *weekdaysVC = [[WeekdaysVC alloc] init];
            weekdaysVC.selectedWeekdays = [[_program.weekdays componentsSeparatedByString:@","] mutableCopy];
            weekdaysVC.parent = self;

            [self willPushChildView];
            [self.navigationController pushViewController:weekdaysVC animated:YES];
        }

    }
    else if (indexPath.section == startTimeSectionIndex) {
        if (indexPath.row == 0) {

            TimePickerVC *timePickerVC = [[TimePickerVC alloc] initWithNibName:@"TimePickerVC" bundle:nil];
            timePickerVC.timeFormat = self.program.timeFormat;
            timePickerVC.parent = self;
            timePickerVC.time = self.program.startTime;
            [timePickerVC refreshTimeFormatConstraint];

            [self willPushChildView];
            [self.navigationController pushViewController:timePickerVC animated:YES];
        }
    }
    else if (indexPath.section == cycleSoakAndStationDelaySectionIndex) {
        [self showSection4Screen:(int)indexPath.row];
    }
    else if (indexPath.section == wateringTimesSectionIndex) {
        SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
        ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
        setDelayVC.userInfo = @{@"name" : @"zoneDelay",
                                @"zoneId" : [NSNumber numberWithInteger:indexPath.row],
                                @"mins" : [NSNumber numberWithInt:programWateringTime.minutes],
                                };
        setDelayVC.titlePicker1 = @"minutes";
        setDelayVC.valuePicker1 = programWateringTime.minutes;
        
        setDelayVC.title = @"Zone watering duration";
        setDelayVC.parent = self;
        
        [self willPushChildView];
        [self.navigationController pushViewController:setDelayVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:[error localizedDescription] showErrorMessage:YES];
    
    if (serverProxy == self.getProgramListServerProxy) {
        self.getProgramListServerProxy = nil;
    }
    else if (serverProxy == self.postSaveServerProxy) {
        self.postSaveServerProxy = nil;
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
    }
//    else if (serverProxy == self.stationDelayServerProxy) {
//        self.stationDelayServerProxy = nil;
//    }
//    else if (serverProxy == self.cycleAndSoakServerProxy) {
//        self.cycleAndSoakServerProxy = nil;
//    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];
    
    [self.tableView reloadData];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.getProgramListServerProxy) {
        self.getProgramListServerProxy = nil;
        [MBProgressHUD hideHUDForView:self.view animated:YES];

        NSArray *newPrograms = (NSArray *)data;
        if ([newPrograms count] > 0) {
            NSArray *oldPrograms = self.parent.programs;
            Program *possibleAddedProgram = [self extractAddedProgramFromList:newPrograms basedOnOldList:oldPrograms];
            self.parent.programs = [newPrograms mutableCopy];

            if (possibleAddedProgram) {
                self.program = possibleAddedProgram;
            }
        }
        self.programCopyBeforeSave = self.program;
        [self createThreeButtonToolbar];
    }
    else if (serverProxy == self.postSaveServerProxy) {
        self.postSaveServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        } else {
            if (self.program.programId == -1) {
                // Create a new program. We don't receive the new id from the server. That's why we have to do a new requestPrograms call and extract the new id from there.
                self.getProgramListServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
                [_getProgramListServerProxy requestPrograms];
            } else {
                // Save existing program
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self.parent setProgram:self.program withIndex:self.programIndex];
                self.programCopyBeforeSave = self.program;
            }
        }
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
        StartStopProgramResponse *response = (StartStopProgramResponse*)data;
        if ([response.state isEqualToString:@"err"]) {
            [self.parent handleSprinklerGeneralError:response.message showErrorMessage:YES];
        }
        self.program.state = response.state;
        self.runNowServerProxy = nil;

        [self.parent setProgram:self.program withIndex:self.programIndex];
        self.programCopyBeforeSave = self.program;
    }
//    else if (serverProxy == self.stationDelayServerProxy) {
//        self.stationDelayServerProxy = nil;
//        ServerResponse *response = (ServerResponse*)data;
//        if ([response.status isEqualToString:@"err"]) {
//            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
//        } else {
//            NSDictionary *paramsDic = (NSDictionary *)userInfo;
//            self.program.delay = [[paramsDic objectForKey:@"delay"] intValue];
//            self.program.delayOn = [[paramsDic objectForKey:@"delay_on"] intValue];
//        }
//    }
//    else if (serverProxy == self.cycleAndSoakServerProxy) {
//        self.cycleAndSoakServerProxy = nil;
//        ServerResponse *response = (ServerResponse*)data;
//        if ([response.status isEqualToString:@"err"]) {
//            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
//        } else {
//            NSDictionary *paramsDic = (NSDictionary *)userInfo;
//            self.program.cycles = [[paramsDic objectForKey:@"cycles"] intValue];
//            self.program.soak = [[paramsDic objectForKey:@"soak"] intValue];
//            self.program.csOn = [[paramsDic objectForKey:@"cs_on"] intValue];
//        }
//    }
    
    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];
    
    [self.tableView reloadData];
    [self refreshToolBarButtonTitles];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Internal

- (Program*)extractAddedProgramFromList:(NSArray*)newPrograms basedOnOldList:(NSArray*)oldPrograms
{
    NSArray *oldIds = [oldPrograms valueForKey:@"programId"];
    NSMutableArray *newIds = [[newPrograms valueForKey:@"programId"] mutableCopy];
    
    [newIds removeObjectsInArray:oldIds];
    if ([newIds count] > 0) {
        int lastId = [[newIds lastObject] intValue];
        for (Program *p in newPrograms) {
            if ([p programId] == lastId) {
                return p;
            }
        }
    }
    
    return nil;
}

- (BOOL)hasUnsavedChanged
{
    if (self.programCopyBeforeSave) {
        // In this comparison the difference in state should not be considered
        self.programCopyBeforeSave.state = self.program.state;
        return ![self.programCopyBeforeSave isEqualToProgram:self.program];
    }
    
    return YES;
}

- (void)showUnsavedChangesPopup:(id)notif
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Leave screen?"
                                                        message:@"There are unsaved changes"
                                                       delegate:self
                                              cancelButtonTitle:@"Leave screen"
                                              otherButtonTitles:@"Stay", nil];
    alertView.tag = kAlertViewTag_UnsavedChanges;
    [alertView show];
}

- (NSString *)checkProgramValidity
{
    if ([self.program.weekdays isEqualToString:@"0,0,0,0,0,0,0"]) {
        return @"Select at least a weekday or change frequency type";
    }
    
    BOOL isThereANonZeroWateringZoneTime = NO;
    for (ProgramWateringTimes *programWateringTime in self.program.wateringTimes) {
        if (programWateringTime.minutes != 0) {
            isThereANonZeroWateringZoneTime = YES;
            break;
        }
    }
    
    if (!isThereANonZeroWateringZoneTime) {
        return @"At least one zone must have a non-zero watering time";
    }
    
    return nil;
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

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertViewTag_UnsavedChanges) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            [self popWithoutQuestion];
        }
    }
    else if (alertView.tag == kAlertViewTag_InvalidProgram) {
    }
}

@end
