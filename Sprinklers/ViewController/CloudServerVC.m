//
//  CloudServerVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 30/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "CloudServerVC.h"
#import "Constants.h"
#import "Additions.h"

@interface CloudServerVC ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *cloudServers;
@property (strong, nonatomic) NSMutableArray *cloudServerNames;
@property (assign, nonatomic) NSUInteger selectedCloudServerIndex;

@end

#pragma mark -

@implementation CloudServerVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Choose cloud server";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cloudServers = [NSMutableArray new];
    [self.cloudServers addObject:kCloudProxyFinderStagingURL];
    [self.cloudServers addObject:kCloudProxyFinderURL];
    
    self.cloudServerNames = [NSMutableArray new];
    [self.cloudServerNames addObject:kCloudProxyFinderStagingName];
    [self.cloudServerNames addObject:kCloudProxyFinderName];
    
    NSString *selectedServer = [[NSUserDefaults standardUserDefaults] objectForKey:kCloudProxyFinderURLKey];
    if (!selectedServer.length) selectedServer = kCloudProxyFinderStagingURL;
    self.selectedCloudServerIndex = [self.cloudServers indexOfObject:selectedServer];
    
    [_tableView registerNib:[UINib nibWithNibName:@"SimpleCell" bundle:nil] forCellReuseIdentifier:@"SimpleCell"];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cloudServers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SimpleCell";
    UITableViewCell *cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = self.cloudServerNames[indexPath.row];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        cell.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    }
    
    cell.accessoryType = (indexPath.row == self.selectedCloudServerIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *oldSelectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedCloudServerIndex inSection:0]];
    self.selectedCloudServerIndex = indexPath.row;
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedCloudServerIndex inSection:0]];
    
    oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.cloudServers[self.selectedCloudServerIndex] forKey:kCloudProxyFinderURLKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
