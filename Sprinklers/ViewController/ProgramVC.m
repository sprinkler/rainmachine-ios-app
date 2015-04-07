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
#import "Program4.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"
#import "ButtonCell.h"
#import "ProgramCellType1.h"
#import "ProgramCellType2.h"
#import "ProgramCellType3.h"
#import "ProgramCellType4.h"
#import "ProgramCellType5.h"
#import "ProgramCellType6.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"
#import "Additions.h"
#import "+NSString.h"
#import "ServerResponse.h"
#import "ProgramsVC.h"
#import "ProgramWateringTimes.h"
#import "ProgramWateringTimes4.h"
#import "WeekdaysVC.h"
#import "SetDelayVC.h"
#import "TimePickerVC.h"
#import "DatePickerVC.h"
#import "+UIDevice.h"
#import "StartStopProgramResponse.h"
#import "Constants.h"
#import "RainDelayPoller.h"
#import "RainDelay.h"
#import "HomeScreenDataSourceCell.h"
#import "API4StatusResponse.h"

@interface ProgramVC ()
{
    MBProgressHUD *hud;
    BOOL setRunNowActivityIndicator;
    BOOL runNowButtonEnabledState;
    BOOL resignKeyboard;
    
    BOOL isNewProgram;
    BOOL didSave;

    int runNowSectionIndex;
    int nameSectionIndex;
    int activeSectionIndex;
    int ignoreWeatherDataSectionIndex;
    int useWaterSenseSectionIndex;
    int frequencySectionIndex;
    int startTimeSectionIndex;
    int cycleSoakAndStationDelaySectionIndex;
    int wateringTimesSectionIndex;
    int getProgramCount;
}

@property (strong, nonatomic) ServerProxy *getProgramListServerProxy;
@property (strong, nonatomic) ServerProxy *runNowServerProxy;
@property (strong, nonatomic) ServerProxy *postSaveServerProxy;
@property (strong, nonatomic) ServerProxy *getZonesServerProxy;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *frequencyEveryXDays;
@property (strong, nonatomic) NSString *frequencyWeekdays;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;

@property (weak, nonatomic) IBOutlet UITableView *statusTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusTableViewHeightConstraint;

@property (strong, nonatomic) RainDelayPoller *rainDelayPoller;

@property (assign, nonatomic) BOOL shouldRefreshContent;

@property (readonly, nonatomic) BOOL waterSenseEnabled;

@property (readonly, nonatomic) NSDate *nextRunDateForDailyFrequency;
@property (readonly, nonatomic) NSDate *nextRunDateForOddDaysFrequency;
@property (readonly, nonatomic) NSDate *nextRunDateForEvenDaysFrequency;
@property (readonly, nonatomic) NSDate *nextRunDateForSelectedDaysFrequency;

- (void)refreshNextRun;

@end

@implementation ProgramVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Hide the status table view initially
    self.statusTableViewHeightConstraint.constant = 0;
    self.title = @"Program";
    isNewProgram = (self.program == nil);
    didSave = NO;
    resignKeyboard = NO;
    
    if (!self.showInitialUnsavedAlert) {
        // In the case when 'showInitialUnsavedAlert' is YES, programCopyBeforeSave is set beforehand
        self.programCopyBeforeSave = self.program;
    }
    
    if (self.program) {

        if ([ServerProxy usesAPI3]) {
            runNowSectionIndex = -1;
            nameSectionIndex = 0;
            activeSectionIndex = 1;
            ignoreWeatherDataSectionIndex = 2;
            useWaterSenseSectionIndex = -1;
            frequencySectionIndex = 3;
            startTimeSectionIndex = 4;
            cycleSoakAndStationDelaySectionIndex = 5;
            wateringTimesSectionIndex = 6;
        } else {
            runNowSectionIndex = -1;
            nameSectionIndex = 0;
            activeSectionIndex = 1;
            ignoreWeatherDataSectionIndex = 2;
            useWaterSenseSectionIndex = 3;
            frequencySectionIndex = 4;
            startTimeSectionIndex = 5;
            cycleSoakAndStationDelaySectionIndex = 6;
            wateringTimesSectionIndex = 7;
        }
        
        if ((![Utils isDevice357Plus]) && ([self.program.state isEqualToString:@"stopped"])) {
            // 3.55 and 3.56 can only Stop programs
            [self createTwoButtonToolbar];
        }
    } else {
        if ([ServerProxy usesAPI3]) {
            runNowSectionIndex = -1;
            nameSectionIndex = 0;
            activeSectionIndex = 1;
            ignoreWeatherDataSectionIndex = 2;
            useWaterSenseSectionIndex = -1;
            frequencySectionIndex = 3;
            startTimeSectionIndex = 4;
            cycleSoakAndStationDelaySectionIndex = 5;
            wateringTimesSectionIndex = 6;
        } else {
            runNowSectionIndex = -1;
            nameSectionIndex = 0;
            activeSectionIndex = 1;
            ignoreWeatherDataSectionIndex = 2;
            useWaterSenseSectionIndex = 3;
            frequencySectionIndex = 4;
            startTimeSectionIndex = 5;
            cycleSoakAndStationDelaySectionIndex = 6;
            wateringTimesSectionIndex = 7;
        }
    
        [self createTwoButtonToolbar];
    }

    [self refreshToolBarButtonTitles];
    
    if (!self.program) {
        if ([ServerProxy usesAPI3]) {
            self.program = [Program program];
        } else {
            self.program = (Program*)[Program4 program];
        }
        self.program.timeFormat = [self.parent serverTimeFormat];
        
        if (!self.showInitialUnsavedAlert) {
            self.programCopyBeforeSave = self.program;
        }
    }
    
    [_statusTableView registerNib:[UINib nibWithNibName:@"HomeDataSourceCell" bundle:nil] forCellReuseIdentifier:@"HomeDataSourceCell"];

    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType1" bundle:nil] forCellReuseIdentifier:@"ProgramCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType2" bundle:nil] forCellReuseIdentifier:@"ProgramCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType3" bundle:nil] forCellReuseIdentifier:@"ProgramCellType3"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType4" bundle:nil] forCellReuseIdentifier:@"ProgramCellType4"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType5" bundle:nil] forCellReuseIdentifier:@"ProgramCellType5"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType6" bundle:nil] forCellReuseIdentifier:@"ProgramCellType6"];
    [_tableView registerNib:[UINib nibWithNibName:@"ButtonCell" bundle:nil] forCellReuseIdentifier:@"ButtonCell"];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];

    self.getProgramListServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    getProgramCount = 0;
    
    self.rainDelayPoller = [[RainDelayPoller alloc] initWithDelegate:self];
    [self showHUD];
    
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
    
    [self refreshToolbarEdited];
}

- (void) refreshToolbarEdited
{
    if (isNewProgram && !didSave) {
        [self createTwoButtonToolbar];
    } else {
        if ((![Utils isDevice357Plus]) && ([self.program.state isEqualToString:@"stopped"])) {
            // 3.55 and 3.56 can only Stop programs
            [self createTwoButtonToolbar];
        } else {
            [self createThreeButtonToolbar];
        }
    }
    
    [self refreshToolBarButtonTitles];
    [self refreshStatus];
}

- (BOOL)didEdit
{
    return ![self.programCopyBeforeSave isEqualToProgram:self.program];
}

- (void)refreshToolBarButtonTitles
{
    self.startButtonItem.title = [self.program.state isEqualToString:@"stopped"] ? @"Start" : @"Stop";
}

- (void)createTwoButtonToolbar
{
    UIBarButtonItem* buttonDiscard = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* buttonSave = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(onSave:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        buttonDiscard.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        buttonSave.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
    }
    
    //set the toolbar buttons
    self.topToolbar.items = [NSArray arrayWithObjects:flexibleSpace, buttonDiscard, flexibleSpace, buttonSave, flexibleSpace, nil];
    self.startButtonItem = nil;
}

- (void)createThreeButtonToolbar
{
    BOOL didEdit = [self didEdit];

    UIBarButtonItem* buttonDiscard = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* buttonSave = [[UIBarButtonItem alloc] initWithTitle:@"Save" style: didEdit ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered target:self action:@selector(onSave:)];
    UIBarButtonItem* buttonStart = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:didEdit ? UIBarButtonItemStyleBordered : UIBarButtonItemStyleDone target:self action:@selector(onStartOrStop:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        buttonDiscard.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        
        if (didEdit) {
            buttonSave.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
            
            buttonStart.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        }
        else
        {
            buttonSave.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
            
            buttonStart.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        }
    }
    
    //set the toolbar buttons
    self.topToolbar.items = [NSArray arrayWithObjects:flexibleSpace, buttonDiscard, flexibleSpace, buttonSave, flexibleSpace, buttonStart, flexibleSpace, nil];
    self.startButtonItem = buttonStart;
}

- (void)willPushChildView
{
    self.shouldRefreshContent = NO;
    
    // This prevents the test from viewWillDisappear to pass
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Don't request the program when the view is created because the program list already is up-to-date
    if (getProgramCount > 0) {
        if (self.program.programId != -1) {
            // There is no getProgrambyId request, so we extract the program from the programs list
            if (self.shouldRefreshContent) {
                [self requestProgram];
                [self showHUD];
            }
        }
    }
    
    self.shouldRefreshContent = YES;
    
    getProgramCount++;
    
    [self refreshToolbarEdited];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.parent setUnsavedProgram:nil withIndex:0];
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
    
    [self.rainDelayPoller scheduleNextPoll:0];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;

    [self.rainDelayPoller stopPollRequests];
}

- (void)updateRunNowButtonActiveStateTo:(BOOL)state setActivityIndicator:(BOOL)setActivityIndicator
{
//    setRunNowActivityIndicator = setActivityIndicator;
//    runNowButtonEnabledState = state;

    if (setActivityIndicator) {
        [self showHUD];
    } else {
        [self hideHUD];
        hud = nil;
    }
    self.startButtonItem.enabled = state;
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
    NSString *invalidProgramStateMessage = nil;
    if (!self.waterSenseEnabled) invalidProgramStateMessage = [self checkProgramValidity];
    
    if (invalidProgramStateMessage) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot save program"
                                                            message:invalidProgramStateMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = kAlertView_InvalidProgram;
        [alertView show];
    } else {
        if (!self.postSaveServerProxy) {
            self.postSaveServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
            if ([ServerProxy usesAPI3]) {
                [self.postSaveServerProxy saveProgram:self.program];
            } else {
                if (self.program.programId != -1) {
                    [self.postSaveServerProxy saveProgram:self.program];
                } else {
                    [self.postSaveServerProxy createProgram:(Program4*)self.program];
                }
            }
            
            [self showHUD];
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
    
    if (!self.getZonesServerProxy) {
        self.getZonesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [self.getZonesServerProxy requestZones];
        [self showHUD];
    }
}

- (IBAction)onStartOrStop:(id)sender {
    self.runNowServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    if ([ServerProxy usesAPI3]) {
        [self.runNowServerProxy runNowProgram:self.program];
    } else {
        Program4 *program4 = (Program4*)self.program;
        if (program4.status == API4_ProgramStatus_Stopped) {
            NSString *cannotStartProgramStateMessage = [self checkProgramCanStart];
            if (cannotStartProgramStateMessage) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot start program"
                                                                    message:cannotStartProgramStateMessage
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                return;
            }
            
            [self.runNowServerProxy startProgram4:program4];
        } else {
            [self.runNowServerProxy stopProgram4:program4];
        }
    }
    
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
            self.program.ignoreWeatherData = !cell.theSwitch.on;
        }
        else if (cell.useWaterSenseCellType) {
            ((Program4*)self.program).useWaterSense = cell.theSwitch.on;
            [self.tableView reloadData];
        }
        else {
            self.program.active = cell.theSwitch.on;
        }
    }
    else if ([object isKindOfClass:[ProgramCellType6 class]]) {
        ProgramCellType6 *cell = (ProgramCellType6*)object;
        cell.programWateringTime.active = cell.theSwitch.on;
        if (cell.programWateringTime.active && cell.programWateringTime.minutes == 0) {
            [self tableView:self.tableView didSelectRowAtIndexPath:[self.tableView indexPathForCell:cell]];
        }
        [self.tableView reloadData];
    }
    
    [self refreshToolbarEdited];
}

- (void)onCell:(UITableViewCell*)theCell checkmarkState:(BOOL)sel
{
    ProgramCellType3 *cell = (ProgramCellType3*)theCell;
    
    [self checkFrequencyWithIndex:cell.index];
    
    [self.tableView reloadData];
    
    [self refreshToolbarEdited];
}

- (void)cellTextFieldChanged:(NSString*)text
{
    self.program.name = text;
    
    [self refreshToolbarEdited];
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
            self.frequencyEveryXDays = [NSString stringWithFormat:@"INT %d", MAX(2, setDelayVC.valuePicker1)];
            self.program.weekdays = self.frequencyEveryXDays;
            }
    } else if ([setDelayVC.userInfo isKindOfClass:[NSDictionary class]]) {
        NSString *name = [setDelayVC.userInfo objectForKey:@"name"];
         if ([name isEqualToString:@"zoneDelay"]) {
             NSNumber *zoneId = [setDelayVC.userInfo objectForKey:@"zoneId"];
             if ([ServerProxy usesAPI4]) {
                 ProgramWateringTimes4 *programWateringTime = self.program.wateringTimes[[zoneId intValue]];
                 [self setProgram4WateringTime:setDelayVC.valuePicker1 on:programWateringTime];
                 programWateringTime.active = (programWateringTime.minutes != 0);
                 [self.tableView reloadData];
             } else {
                 ProgramWateringTimes *programWateringTime = self.program.wateringTimes[[zoneId intValue]];
                 [self setProgramWateringTime:setDelayVC.valuePicker1 on:programWateringTime];
             }
         }
    }
    
    [self.tableView reloadData];
}

- (void)weekdaysVCWillDissapear:(WeekdaysVC*)weekdaysVC
{
    self.frequencyWeekdays = [weekdaysVC.selectedWeekdays componentsJoinedByString:@","];
    self.program.weekdays = self.frequencyWeekdays;
    
    if ([ServerProxy usesAPI4]) [self refreshNextRun];
    
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
    if ([ServerProxy usesAPI4]) [self refreshNextRun];
    
    [self.tableView reloadData];
}

- (void)datePickerVCWillDissapear:(DatePickerVC*)datePickerVC
{
    if ([ServerProxy usesAPI4]) {
        ((Program4*)self.program).nextRun = datePickerVC.date;
    }
    [self.tableView reloadData];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.statusTableView) {
        if ([self.rainDelayPoller rainDelayMode]) {
            return 1;
        }
        
        return 0;
    }

    return wateringTimesSectionIndex + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.statusTableView) {
        return nil;
    }
    
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
    if (tableView == self.statusTableView) {
        if ([self.rainDelayPoller rainDelayMode]) {
            return 1;
        }
        
        return 0;
    }

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
    else if (section == useWaterSenseSectionIndex) {
        return 1;
    }
    else if (section == frequencySectionIndex) {
        return 5;
    }
    else if (section == startTimeSectionIndex) {
        return ([ServerProxy usesAPI3] ? 1 : 2);
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
    if (tableView == self.statusTableView) {
        return 54;
    }

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
    else if (indexPath.section == useWaterSenseSectionIndex) {
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
    if (tableView == self.statusTableView) {
        static NSString *CellIdentifier = @"HomeDataSourceCell";
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if ([self.rainDelayPoller rainDelayMode]) {
            [cell setRainDelayUITo:YES withValue:[self.rainDelayPoller.rainDelayData.delayCounter intValue]];
        } else {
            [cell setRainDelayUITo:NO withValue:0];
        }
        
        return cell;
    } else {
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
            cell.theTextField.enabled = [Utils isDevice359Plus];
            cell.theTextField.text = self.program.name;
            cell.delegate = self;
            if (resignKeyboard) {
                [cell.theTextField resignFirstResponder];
                resignKeyboard = NO;
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
            cell.useWaterSenseCellType = NO;
            return cell;
        }
        else if (indexPath.section == ignoreWeatherDataSectionIndex) {
            static NSString *CellIdentifier = @"ProgramCellType2";
            ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            if (self.waterSenseEnabled) {
                cell.theSwitch.on = YES;
                cell.theSwitch.enabled = NO;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.theSwitch.on = !self.program.ignoreWeatherData;
                cell.theSwitch.enabled = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            cell.theTextLabel.text = @"Weather data";
            cell.theDetailLabel.text = nil;
            cell.delegate = self;
            cell.ignoreWeatherDataCellType = YES;
            cell.useWaterSenseCellType = NO;
            return cell;
        }
        else if (indexPath.section == useWaterSenseSectionIndex) {
            static NSString *CellIdentifier = @"ProgramCellType2";
            ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.theSwitch.on = ((Program4*)self.program).useWaterSense;
            cell.theTextLabel.text = @"WaterSense";
            cell.theDetailLabel.text = nil;
            cell.delegate = self;
            cell.ignoreWeatherDataCellType = NO;
            cell.useWaterSenseCellType = YES;
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
                if (self.waterSenseEnabled) check = YES;
                else check = [self.program.weekdays isEqualToString:@"D"];
                cell.theCenteredTextLabel.text = @"Daily";
                cell.index = 0;
            }
            else if (indexPath.row == 1) {
                if (self.waterSenseEnabled) check = NO;
                else check = [self.program.weekdays isEqualToString:@"ODD"];
                cell.theCenteredTextLabel.text = @"Odd days";
                cell.index = 1;
            }
            else if (indexPath.row == 2) {
                if (self.waterSenseEnabled) check = NO;
                else check = [self.program.weekdays isEqualToString:@"EVD"];
                cell.theCenteredTextLabel.text = @"Even days";
                cell.index = 2;
            }
            else if (indexPath.row == 3) {
                if (self.waterSenseEnabled) check = NO;
                else check = [self.program.weekdays containsString:@"INT"];
                int nrDays;
                sscanf([self.frequencyEveryXDays UTF8String], "INT %d", &nrDays);
                cell.theCenteredTextLabel.text = [NSString stringWithFormat:@"Every %d days", nrDays];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.index = 3;
            }
            else if (indexPath.row == 4) {
                if (self.waterSenseEnabled) check = NO;
                else check = [self.program.weekdays containsString:@","];
                cell.theTextLabel.text = @"Selected days";
                cell.theCenteredTextLabel.text = @"Selected days";
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
            
            if (self.waterSenseEnabled) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.theTextLabel.textColor = [UIColor lightGrayColor];
                cell.theCenteredTextLabel.textColor = [UIColor lightGrayColor];
                cell.theDetailTextLabel.textColor = [UIColor lightGrayColor];
            }
            else {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.theTextLabel.textColor = [UIColor blackColor];
                cell.theCenteredTextLabel.textColor = [UIColor blackColor];
                cell.theDetailTextLabel.textColor = [UIColor blackColor];
            }
            
            return cell;
        }
        
        else if (indexPath.section == startTimeSectionIndex) {
            int nextRunRow = ([ServerProxy usesAPI3] ? -1 : 0);
            int startTimeRow = ([ServerProxy usesAPI3] ? 0 : 1);
            
            static NSString *CellIdentifier = @"ProgramCellType4";
            ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (indexPath.row == nextRunRow) {
                cell.theTextLabel.text = @"NEXT RUN";
                cell.timeLabel.text = [[NSDate sharedReverseDateFormatterAPI4] stringFromDate:((Program4*)self.program).nextRun];
                
                if ([self.program.weekdays containsString:@"INT"]) {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.timeLabelTrailingLayoutConstraint.constant = 4.0;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.timeLabelTrailingLayoutConstraint.constant = 37.0;
                }
            }
            else if (indexPath.row == startTimeRow) {
                NSNumber *time_format = ([Utils isTime24HourFormat]) ? @24 : @12;
                NSDateFormatter *formatter = [Utils sprinklerDateFormatterForTimeFormat:time_format seconds:NO forceOnlyTimePart:YES forceOnlyDatePart:NO];
                NSString *startHourAndMinute = [formatter stringFromDate:_program.startTime];
                cell.theTextLabel.text = @"START TIME";
                cell.timeLabel.text = startHourAndMinute;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.timeLabelTrailingLayoutConstraint.constant = 4.0;
            }
            
            cell.theTextLabel.font = [UIFont systemFontOfSize: 22.0f];
            cell.timeLabel.textColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
            
            return cell;
        }
        
        else if (indexPath.section == cycleSoakAndStationDelaySectionIndex) {
            static NSString *CellIdentifier = @"ProgramCellType5";
            ProgramCellType5 *cell = (ProgramCellType5*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            if (indexPath.row == 0) {
                cell.theTextLabel.text = @"Cycle & Soak";
                if (self.waterSenseEnabled) {
                    cell.theSwitch.on = YES;
                    cell.theSwitch.enabled = NO;
                    cell.theDetailTextLabel.text = @"Auto";
                    cell.theTextLabel.textColor = [UIColor lightGrayColor];
                    cell.theDetailTextLabel.textColor = [UIColor lightGrayColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.theSwitch.on = self.program.csOn;
                    cell.theSwitch.enabled = YES;
                    cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d cycles / %d min soak", self.program.cycles, self.program.soak];
                    cell.theTextLabel.textColor = [UIColor blackColor];
                    cell.theDetailTextLabel.textColor = [UIColor blackColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                }
                cell.cycleAndSoak = YES;
            }
            else if (indexPath.row == 1) {
                cell.theTextLabel.text = @"Delay between zones";
                
                if (self.waterSenseEnabled) {
                    cell.theSwitch.on = YES;
                    cell.theSwitch.enabled = NO;
                    cell.theDetailTextLabel.text = @"Auto";
                    cell.theTextLabel.textColor = [UIColor lightGrayColor];
                    cell.theDetailTextLabel.textColor = [UIColor lightGrayColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.theSwitch.on = self.program.delayOn;
                    cell.theSwitch.enabled = YES;
                    cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d min", self.program.delay];
                    cell.theTextLabel.textColor = [UIColor blackColor];
                    cell.theDetailTextLabel.textColor = [UIColor blackColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                }
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
            if ([ServerProxy usesAPI4]) {
                static NSString *CellIdentifier = @"ProgramCellType6";
                ProgramCellType6 *cell = (ProgramCellType6*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                ProgramWateringTimes4 *programWateringTime = self.program.wateringTimes[indexPath.row];
                cell.theTextLabel.font = [UIFont systemFontOfSize: 17.0f];
                cell.theTextLabel.text = [Utils fixedZoneName:programWateringTime.name withId:[NSNumber numberWithInt:programWateringTime.wtId]];
                if (self.waterSenseEnabled) {
                    if (programWateringTime.active) cell.timeLabel.text = @"Auto";
                    else cell.timeLabel.text = @"";
                    cell.theTextLabel.textColor = [UIColor lightGrayColor];
                    cell.timeLabel.textColor = [UIColor lightGrayColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                } else {
                    cell.timeLabel.text = [NSString stringWithFormat:@"%d min", programWateringTime.minutes];
                    cell.theTextLabel.textColor = [UIColor blackColor];
                    cell.timeLabel.textColor = [UIColor blackColor];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                }
                cell.theSwitch.on = programWateringTime.active;
                cell.delegate = self;
                cell.programWateringTime = programWateringTime;
                return cell;
            } else {
                static NSString *CellIdentifier = @"ProgramCellType4";
                ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
                cell.theTextLabel.font = [UIFont systemFontOfSize: 17.0f];
                cell.theTextLabel.text = [Utils fixedZoneName:programWateringTime.name withId:[NSNumber numberWithInt:programWateringTime.wtId]];
                cell.timeLabel.text = [NSString stringWithFormat:@"%d min", programWateringTime.minutes];
                cell.timeLabel.textColor = [UIColor blackColor];
                return cell;
            }
        }
    }
    
    return nil;
}

- (void)showSection4Screen:(int)row
{
    SetDelayVC *setDelayVC = [[SetDelayVC alloc] initWithNibName: [[UIDevice currentDevice] isIpad] ? @"SetDelayVC-iPad" :
                                                          @"SetDelayVC" bundle: nil];
    if (row == 0) {
        setDelayVC.moveLabelsLeftOfPicker = YES;
        setDelayVC.minValuePicker1 = 2;
        setDelayVC.maxValuePicker1 = 5;
        setDelayVC.minValuePicker2 = 0;
        setDelayVC.maxValuePicker2 = 300;
        setDelayVC.userInfo = @"cycle_and_soak";
        setDelayVC.titlePicker1 = @"Number of cycles:";
        setDelayVC.titlePicker2 = @"Soak time:";
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
        setDelayVC.title = @"Delay between zones";
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

    if (tableView == self.statusTableView) {
        HomeScreenDataSourceCell *cell = (HomeScreenDataSourceCell *)[self.statusTableView cellForRowAtIndexPath:indexPath];
        if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Resume sprinkler operation?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Resume", nil];
            alertView.tag = kAlertView_ResumeRainDelay;
            [alertView show];
        }
    } else {
        
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
            if (!self.waterSenseEnabled) {
                ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.theSwitch.on = !cell.theSwitch.on;
                self.program.ignoreWeatherData = !cell.theSwitch.on;
                [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.25];
            }
        }
        else if (indexPath.section == useWaterSenseSectionIndex) {
            ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.theSwitch.on = !cell.theSwitch.on;
            ((Program4*)self.program).useWaterSense = cell.theSwitch.on;
            [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.25];
        }
        else if (indexPath.section == frequencySectionIndex) {
            if (!self.waterSenseEnabled) {
                NSString *oldWeekdays = self.program.weekdays;
                
                ProgramCellType3 *cell = (ProgramCellType3*)[self.tableView cellForRowAtIndexPath:indexPath];
                [cell onCheckMark: self];
                
                if (indexPath.row == 3) {
                    int nrDays;
                    sscanf([self.frequencyEveryXDays UTF8String], "INT %d", &nrDays);

                    SetDelayVC *setIntervalFrequencyVC = [[SetDelayVC alloc] initWithNibName: [[UIDevice currentDevice] isIpad] ? @"SetDelayVC-iPad" : @"SetDelayVC" bundle: nil];
                    setIntervalFrequencyVC.parent = self;
                    setIntervalFrequencyVC.userInfo = @"interval_frequency";
                    setIntervalFrequencyVC.titlePicker1 = @"days";
                    setIntervalFrequencyVC.minValuePicker1 = 2;
                    setIntervalFrequencyVC.maxValuePicker1 = 14;
                    setIntervalFrequencyVC.valuePicker1 = MAX(2, nrDays);
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
                
                if ([ServerProxy usesAPI4] && ![self.program.weekdays isEqualToString:oldWeekdays]) {
                    if ([self.program.weekdays containsString:@"INT"]) {
                        ((Program4*)self.program).nextRun = [[NSDate date] dateByAddingDays:1];
                    } else {
                        [self refreshNextRun];
                    }
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:startTimeSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
                }
            }
        }
        else if (indexPath.section == startTimeSectionIndex) {
            
            int nextRunRow = ([ServerProxy usesAPI3] ? -1 : 0);
            int startTimeRow = ([ServerProxy usesAPI3] ? 0 : 1);
            
            if (indexPath.row == nextRunRow) {
                if ([self.program.weekdays containsString:@"INT"]) {
                    DatePickerVC *datePickerVC = [[DatePickerVC alloc] init];
                    datePickerVC.parent = self;
                    datePickerVC.date = ((Program4*)self.program).nextRun;
                    
                    [self willPushChildView];
                    [self.navigationController pushViewController:datePickerVC animated:YES];
                }
            }
            else if (indexPath.row == startTimeRow) {

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
            if (!self.waterSenseEnabled) {
                [self showSection4Screen:(int)indexPath.row];
            }
        }
        else if (indexPath.section == wateringTimesSectionIndex) {
            if (!self.waterSenseEnabled) {
                SetDelayVC *setDelayVC = [[SetDelayVC alloc] initWithNibName: [[UIDevice currentDevice] isIpad] ? @"SetDelayVC-iPad" : @"SetDelayVC" bundle: nil];
                
                if ([ServerProxy usesAPI4]) {
                    ProgramWateringTimes4 *programWateringTime = self.program.wateringTimes[indexPath.row];
                    setDelayVC.userInfo = @{@"name"     : @"zoneDelay",
                                            @"zoneId"   : [NSNumber numberWithInteger:indexPath.row],
                                            @"mins"     : [NSNumber numberWithInt:programWateringTime.minutes],
                                            @"active"   : [NSNumber numberWithBool:programWateringTime.active]
                                            };
                    setDelayVC.valuePicker1 = programWateringTime.minutes;
                } else {
                    ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
                    setDelayVC.userInfo = @{@"name"     : @"zoneDelay",
                                            @"zoneId"   : [NSNumber numberWithInteger:indexPath.row],
                                            @"mins"     : [NSNumber numberWithInt:programWateringTime.minutes],
                                            };
                    setDelayVC.valuePicker1 = programWateringTime.minutes;
                }
                
                setDelayVC.titlePicker1 = @"minutes";
                setDelayVC.title = @"Zone watering duration";
                setDelayVC.parent = self;
                
                [self willPushChildView];
                [self.navigationController pushViewController:setDelayVC animated:YES];
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.getProgramListServerProxy) {
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
    
    [self hideHUD];

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];
    
    [self.tableView reloadData];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo
{
    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:NO];
    
    if (serverProxy == self.getZonesServerProxy) {
        self.getZonesServerProxy = nil;
        [self hideHUD];
        
        [self updateProgramWateringTimes:data onlyActiveZones:isNewProgram updateProgramCopy:!isNewProgram];
        [self.tableView reloadData];
    }
    else if (serverProxy == self.getProgramListServerProxy) {
        [self hideHUD];

        if ([ServerProxy usesAPI3]) {
            NSArray *newPrograms = (NSArray *)data;
            if ([newPrograms count] > 0) {
                Program *programFromList = nil;
                if (self.program.programId == -1) {
                    NSArray *oldPrograms = self.parent.programs;
                    Program *possibleAddedProgram = [self extractAddedProgramFromList:newPrograms basedOnOldList:oldPrograms];
                    programFromList = possibleAddedProgram;
                } else {
                    programFromList = [self extractProgramWithId:self.program.programId fromList:newPrograms];
                }
                
                self.parent.programs = [newPrograms mutableCopy];

                if (programFromList) {
                    self.program = programFromList;
                    didSave = YES;
                }
            }
        } else {
            self.program = data;
            didSave = YES;
        }
        self.programCopyBeforeSave = self.program;
        [self createThreeButtonToolbar];
    }
    else if (serverProxy == self.postSaveServerProxy) {
        self.postSaveServerProxy = nil;
        NSString *errorMessage = nil;
        if ([ServerProxy usesAPI3]) {
            ServerResponse *response = (ServerResponse*)data;
            if ([response.status isEqualToString:@"err"]) {
                errorMessage = response.message;
            }
        } else {
            API4StatusResponse *response = (API4StatusResponse*)data;
            if (response.program[@"uid"]) {
                // New program
                self.program.programId = [response.program[@"uid"] intValue];
                [self.parent setProgram:self.program withIndex:self.programIndex];
            }
            didSave = YES;
            [self hideHUD];
        }
        if (errorMessage) {
            [self.parent handleSprinklerGeneralError:errorMessage showErrorMessage:YES];
        } else {
            if (self.program.programId == -1) {
                // Create a new program. We don't receive the new id from the server. That's why we have to do a new requestPrograms call and extract the new id from there.
                [self showHUD];
                [self requestProgram];
            } else {
                // Save existing program
                [self hideHUD];
                [self.parent setProgram:self.program withIndex:self.programIndex];
                self.programCopyBeforeSave = self.program;
                
                // reset toolbar state
                [self refreshToolbarEdited];
            }
            didSave = YES;
        }
        
        [self.tableView reloadData];
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
        NSString *errorMessage = nil;
        if ([ServerProxy usesAPI3]) {
            StartStopProgramResponse *response = (StartStopProgramResponse*)data;
            if ([response.state isEqualToString:@"err"]) {
                errorMessage = response.message;
            }
            self.program.state = response.state;
        } else {
            self.program.state = userInfo;
        }
        
        if (errorMessage) {
            [self.parent handleSprinklerGeneralError:errorMessage showErrorMessage:YES];
        }

        self.runNowServerProxy = nil;

        [self.parent setProgram:self.program withIndex:self.programIndex];
        self.programCopyBeforeSave = self.program;
        
        [self.tableView reloadData];
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
    
    [self refreshToolBarButtonTitles];
    [self refreshStatus];
}

- (void)loggedOut {
    [self hideHUD];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Internal

- (void)requestProgram
{
    if ([ServerProxy usesAPI3]) {
        [_getProgramListServerProxy requestPrograms];
    } else {
        [_getProgramListServerProxy requestProgramWithId:self.program.programId];
    }
}

- (Program*)extractProgramWithId:(int)programId fromList:(NSArray*)programs
{
    for (Program *listProgram in programs) {
        if (listProgram.programId == programId) {
            return listProgram;
        }
    }
    return nil;
}

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
    alertView.tag = kAlertView_UnsavedChanges;
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

- (NSString *)checkProgramCanStart
{
    if ([ServerProxy usesAPI3]) return nil;
    
    BOOL isThereANonZeroActiveWateringZoneTime = NO;
    for (ProgramWateringTimes4 *programWateringTime in self.programCopyBeforeSave.wateringTimes) {
        if (self.waterSenseEnabled) {
            if (programWateringTime.active) {
                isThereANonZeroActiveWateringZoneTime = YES;
                break;
            }
        } else {
            if (programWateringTime.duration != 0 && programWateringTime.active) {
                isThereANonZeroActiveWateringZoneTime = YES;
                break;
            }
        }
    }
    
    if (!isThereANonZeroActiveWateringZoneTime) {
        return @"At least one zone with a non-zero watering time must be active";
    }
    
    return nil;
}

- (void)updateProgramWateringTimes:(NSArray*)input onlyActiveZones:(BOOL)onlyActiveZones updateProgramCopy:(BOOL)updateProgramCopy
{
    // Filter out the master valve and inactive zones
    NSMutableArray *zones = [NSMutableArray array];
    for (Zone *zone in input) {
        BOOL validZone = !zone.masterValve;
        if (onlyActiveZones) validZone = validZone && zone.active;
        if (validZone) {
            [zones addObject:zone];
        }
    }

    NSSet *receivedSet = [NSSet setWithArray:[zones valueForKeyPath:@"zoneId"]];
    NSSet *existingSet = [NSSet setWithArray:[self.program.wateringTimes valueForKeyPath:@"wtId"]];
    NSMutableSet *zonesToBeAdded = [receivedSet mutableCopy];
    [zonesToBeAdded minusSet:existingSet];
    NSMutableSet *zonesToBeDeleted = [existingSet mutableCopy];
    [zonesToBeDeleted minusSet:receivedSet];

    // Add all new zones from the receiving set
    for (Zone *zone in zones) {
        if ([zonesToBeAdded containsObject:[NSNumber numberWithInt:zone.zoneId ]]) {
            id wateringTime = nil;
            if ([ServerProxy usesAPI3]) {
                ProgramWateringTimes *wt = [[ProgramWateringTimes alloc] init];
                wt.wtId = zone.zoneId;
                wt.minutes = 0;
                wt.name = zone.name;
                wateringTime = wt;
            } else {
                ProgramWateringTimes4 *wt = [[ProgramWateringTimes4 alloc] init];
                wt.wtId = zone.zoneId;
                wt.minutes = 0;
                wt.name = zone.name;
                wt.active = NO;
                wateringTime = wt;
            }
            [self.program.wateringTimes addObject:wateringTime];
            if (updateProgramCopy) [self.programCopyBeforeSave.wateringTimes addObject:[wateringTime copy]];
        }
    }
    
    NSMutableIndexSet *indexSetToBeRemoved = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < self.program.wateringTimes.count; i++) {
        ProgramWateringTimes *wt = self.program.wateringTimes[i];
        if ([zonesToBeDeleted containsObject:[NSNumber numberWithInt:wt.wtId]]) {
            [indexSetToBeRemoved addIndex:i];
        }
    }
    [self.program.wateringTimes removeObjectsAtIndexes:indexSetToBeRemoved];
    if (updateProgramCopy) [self.programCopyBeforeSave.wateringTimes removeObjectsAtIndexes:indexSetToBeRemoved];
    
    if (self.program.wateringTimes.count == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot create program"
                                                            message:@"There must be at least one available active zone"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = kAlertView_NoActiveZones;
        [alertView show];
    }
}

- (void)setProgramWateringTime:(int)t on:(ProgramWateringTimes*)programWateringTime
{
    programWateringTime.minutes = t;
}

- (void)setProgram4WateringTime:(int)t on:(ProgramWateringTimes4*)programWateringTime
{
    programWateringTime.minutes = t;
}

#pragma mark - WaterSense flag

- (BOOL)waterSenseEnabled {
    if ([ServerProxy usesAPI3]) return NO;
    return ((Program4*)self.program).useWaterSense;
}

#pragma mark - Next run

- (NSDate*)nextRunDateForDailyFrequency {
    return [[NSDate date] dateByAddingDays:1];
}

- (NSDate*)nextRunDateForOddDaysFrequency {
    NSDate *tomorrow = [[NSDate date] dateByAddingDays:1];
    return (tomorrow.day % 2 ? tomorrow : [tomorrow dateByAddingDays:1]);
}

- (NSDate*)nextRunDateForEvenDaysFrequency {
    NSDate *tomorrow = [[NSDate date] dateByAddingDays:1];
    return (!(tomorrow.day % 2) ? tomorrow : [tomorrow dateByAddingDays:1]);
}

- (NSDate*)nextRunDateForSelectedDaysFrequency {
    NSDate *nextRunDate = nil;
    NSArray *frequencyWeekdays = [self.frequencyWeekdays componentsSeparatedByString:@","];
    BOOL nextRunDateSet = NO;
    
    for (NSInteger addDay = 1; addDay < 8; addDay++) {
        nextRunDate = [[NSDate date] dateByAddingDays:addDay];
        
        NSInteger weekday = nextRunDate.weekday;
        weekday -= 2;
        if (weekday < 0) weekday += 7;
        
        if (weekday < frequencyWeekdays.count && [frequencyWeekdays[weekday] isEqualToString:@"1"]) {
            nextRunDateSet = YES;
            break;
        }
    }
    
    if (nextRunDateSet) return nextRunDate;
    return [[NSDate date] dateByAddingDays:8];
}

- (void)refreshNextRun {
    if ([self.program.weekdays isEqualToString:@"D"]) ((Program4*)self.program).nextRun = self.nextRunDateForDailyFrequency;
    else if ([self.program.weekdays isEqualToString:@"ODD"]) ((Program4*)self.program).nextRun = self.nextRunDateForOddDaysFrequency;
    else if ([self.program.weekdays isEqualToString:@"EVD"]) ((Program4*)self.program).nextRun = self.nextRunDateForEvenDaysFrequency;
    else if ([self.program.weekdays containsString:@","]) ((Program4*)self.program).nextRun = self.nextRunDateForSelectedDaysFrequency;
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

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_ResumeRainDelay) {
        if (buttonIndex != theAlertView.cancelButtonIndex) {
            [self setRainDelay];
        }
    }
    else if (theAlertView.tag == kAlertView_UnsavedChanges) {
        if (theAlertView.cancelButtonIndex == buttonIndex) {
            [self popWithoutQuestion];
        }
    }
    else if (theAlertView.tag == kAlertView_NoActiveZones) {
        [self popWithoutQuestion];
    } else {
        [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    }
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

- (void)showHUD
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)hideHUD
{
    if (!self.getZonesServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

- (void)refreshStatus
{
    if ([self.rainDelayPoller rainDelayMode]) {
        self.statusTableViewHeightConstraint.constant = 54;
        self.startButtonItem.enabled = NO;
    } else {
        self.statusTableViewHeightConstraint.constant = 0;
        self.startButtonItem.enabled = YES;
    }
    
    if (!self.getZonesServerProxy) {
        [self.statusTableView reloadData];
    }
}

- (void)rainDelayResponseReceived
{
    if (!self.getZonesServerProxy) {
        self.getZonesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
        [self.getZonesServerProxy requestZones];
        [self showHUD];
    }
    [self refreshStatus];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.tableView endEditing:YES];
}

@end
