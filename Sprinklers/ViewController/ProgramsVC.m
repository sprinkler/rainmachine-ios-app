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

@interface ProgramsVC () {
    MBProgressHUD *hud;
    NSMutableArray *programs;
    BOOL editing;
    UIBarButtonItem *editButton;
}

@property (strong, nonatomic) ServerProxy *serverProxy;
@property (strong, nonatomic) ServerProxy *postServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

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
    
    editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(edit)];
    self.navigationItem.rightBarButtonItem = editButton;
    editing = NO;
    
    self.serverProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:NO];
    self.postServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    
    [self startHud:nil];
    [self.serverProxy requestPrograms];
}

#pragma mark - Methods

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

- (void)edit {
    editing = !editing;
    [_tableView setEditing:editing];
    if (editing) {
        [editButton setTitle:@"Done"];
    }
    else {
        [editButton setTitle:@"Edit"];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    programs = data;
    [_tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)programDeleted:(int)programId {
    for (int i = 0; i < programs.count; i++) {
        if (((Program *)programs[i]).programId == programId) {
            [programs removeObject:programs[i]];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) return 1;
    return programs.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Program *program = programs[indexPath.row];
        [self startHud:nil];
        [_serverProxy deleteProgram:program.programId];
    }
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
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        Program *program = programs[indexPath.row];
        cell.textLabel.text = program.name;
        
        if ([program.weekdays isEqualToString:@"D"]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Daily %@", program.startTime];
        }
        if ([program.weekdays isEqualToString:@"ODD"]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Odd days %@", program.startTime];
        }
        if ([program.weekdays isEqualToString:@"EVD"]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Even days %@", program.startTime];
        }
        if ([program.weekdays containsString:@","]) {
            NSArray *vals = [program.weekdays componentsSeparatedByString:@","];
            if (vals && vals.count == 7) {
                NSDateFormatter * df = [[NSDateFormatter alloc] init];
                [df setLocale: [NSLocale currentLocale]];
                NSArray *weekdays = [df weekdaySymbols];
                NSString *daysString = @"";
                if ([vals[0] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[0]];
                }
                if ([vals[1] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[1]];
                }
                if ([vals[2] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[2]];
                }
                if ([vals[3] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[3]];
                }
                if ([vals[4] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[4]];
                }
                if ([vals[5] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[5]];
                }
                if ([vals[6] isEqualToString:@"1"]) {
                    daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[6]];
                }
                if ([daysString hasSuffix:@","]) {
                    daysString = [daysString substringToIndex:daysString.length - 2];
                }
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", daysString, program.startTime];
            }
        }
        
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
        
        return cell;
    }
    
    if (indexPath.section == 1) {
        static NSString *CellIdentifier2 = @"Cell2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier2];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = @"Add New Program";

        return cell;
    }
    
    return nil;
}

@end
