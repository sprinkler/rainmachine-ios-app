//
//  VegetationTypeVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 04/03/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "VegetationTypeVC.h"
#import "Constants.h"
#import "ZonePropertiesVC.h"
#import "+UIDevice.h"

@interface VegetationTypeVC ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation VegetationTypeVC

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
    
	// Do any additional setup after loading the view.
    [_tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
    
    self.title = @"Vegetation type";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.parent vegetationTypeVCWillDissapear:self];
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
    cell.textLabel.text = kVegetationType[indexPath.row + 2];
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerWaterColor[0] green:kSprinklerWaterColor[1] blue:kSprinklerWaterColor[2] alpha:1];
    }
    cell.accessoryType = (indexPath.row == (_vegetationType - 2)) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:_vegetationType - 2 inSection:indexPath.section];
    UITableViewCell *oldCell = [self.tableView cellForRowAtIndexPath:oldIndexPath];
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    self.vegetationType = 2 + indexPath.row;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
