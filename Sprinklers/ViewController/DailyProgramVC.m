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
#import "MBProgressHUD.h"
#import "ServerResponse.h"
#import "ProgramsVC.h"

@interface DailyProgramVC ()
{
    MBProgressHUD *hud;
    BOOL setRunNowActivityIndicator;
    BOOL runNowButtonEnabledState;
}

@property (strong, nonatomic) ServerProxy *runNowServerProxy;
@property (strong, nonatomic) ServerProxy *postSaveServerProxy;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

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

    setRunNowActivityIndicator = NO;
    runNowButtonEnabledState = YES;
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
}

- (void)save
{
    self.postSaveServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [self.postSaveServerProxy saveProgram:self.program];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
         case 0:
            return 1;
            break;
        case 1:
            return 3;
            break;
        case 2:
            return 4;
            break;
        case 3:
            return 2;
            break;
        case 4:
            return 2;
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 22.0;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 60;
            break;
//        case 1:
//            return 3;
//            break;
//        case 2:
//            return 4;
//            break;
//        case 3:
//            return 2;
//            break;
            
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
            [cell.button setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
            
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
                return cell;
            }
            else if (indexPath.row == 1) {
                static NSString *CellIdentifier = @"ProgramCellType2";
                ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                [cell.theDetailLabel removeFromSuperview];
                return cell;
            }
            else if (indexPath.row == 2) {
                static NSString *CellIdentifier = @"ProgramCellType2";
                ProgramCellType2 *cell = (ProgramCellType2*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                return cell;
            }
        }
            break;
        case 2: {
            static NSString *CellIdentifier = @"ProgramCellType3";
            ProgramCellType3 *cell = (ProgramCellType3*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.theTextLabel.text = @"Weekdays";
            cell.theDetailTextLabel.text = @"Mon, Tue, Wed";
            cell.checkMarkImage.image = [UIImage imageNamed:@"checkbox-selected"];
            return cell;
        }
        case 3: {
            static NSString *CellIdentifier = @"ProgramCellType4";
            ProgramCellType4 *cell = (ProgramCellType4*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.theTextLabel.text = @"START TIME";
            cell.timeLabel.text = @"0h 0m 0s abcdef";
            return cell;
        }
            break;
        case 4: {
            static NSString *CellIdentifier = @"ProgramCellType5";
            ProgramCellType5 *cell = (ProgramCellType5*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            return cell;
        }
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ProxyService delegate

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy {
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    if (serverProxy == self.postSaveServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.postSaveServerProxy = nil;
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
    }

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy {
    if (serverProxy == self.postSaveServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.postSaveServerProxy = nil;
    }
    else if (serverProxy == self.runNowServerProxy) {
        self.runNowServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        }
        self.runNowServerProxy = nil;
    }

    [self updateRunNowButtonActiveStateTo:YES setActivityIndicator:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
