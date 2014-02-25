//
//  DailyProgramVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "DailyProgramVC.h"
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
#import "MBProgressHUD.h"
#import "ServerResponse.h"
#import "ProgramsVC.h"
#import "ProgramWateringTimes.h"
#import "WeekdaysVC.h"
#import "SetDelayVC.h"

@interface DailyProgramVC ()
{
    MBProgressHUD *hud;
    BOOL setRunNowActivityIndicator;
    BOOL runNowButtonEnabledState;
}

@property (strong, nonatomic) ServerProxy *runNowServerProxy;
@property (strong, nonatomic) ServerProxy *postSaveServerProxy;
@property (strong, nonatomic) ServerProxy *cycleAndSoakServerProxy;
@property (strong, nonatomic) ServerProxy *stationDelayServerProxy;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *frequencyEveryXDays;
@property (strong, nonatomic) NSString *frequencyWeekdays;

@end

@implementation DailyProgramVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType1" bundle:nil] forCellReuseIdentifier:@"ProgramCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType2" bundle:nil] forCellReuseIdentifier:@"ProgramCellType2"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType3" bundle:nil] forCellReuseIdentifier:@"ProgramCellType3"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType4" bundle:nil] forCellReuseIdentifier:@"ProgramCellType4"];
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType5" bundle:nil] forCellReuseIdentifier:@"ProgramCellType5"];
    [_tableView registerNib:[UINib nibWithNibName:@"ButtonCell" bundle:nil] forCellReuseIdentifier:@"ButtonCell"];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:YES];

    if ([self.program.weekdays containsString:@"INT"]) {
        self.frequencyEveryXDays = self.program.weekdays;
    } else {
        self.frequencyEveryXDays = @"INT 2"; // Default value
    }
    
    if ([self.program.weekdays containsString:@","]) {
        self.frequencyWeekdays = self.program.weekdays;
    }
}

- (void)updateRunNowButtonActiveStateTo:(BOOL)state setActivityIndicator:(BOOL)setActivityIndicator
{
    setRunNowActivityIndicator = setActivityIndicator;
    runNowButtonEnabledState = state;
}

#pragma mark - Actions

// onRunNow
- (void)onCellButton
{
    self.runNowServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    [self.runNowServerProxy runNowProgram:self.program];
    
    [self updateRunNowButtonActiveStateTo:NO setActivityIndicator:YES];
    self.program.state = @"running";
    
    [self.tableView reloadData];
}

- (void)requestCycleAndSoakServerProxyWithProgramId:(int)programId cycles:(int)nr_of_cycles soak:(int)soak_minutes cs_on:(int)cs_on
{
    if (self.cycleAndSoakServerProxy) {
        [self.cycleAndSoakServerProxy cancelAllOperations];
        self.cycleAndSoakServerProxy = nil;
    }
    
    self.cycleAndSoakServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    [self.cycleAndSoakServerProxy programCycleAndSoak:programId cycles:nr_of_cycles soak:soak_minutes cs_on:cs_on];
    
    [self.tableView reloadData];
}

- (void)requestStationDelay:(int)programId delay:(int)delay_minutes delay_on:(int)delay_on
{
    if (self.stationDelayServerProxy) {
        [self.stationDelayServerProxy cancelAllOperations];
        self.stationDelayServerProxy = nil;
    }

    self.stationDelayServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    [self.stationDelayServerProxy programStationDelay:programId delay:delay_minutes delay_on:delay_on];
    
    [self.tableView reloadData];
}

- (void)onCellSwitch:(id)object
{
    if ([object isKindOfClass:[ProgramCellType5 class]]) {
        ProgramCellType5 *cell = (ProgramCellType5*)object;
        if (cell.cycleAndSoak) {
            if ((cell.theSwitch.on) && ((self.program.cycles == 0) && (self.program.soak == 0)) ) {
                [self showSection4Screen:0];
            } else {
                self.program.csOn = YES;
                [self requestCycleAndSoakServerProxyWithProgramId:_program.programId cycles:_program.cycles soak:_program.soak cs_on:cell.theSwitch.on];
            }
        } else {
            if ((cell.theSwitch.on) && ((self.program.delay == 0)) ) {
                [self showSection4Screen:1];
            } else {
                self.program.delayOn = YES;
                [self requestStationDelay:_program.programId delay:_program.delay delay_on:cell.theSwitch.on];
            }
        }
    }
    else if ([object isKindOfClass:[ProgramCellType2 class]]) {
        ProgramCellType2 *cell = (ProgramCellType2*)object;
        self.program.active = cell.theSwitch.on;
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
    self.postSaveServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    [self.postSaveServerProxy saveProgram:self.program];

    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)setDelayVCOver:(SetDelayVC*)setDelayVC
{
    if ([setDelayVC.userInfo isKindOfClass:[NSString class]]) {
        if ([setDelayVC.userInfo isEqualToString:@"cycle_and_soak"]) {
            self.program.cycles = setDelayVC.valuePicker1;
            self.program.soak = setDelayVC.valuePicker2;
            self.program.csOn = !((_program.cycles == 0) && (_program.soak == 0));
            if (self.program.csOn) {
                [self requestCycleAndSoakServerProxyWithProgramId:_program.programId cycles:_program.cycles soak:_program.soak cs_on:_program.csOn];
            }
        } else if ([setDelayVC.userInfo isEqualToString:@"station_delay"]) {
            self.program.delay = setDelayVC.valuePicker1;
            self.program.delayOn = !((_program.delay == 0));
            if (self.program.delayOn) {
                [self requestStationDelay:_program.programId delay:_program.delay delay_on:_program.delayOn];
            }
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

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 2) {
        return @"Frequency";
    }
    else if (section == 5) {
        return @"Watering Time";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 2) {
        return 44.0;
    }
    else if (section == 5) {
        return 44.0;
    }
    return 22.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
         case 0:
            return 1; // Run Now
            break;
        case 1:
            return 2; // Program name, Active
            break;
        case 2:
            return 5; // Frequency
            break;
        case 3:
            return 1; // Start Time
            break;
        case 4:
            return 2; // Cycle & Soak, Station Delay
            break;
        case 5:
            return self.program.wateringTimes.count; // Watering Time
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 60;
            break;
            
        default:
            break;
    }
    
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            static NSString *CellIdentifier = @"ButtonCell";
            ButtonCell *cell = (ButtonCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            BOOL isStopped = [self.program.state isEqualToString:@"stopped"];
            [cell.button setCustomBackgroundColorFromComponents:isStopped ? kLoginGreenButtonColor : kWateringRedButtonColor];
            [cell.button setTitle:isStopped ? @"Run Now" : @"Stop" forState:UIControlStateNormal];
            
            if (setRunNowActivityIndicator) {
                cell.buttonActivityIndicator.hidden = runNowButtonEnabledState;
            }
            cell.button.enabled = runNowButtonEnabledState;
            cell.button.alpha = runNowButtonEnabledState ? 1 : 0.66;
            
            return cell;
        }
            break;
        case 1: {
            if (indexPath.row == 0) {
                static NSString *CellIdentifier = @"ProgramCellType1";
                ProgramCellType1 *cell = (ProgramCellType1*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                cell.theTextField.tintColor = [UIColor blackColor];
                cell.theTextField.text = self.program.name;
                cell.delegate = self;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
            else if (indexPath.row == 1) {
                static NSString *CellIdentifier = @"ProgramCellType2";
                ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                cell.theSwitch.on = self.program.active;
                cell.theTextLabel.text = @"Active";
                cell.theDetailLabel.text = nil;
                return cell;
            }
            // The commented part is for the newer API
//            else if (indexPath.row == 2) {
//                static NSString *CellIdentifier = @"ProgramCellType2";
//                ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//                cell.theSwitch.on = self.program.ignoreWeatherData;
//                cell.theTextLabel.text = @"Ignore weather data";
//                cell.theDetailLabel.text = @"";
//                return cell;
//            }
        }
            break;
        case 2: {
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
                cell.theCenteredTextLabel.text = @"Every day";
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
        case 3: {
            static NSString *CellIdentifier = @"ProgramCellType4";
            ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            if (indexPath.row == 0) {
                
                NSString *startHourAndMinute = [Utils formattedTime:_program.startTime forTimeFormat:_program.timeFormat];
                cell.theTextLabel.text = @"START TIME";
                cell.timeLabel.text = startHourAndMinute;
                cell.timeLabel.textColor = [UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1];
            }
            return cell;
        }
            break;
        case 4: {
            static NSString *CellIdentifier = @"ProgramCellType5";
            ProgramCellType5 *cell = (ProgramCellType5*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            if (indexPath.row == 0) {
                cell.theSwitch.on = self.program.csOn;
                cell.theTextLabel.text = @"Cycle & Soak";
                cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d cycles / %d min soak", self.program.cycles, self.program.soak];
                cell.theActivityIndicator.hidden = (self.cycleAndSoakServerProxy == nil);
                cell.cycleAndSoak = YES;
            }
            else if (indexPath.row == 1) {
                cell.theSwitch.on = self.program.delayOn;
                cell.theTextLabel.text = @"Station Delay";
                cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%d min", self.program.delay];
                cell.theActivityIndicator.hidden = (self.stationDelayServerProxy == nil);
                cell.cycleAndSoak = NO;
            }
            if (!cell.theActivityIndicator.hidden) {
                [cell.theActivityIndicator startAnimating];
            } else {
                [cell.theActivityIndicator stopAnimating];
            }
            return cell;
        }
            break;
        case 5: {
            static NSString *CellIdentifier = @"ProgramCellType4";
            ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
            cell.theTextLabel.text = [Utils fixedZoneName:programWateringTime.name withId:[NSNumber numberWithInt:programWateringTime.wtId]];
            cell.timeLabel.text = [NSString stringWithFormat:@"%d min", programWateringTime.minutes];
            cell.timeLabel.textColor = [UIColor blackColor];
            return cell;
        }
            break;
        default:
            break;
    }
    
    return nil;
}

- (void)showSection4Screen:(int)row
{
    SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
    if (row == 0) {
        setDelayVC.userInfo = @"cycle_and_soak";
        setDelayVC.titlePicker1 = @"cycles delayed";
        setDelayVC.titlePicker2 = @"minutes";
        setDelayVC.valuePicker1 = self.program.cycles;
        setDelayVC.valuePicker2 = self.program.soak;
        setDelayVC.title = @"Cycles and soak duration";
    }
    else if (row == 1) {
        setDelayVC.userInfo = @"station_delay";
        setDelayVC.titlePicker1 = @"minutes";
        setDelayVC.valuePicker1 = self.program.delay;
        setDelayVC.title = @"Station delay duration";
    }
    
    setDelayVC.parent = self;
    
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
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.theSwitch.on = !cell.theSwitch.on;
            self.program.active = cell.theSwitch.on;
        }
    }
    else if (indexPath.section == 2) {
        [self checkFrequencyWithIndex:indexPath.row];
        if (indexPath.row == 3) {
            int nrDays;
            sscanf([self.frequencyEveryXDays UTF8String], "INT %d", &nrDays);

            SetDelayVC *setIntervalFrequencyVC = [[SetDelayVC alloc] init];
            setIntervalFrequencyVC.parent = self;
            setIntervalFrequencyVC.userInfo = @"interval_frequency";
            setIntervalFrequencyVC.titlePicker1 = @"days";
            setIntervalFrequencyVC.valuePicker1 = nrDays;
            setIntervalFrequencyVC.title = @"Set days frequency";
            [self.navigationController pushViewController:setIntervalFrequencyVC animated:YES];
        }
        else if (indexPath.row == 4) {
            WeekdaysVC *weekdaysVC = [[WeekdaysVC alloc] init];
            weekdaysVC.selectedWeekdays = [[_program.weekdays componentsSeparatedByString:@","] mutableCopy];
            weekdaysVC.parent = self;
            [self.navigationController pushViewController:weekdaysVC animated:YES];
        }

    }
    else if (indexPath.section == 4) {
        [self showSection4Screen:indexPath.row];
    }
    else if (indexPath.section == 5) {
        SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
        ProgramWateringTimes *programWateringTime = self.program.wateringTimes[indexPath.row];
        setDelayVC.userInfo = @{@"name" : @"zoneDelay",
                                @"zoneId" : [NSNumber numberWithInt:indexPath.row],
                                @"mins" : [NSNumber numberWithInt:programWateringTime.minutes],
                                };
        setDelayVC.titlePicker1 = @"minutes";
        setDelayVC.valuePicker1 = programWateringTime.minutes;
        
        setDelayVC.title = @"Zone watering duration";
        setDelayVC.parent = self;
        
        [self.navigationController pushViewController:setDelayVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    
    if (serverProxy == self.postSaveServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.postSaveServerProxy = nil;
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
    }
    else if (serverProxy == self.stationDelayServerProxy) {
        self.stationDelayServerProxy = nil;
    }
    else if (serverProxy == self.cycleAndSoakServerProxy) {
        self.cycleAndSoakServerProxy = nil;
    }
    
    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:YES];
    
    [self.tableView reloadData];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.postSaveServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.postSaveServerProxy = nil;
        [self.parent setProgram:self.program withIndex:self.programIndex];
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        }
        self.runNowServerProxy = nil;
    }
    else if (serverProxy == self.stationDelayServerProxy) {
        self.stationDelayServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        } else {
            NSDictionary *paramsDic = (NSDictionary *)userInfo;
            self.program.delay = [[paramsDic objectForKey:@"delay"] intValue];
            self.program.delayOn = [[paramsDic objectForKey:@"delay_on"] intValue];
        }
    }
    else if (serverProxy == self.cycleAndSoakServerProxy) {
        self.cycleAndSoakServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        } else {
            NSDictionary *paramsDic = (NSDictionary *)userInfo;
            self.program.cycles = [[paramsDic objectForKey:@"cycles"] intValue];
            self.program.soak = [[paramsDic objectForKey:@"soak"] intValue];
            self.program.csOn = [[paramsDic objectForKey:@"cs_on"] intValue];
        }
    }
    
    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:YES];
    
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
