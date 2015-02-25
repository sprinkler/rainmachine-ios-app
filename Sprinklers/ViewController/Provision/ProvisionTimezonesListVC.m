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
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *coloredView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) BaseModalProvisionVC *errorHandlingHelper;

@end

@implementation ProvisionTimezonesListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Timezone";
//    [[self view] setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.errorHandlingHelper = [BaseModalProvisionVC new];
    [self.errorHandlingHelper setWizardNavBarForVC:self];
    self.errorHandlingHelper.delegate = self;

    self.timezones = [NSTimeZone knownTimeZoneNames];
    
    self.navigationItem.titleView = self.searchDisplayController.searchBar;
    self.searchDisplayController.searchBar.showsCancelButton = YES;
    
    if (self.isPartOfWizard) {
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            self.searchDisplayController.searchBar.tintColor = [UIColor darkTextColor];
            self.searchDisplayController.searchBar.barTintColor = [UIColor whiteColor];
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.200000 green:0.200000 blue:0.203922 alpha:1];
            self.navigationController.navigationBar.translucent = NO;
        }
        else {
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        }
    } else {
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            self.searchDisplayController.searchBar.tintColor = [UIColor darkTextColor];
            self.searchDisplayController.searchBar.barTintColor = [UIColor whiteColor];
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
            self.navigationController.navigationBar.translucent = NO;
        }
        else {
            self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.searchDisplayController.searchBar.text = self.delegate.timeZoneName;
    
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
//    if (tableView == self.tableView) {
//        return 0;//self.timezones.count;
//    }
    
    return self.filteredTimeZones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeZoneCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"timeZoneCell"];
    }

    NSString *timeZone;
    
//    if (tableView == self.tableView) {
//        timeZone = self.timezones[indexPath.row];
//    } else {
        timeZone = self.filteredTimeZones[indexPath.row];
//    }
    cell.textLabel.text = timeZone;
    
    return cell;
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *timeZoneName = self.filteredTimeZones[indexPath.row];
    // Navigation logic may go here, for example:
//    if (tableView == self.tableView) {
//        [self.delegate timeZoneSelected:self.timezones[indexPath.row]];
//    } else {
        [self.delegate timeZoneSelected:timeZoneName];
//    }
    
    if (self.isPartOfWizard) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        ServerProxy *provisionTimezoneServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        [provisionTimezoneServerProxy setTimezone:timeZoneName];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
    self.filteredTimeZones = [NSMutableArray array];
    for (NSString *text in self.timezones) {
        if ([text rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.filteredTimeZones addObject:text];
        }
    }
    
    [self.tableView reloadData];
    
    return NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
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

- (void)loggedOut
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.errorHandlingHelper handleLoggedOutSprinklerError];
}

@end
