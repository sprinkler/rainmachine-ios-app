//
//  DataSourcesParserVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DataSourcesParserVC.h"
#import "SettingsVC.h"
#import "Parser.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface DataSourcesParserVC ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)refreshProgressHUD;

@end

#pragma mark -

@implementation DataSourcesParserVC

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.parser.name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)refreshProgressHUD {
    
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.parser.params.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 56.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"ParserDetailCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    ParserParameter *parameter = self.parser.params[indexPath.row];
    cell.textLabel.text = parameter.name;
    
    if (parameter.parameterType == ParserParameterTypeUnknown) cell.accessoryView = nil;
    else if (parameter.parameterType == ParserParameterTypeNull) cell.accessoryView = nil;
    else if (parameter.parameterType == ParserParameterTypeBoolean) {
        UISwitch *accessorySwitch = [UISwitch new];
        accessorySwitch.on = [parameter.value boolValue];
        cell.accessoryView = accessorySwitch;
    }
    else if (parameter.parameterType == ParserParameterTypeNumber) {
        UILabel *accessoryLabel = [UILabel new];
        accessoryLabel.text = [parameter.value stringValue];
        accessoryLabel.font = [UIFont systemFontOfSize:17.0];
        [accessoryLabel sizeToFit];
        cell.accessoryView = accessoryLabel;
    }
    else if (parameter.parameterType == ParserParameterTypeString) {
        UILabel *accessoryLabel = [UILabel new];
        accessoryLabel.text = parameter.value;
        accessoryLabel.font = [UIFont systemFontOfSize:11.0];
        [accessoryLabel sizeToFit];
        cell.accessoryView = accessoryLabel;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
