//
//  SettingsVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 17/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SettingsVC.h"
#import "Additions.h"
#import "ProgramsVC.h"
#import "ZonesVC.h"
#import "RainDelayVC.h"
#import "RestrictionsVC.h"
#import "UnitsVC.h"

@interface SettingsVC ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //TODO: Load current sprinkler from SettingsManager here and update content if needed.
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    else if (section == 1) {
        return 1;
    }
    else if (section == 2) {
        return 4;
    }
    
    return 0;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 20;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 1;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
//    return view;
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Programs Properties";
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Zone Properties";
        }
    }
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Rain Delay";
        }
    }
    
    if (indexPath.section == 2)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Device Settings";
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"Units";
        }
        if (indexPath.row == 2) {
            cell.textLabel.text = @"Date & Time";
        }
        if (indexPath.row == 3) {
            cell.textLabel.text = @"Security";
        }
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProgramsVC *programs = [[ProgramsVC alloc] init];
            programs.parent = self;
            [self.navigationController pushViewController:programs animated:YES];
        }
        if (indexPath.row == 1) {
            ZonesVC *zones = [[ZonesVC alloc] init];
            [self.navigationController pushViewController:zones animated:YES];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            RainDelayVC *rainDelay = [[RainDelayVC alloc] init];
            rainDelay.parent = self;
            [self.navigationController pushViewController:rainDelay animated:YES];
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 1) {
            UnitsVC *unitsVC = [[UnitsVC alloc] init];
            unitsVC.parent = self;
            [self.navigationController pushViewController:unitsVC animated:YES];
        }
        else if (indexPath.row == 2) {
        }
        else if (indexPath.row == 3) {
        }
    }
}

@end
