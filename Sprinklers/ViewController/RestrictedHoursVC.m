//
//  RestrictedHoursVC.m
//  Sprinklers
//
//  Created by Adrian Manolache on 18/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictedHoursVC.h"
#import "RestrictionsVC.h"
#import "RestrictionsCell.h"
#import "NewRestrictionVC.h"
#import "AddNewCell.h"
#import "HourlyRestriction.h"
#import "Additions.h"
#import "Utils.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"

@interface RestrictedHoursVC ()

@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) ServerProxy *deleteHourlyRestrictionServerProxy;
@property (nonatomic, strong) ServerProxy *requestHourlyRestrictionsServerProxy;
@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (strong, nonatomic) HourlyRestriction *unsavedRestriction;
@property (assign, nonatomic) int unsavedRestrictionIndex;

- (IBAction)edit:(id)sender;

@end

#pragma mark -

@implementation RestrictedHoursVC {
    MBProgressHUD *hud;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Restricted hours";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = self.editBarButtonItem;
    
    [_tableView registerNib:[UINib nibWithNibName:@"RestrictionsCell" bundle:nil] forCellReuseIdentifier:@"RestrictionsCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"AddNewCell" bundle:nil] forCellReuseIdentifier:@"AddNewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tableView setEditing:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.unsavedRestriction) {
        [self pushVCForRestriction:self.unsavedRestriction withIndex:self.unsavedRestrictionIndex showInitialUnsavedAlert:YES];
        self.unsavedRestriction = nil;
    } else {
        [self requestHourlyRestrictions];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Methods

- (void)deleteHourlyRestriction:(HourlyRestriction*)restriction {
    self.deleteHourlyRestrictionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.deleteHourlyRestrictionServerProxy deleteHourlyRestriction:restriction];
    [self startHud:nil];
}

- (void)requestHourlyRestrictions {
    self.requestHourlyRestrictionsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestHourlyRestrictionsServerProxy requestHourlyRestrictions];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    if (hud) return;
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - Action

- (IBAction)edit:(id)sender {
    [self.tableView setEditing:!self.tableView.editing];
    if (self.tableView.editing) [self.editBarButtonItem setTitle:@"Done"];
    else [self.editBarButtonItem setTitle:@"Edit"];
    [self.tableView reloadData];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.deleteHourlyRestrictionServerProxy) {
        self.deleteHourlyRestrictionServerProxy = nil;
        [self requestHourlyRestrictions];
        return;
    }
    
    if (serverProxy == self.requestHourlyRestrictionsServerProxy) {
        self.hourlyRestrictions = (NSArray*)data;
        self.requestHourlyRestrictionsServerProxy = nil;
    }
    
    if (!self.deleteHourlyRestrictionServerProxy && !self.requestHourlyRestrictionsServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    [self.tableView reloadData];
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.parent handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.hourlyRestrictions.count;
    if (section == 1) return 1;
    return 0;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) return 56.0;
    if (indexPath.section == 1) return 44.0;
    return 44.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        static NSString *RestrictionsCellIdentifier = @"RestrictionsCell";
        
        RestrictionsCell *cell = [tableView dequeueReusableCellWithIdentifier:RestrictionsCellIdentifier];
        HourlyRestriction *restriction = self.hourlyRestrictions[indexPath.row];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.restrictionNameLabel.text = [self.parent daysDescriptionForHourlyRestriction:restriction];
        cell.restrictionDescriptionLabel.text = [self.parent timeDescriptionForHourlyRestriction:restriction];
        cell.restrictionNameLabel.hidden = NO;
        cell.restrictionCenteredNameLabel.hidden = YES;
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) cell.restrictionDescriptionLabel.textColor = [UIColor lightGrayColor];
        
        return cell;
    }
    else if (indexPath.section == 1) {
        static NSString *AddNewCellIdentifier = @"AddNewCell";
        
        AddNewCell *cell = [tableView dequeueReusableCellWithIdentifier:AddNewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        [cell.plusLabel setCustomRMFontWithCode:icon_Add size:24];
        
        cell.titleLabel.text = @"Add New Restriction";
        
        [cell.plusLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
        [cell.titleLabel setTextColor:[UIColor colorWithRed:kWateringGreenButtonColor[0] green:kWateringGreenButtonColor[1] blue:kWateringGreenButtonColor[2] alpha:1]];
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        [self pushVCForRestriction:self.hourlyRestrictions[indexPath.row] withIndex:(int)indexPath.row showInitialUnsavedAlert:NO];
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        NewRestrictionVC *newRestrictionVC = [[NewRestrictionVC alloc] init];
        newRestrictionVC.parent = self;
        [self.navigationController pushViewController:newRestrictionVC animated:YES];
    }
}

- (void)pushVCForRestriction:(HourlyRestriction*)r withIndex:(int)i showInitialUnsavedAlert:(BOOL)showInitialUnsavedAlert
{
    NewRestrictionVC *newRestrictionVC = [[NewRestrictionVC alloc] init];
    newRestrictionVC.restriction = r;
    if (showInitialUnsavedAlert) {
        if (i != -1) {
            newRestrictionVC.restrictionCopyBeforeSave = self.hourlyRestrictions[i];
        }
    }
    newRestrictionVC.parent = self;
    newRestrictionVC.parent = self;
    newRestrictionVC.restrictionIndex = i;
    newRestrictionVC.showInitialUnsavedAlert = showInitialUnsavedAlert;
    [self.navigationController pushViewController:newRestrictionVC animated:!showInitialUnsavedAlert];
}

- (void)setUnsavedRestriction:(HourlyRestriction*)restriction withIndex:(int)i
{
    self.unsavedRestriction = restriction;
    self.unsavedRestrictionIndex = i;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return (indexPath.section == 0);
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteHourlyRestriction:self.hourlyRestrictions[indexPath.row]];
    }
}

@end
