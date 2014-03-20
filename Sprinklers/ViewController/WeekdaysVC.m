//
//  WeekdaysVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 24/02/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "WeekdaysVC.h"
#import "Constants.h"
#import "ProgramVC.h"
#import "+UIDevice.h"

@interface WeekdaysVC ()

@property (nonatomic, strong) NSArray *weekdaysNames;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation WeekdaysVC

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

    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale: [NSLocale currentLocale]];
    self.weekdaysNames = [df weekdaySymbols];
    if ((!self.selectedWeekdays) || ([self.selectedWeekdays count] == 0)) {
        self.selectedWeekdays = [NSMutableArray arrayWithObjects:
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 @"0",
                                 nil];
    }
    
    self.title = @"Select week days";
    
	// Do any additional setup after loading the view.
    [_tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.parent weekdaysVCWillDissapear:self];
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
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SimpleCell";
    UITableViewCell *cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = self.weekdaysNames[indexPath.row];
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerWaterColor[0] green:kSprinklerWaterColor[1] blue:kSprinklerWaterColor[2] alpha:1];
    }
    cell.accessoryType = [_selectedWeekdays[indexPath.row] intValue] == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *newValue = [NSNumber numberWithInt:1 - [_selectedWeekdays[indexPath.row] intValue]];
    [_selectedWeekdays replaceObjectAtIndex:indexPath.row withObject:newValue];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryType = [_selectedWeekdays[indexPath.row] intValue] == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
