//
//  DashboardGraphAllDataVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 07/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DashboardGraphAllDataVC.h"
#import "GraphDescriptor.h"
#import "GraphDataSource.h"
#import "GraphDataFormatter.h"
#import "GraphTitleAreaDescriptor.h"

#pragma mark -

@interface DashboardGraphAllDataVC ()

@property (nonatomic, strong) GraphDataFormatter *graphDataFormatter;
@end

#pragma mark -

@implementation DashboardGraphAllDataVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.graphDescriptor.titleAreaDescriptor.title;
    
    self.graphDataFormatter = [self.graphDescriptor.dataSource.graphDataFormatterClass new];
    self.graphDataFormatter.graphDataSourceValues = self.graphDescriptor.dataSource.valuesForGraphDataFormatter;
    
    [self.graphDataFormatter registerFormatterCellsInTableView:self.tableView];
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [self.graphDataFormatter numberOfSection];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.graphDataFormatter numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return [self.graphDataFormatter heighForRowAtIndexPath:indexPath];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [self.graphDataFormatter cellForRowAtIndexPath:indexPath inTableView:tableView];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
