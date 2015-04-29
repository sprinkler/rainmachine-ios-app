//
//  ProvisionTimezonesListVC.m
//  Sprinklers
//
//  Created by Fabian Matyas on 23/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ProvisionTimezonesListVC.h"
#import "+UIDevice.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "Utils.h"

@interface ProvisionTimezonesListVC ()

@property (nonatomic, strong) NSArray *timezones;
@property (nonatomic, strong) NSMutableArray *filteredTimeZones;
@property (strong, nonatomic) BaseWizardVC *errorHandlingHelper;

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

- (void)reloadFilteredTimezonesForSearchText:(NSString*)searchText;

@end

@implementation ProvisionTimezonesListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Timezone";

    self.errorHandlingHelper = [BaseWizardVC new];
    [self.errorHandlingHelper setWizardNavBarForVC:self];
    self.errorHandlingHelper.delegate = self;

    self.timezones = [NSTimeZone knownTimeZoneNames];
    
    self.navigationItem.titleView = self.searchBar;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(onCancel:)];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (self.isPartOfWizard) {
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            self.searchBar.tintColor = [UIColor darkTextColor];
            self.searchBar.barTintColor = [UIColor whiteColor];
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
            self.navigationController.navigationBar.translucent = NO;
        }
        else {
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        }
    } else {
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            self.searchBar.tintColor = [UIColor darkTextColor];
            self.searchBar.barTintColor = [UIColor whiteColor];
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
            self.navigationController.navigationBar.translucent = NO;
        }
        else {
            self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        }
    }
    
    [self reloadFilteredTimezonesForSearchText:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
    [self reloadFilteredTimezonesForSearchText:self.searchBar.text];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredTimeZones.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeZoneCell"];
    if (!cell) cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"timeZoneCell"];

    cell.textLabel.text = self.filteredTimeZones[indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSString *timeZoneName = self.filteredTimeZones[indexPath.row];
    [self.delegate timeZoneSelected:timeZoneName];
    
    if (self.isPartOfWizard) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        ServerProxy *provisionTimezoneServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        [provisionTimezoneServerProxy setTimezone:timeZoneName];
    }
    
    [self.searchBar resignFirstResponder];
}

#pragma mark Search bar delegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
    [self reloadFilteredTimezonesForSearchText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Helper methods

- (void)reloadFilteredTimezonesForSearchText:(NSString*)searchText {
    self.filteredTimeZones = [NSMutableArray array];
    
    if (!searchText.length) {
        [self.filteredTimeZones addObjectsFromArray:self.timezones];
        [self.tableView reloadData];
        return;
    }
    
    for (NSString *timezone in self.timezones) {
        if ([timezone rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.filteredTimeZones addObject:timezone];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)onCancel:(id)sender {
    [self.searchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SprinklerResponseProtocol

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.errorHandlingHelper handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.errorHandlingHelper handleLoggedOutSprinklerError];
}

@end
