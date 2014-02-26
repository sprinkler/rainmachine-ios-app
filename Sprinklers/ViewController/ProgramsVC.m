//
//  ProgramsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 05/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProgramsVC.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "Program.h"
#import "MBProgressHUD.h"
#import "Additions.h"
#import "Utils.h"
#import "SettingsVC.h"
#import "DailyProgramVC.h"
#import "ProgramListCell.h"
#import "AddNewCell.h"

@interface ProgramsVC () {
    MBProgressHUD *hud;
    UIBarButtonItem *editButton;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postDeleteServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *programs;

@end

@implementation ProgramsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Programs";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramListCell" bundle:nil] forCellReuseIdentifier:@"ProgramListCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];

    editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(edit)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    
    [self requestPrograms];
}

#pragma mark - Methods

- (void)requestPrograms
{
    [self startHud:nil];
    [self.serverProxy requestPrograms];
}

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (void)edit {
    [_tableView setEditing:!_tableView.editing];
    if (_tableView.editing) {
        self.postDeleteServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
        [editButton setTitle:@"Done"];
        [self.tableView reloadData];
    } else {
        self.postDeleteServerProxy = nil;
        [editButton setTitle:@"Edit"];
//        [self requestPrograms];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.postDeleteServerProxy) {
//        [self requestPrograms];
        [self programDeleted:data];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.programs = data;
    }
    
    [_tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];

//    if (serverProxy == self.postDeleteServerProxy) {
//        [self requestPrograms];
//    }
}

- (void)programDeleted:(NSNumber*)programId {
    for (int i = 0; i < self.programs.count - 1 ; i++) {
        if (((Program *)self.programs[i]).programId == [programId intValue]) {
            [self.programs removeObject:self.programs[i]];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            break;
        }
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
//    [self handleLoggedOutSprinklerError];
    [self.parent handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return tableView.editing ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) return 1;
    return self.programs.count - 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Program *program = self.programs[indexPath.row];
        [self startHud:nil];
        [self.postDeleteServerProxy deleteProgram:program.programId];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        return 20.0f;
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
        headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
        return headerView;
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ProgramListCell";
        ProgramListCell *cell = (ProgramListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        Program *program = self.programs[indexPath.row];
        cell.theTextLabel.text = program.name;
        cell.activeStateLabel.hidden = program.active;
        NSString *startHourAndMinute =  [Utils formattedTime:program.startTime forTimeFormat:program.timeFormat];
        if (!startHourAndMinute) {
            startHourAndMinute = @"";
        } else {
            startHourAndMinute = [@"at " stringByAppendingString:startHourAndMinute];
        }
        
        if ([program.weekdays isEqualToString:@"D"]) {
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"Daily %@", startHourAndMinute];
        }
        if ([program.weekdays isEqualToString:@"ODD"]) {
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"Odd days %@", startHourAndMinute];
        }
        if ([program.weekdays containsString:@"INT"]) {
            int nrDays;
            sscanf([program.weekdays UTF8String], "INT %d", &nrDays);
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"Every %d days %@", nrDays, startHourAndMinute];
        }
        if ([program.weekdays isEqualToString:@"EVD"]) {
            cell.theDetailTextLabel.text = [NSString stringWithFormat:@"Even days %@", startHourAndMinute];
        }
        if ([program.weekdays containsString:@","]) {
            NSString *daysString = [Utils daysStringFromWeekdaysFrequency:program.weekdays];
            if (daysString) {
                cell.theDetailTextLabel.text = [NSString stringWithFormat:@"%@ %@", daysString, startHourAndMinute];
            } else {
                cell.theDetailTextLabel.text = @"";
            }
        }
        
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            cell.theDetailTextLabel.textColor = [UIColor lightGrayColor];
        }
        
        return cell;
    }
    
    if (indexPath.section == 1) {
        AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddNewCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        [cell.plusLabel setCustomRMFontWithCode:icon_Plus size:24];

        cell.titleLabel.text = @"Add New Program";

        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        DailyProgramVC *dailyProgramVC = [[DailyProgramVC alloc] init];
        dailyProgramVC.program = self.programs[indexPath.row];
        dailyProgramVC.parent = self;
        dailyProgramVC.programIndex = indexPath.row;
        [self.navigationController pushViewController:dailyProgramVC animated:YES];
    } else {
        DailyProgramVC *dailyProgramVC = [[DailyProgramVC alloc] init];
        dailyProgramVC.parent = self;
        dailyProgramVC.programIndex = -1;
        [self.navigationController pushViewController:dailyProgramVC animated:YES];
    }
}

- (void)addProgram:(Program*)p
{
    [self.programs addObject:p];
}

- (void)setProgram:(Program*)p withIndex:(int)i
{
    if (i >= 0) {
        [self.programs replaceObjectAtIndex:i withObject:p];
    }
}

- (int)serverTimeFormat
{
    if ([self.programs count] > 0) {
        Program *p = self.programs[0];
        return p.timeFormat;
    }
    
    // As default return the AM/PM time format. It's more natural for USA people.
    return 1;
}

@end
