//
//  MonthsVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 27/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "MonthsVC.h"
#import "Constants.h"
#import "ProgramVC.h"
#import "+UIDevice.h"

@interface MonthsVC ()

@property (nonatomic, strong) NSArray *monthsNames;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MonthsVC

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
    
    self.monthsNames = @[monthsOfYear[0], monthsOfYear[1], monthsOfYear[2], monthsOfYear[3], monthsOfYear[4], monthsOfYear[5], monthsOfYear[6], monthsOfYear[7], monthsOfYear[8], monthsOfYear[9], monthsOfYear[10], monthsOfYear[11]];
    if ((!self.selectedMonths) || ([self.selectedMonths count] == 0)) {
        self.selectedMonths = [NSMutableArray arrayWithObjects:
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 nil];
    }
    
    self.title = @"Select months";
    
    // Do any additional setup after loading the view.
    [_tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.parent monthsVCWillDissapear:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SimpleCell";
    UITableViewCell *cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.monthsNames[indexPath.row];
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    cell.accessoryType = [_selectedMonths[indexPath.row] intValue] == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *newValue = [NSNumber numberWithInt:1 - [_selectedMonths[indexPath.row] intValue]];
    [_selectedMonths replaceObjectAtIndex:indexPath.row withObject:newValue];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryType = [_selectedMonths[indexPath.row] intValue] == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
