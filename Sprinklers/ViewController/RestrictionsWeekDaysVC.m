//
//  RestrictionsWeekDaysVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 14/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsWeekDaysVC.h"
#import "RestrictionsCell.h"
#import "+UIDevice.h"

@interface RestrictionsWeekDaysVC ()

@end

@implementation RestrictionsWeekDaysVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_tableView registerNib:[UINib nibWithNibName: @"RestrictionsCell" bundle:nil] forCellReuseIdentifier: @"RestrictionsCell"];
        
    self.title = @"Restricted Days";
    self.restrictedDays = @"0100001";   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    headerView.backgroundColor = [UIColor colorWithRed:229.0f / 255.0f green:229.0f / 255.0f blue:229.0f / 255.0f alpha:1.0f];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"RestrictionsCell";
    RestrictionsCell *cell = (RestrictionsCell*)[tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    NSString* weekDays[] = {@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday",@"Saturday", @"Sunday"};
    
    cell.onOffSwitch.on = [self.restrictedDays characterAtIndex: indexPath.row] == '1';
    
    cell.textLabel.text = weekDays[indexPath.row];
    cell.detailTextLabel.text = @"";
    
    if ([[UIDevice currentDevice] iOSGreaterThan: 7]) {
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        default:
            break;
    }
}

@end
