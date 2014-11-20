//
//  RainSensitivityVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityVC.h"
#import "RainSensitivityCell.h"
#import "FieldCapacityCell.h"
#import "Constants.h"
#import "ColoredBackgroundButton.h"

@interface RainSensitivityVC ()

@end

#pragma mark -

@implementation RainSensitivityVC

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Sensitivity";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RainSensitivityCell" bundle:nil] forCellReuseIdentifier:@"RainSensitivityCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"FieldCapacityCell" bundle:nil] forCellReuseIdentifier:@"FieldCapacityCell"];

    UIColor *sprinklerBlueColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0];
    
    [self.defaultsButton setCustomBackgroundColorFromComponents:(CGFloat[3]){1.0f, 1.0f, 1.0f}];
    [self.defaultsButton.layer setBorderColor:sprinklerBlueColor.CGColor];
    [self.defaultsButton.layer setBorderWidth:1.0];
    [self.defaultsButton setTitleColor:sprinklerBlueColor forState:UIControlStateNormal];
    [self.defaultsButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    
    [self.saveButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    
    self.tableView.tableHeaderView = self.rainSensitivityHeaderView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) return 83.0;
    if (indexPath.section == 1 && indexPath.row == 0) return 57.0;
    return 0.0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"Field Capacity";
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *RainSensitivityCellIdentifier = @"RainSensitivityCell";
    static NSString *FieldCapacityCellIdentifier = @"FieldCapacityCell";
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        RainSensitivityCell *cell = [tableView dequeueReusableCellWithIdentifier:RainSensitivityCellIdentifier];
        return cell;
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        FieldCapacityCell *cell = [tableView dequeueReusableCellWithIdentifier:FieldCapacityCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onDefaults:(id)sender {
    
}

- (IBAction)onSave:(id)sender {
    
}

@end
