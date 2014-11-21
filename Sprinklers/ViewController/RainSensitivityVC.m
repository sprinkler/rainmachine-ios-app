//
//  RainSensitivityVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityVC.h"
#import "RainSensitivityCell.h"
#import "FieldCapacityCell.h"
#import "Constants.h"
#import "Utils.h"
#import "ColoredBackgroundButton.h"
#import "ServerProxy.h"
#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"
#import "SettingsVC.h"
#import "MBProgressHUD.h"

@interface RainSensitivityVC ()

@property (strong, nonatomic) ServerProxy *requestProvisionServerProxy;
@property (strong, nonatomic) Provision *provision;

- (void)requestProvision;

@end

#pragma mark -

@implementation RainSensitivityVC {
    MBProgressHUD *hud;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Sensitivity";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RainSensitivityCell" bundle:nil] forCellReuseIdentifier:@"RainSensitivityCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"FieldCapacityCell" bundle:nil] forCellReuseIdentifier:@"FieldCapacityCell"];

    UIColor *sprinklerBlueColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0];
    
    [self.defaultsButton setCustomBackgroundColorFromComponents:(CGFloat[3]){1.0f, 1.0f, 1.0f}];
    [self.defaultsButton.layer setBorderColor:sprinklerBlueColor.CGColor];
    [self.defaultsButton.layer setBorderWidth:1.0];
    [self.defaultsButton setTitleColor:sprinklerBlueColor forState:UIControlStateNormal];
    [self.defaultsButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    
    [self.saveButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestProvision];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Methods

- (void)requestProvision {
    self.requestProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestProvisionServerProxy requestProvision];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    if (hud) return;
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestProvisionServerProxy) {
        self.provision = (Provision*)data;
        self.requestProvisionServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    hud = nil;
    
    self.tableView.tableHeaderView = (self.provision ? self.rainSensitivityHeaderView : nil);
    
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
    
#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.provision ? 2 : 0);
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) return 83.0;
    if (indexPath.section == 1 && indexPath.row == 0) return 62.0;
    return 0.0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"Field Capacity";
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *RainSensitivityCellIdentifier = @"RainSensitivityCell";
    static NSString *FieldCapacityCellIdentifier = @"FieldCapacityCell";
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        RainSensitivityCell *cell = [tableView dequeueReusableCellWithIdentifier:RainSensitivityCellIdentifier];
        cell.rainSensitivity = self.provision.location.rainSensitivity;
        return cell;
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        FieldCapacityCell *cell = [tableView dequeueReusableCellWithIdentifier:FieldCapacityCellIdentifier];
        cell.fieldCapacity = self.provision.location.wsDays;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)onDefaults:(id)sender {
    self.provision.location.rainSensitivity = 0.8;
    self.provision.location.wsDays = 2;
    [self.tableView reloadData];
}

- (IBAction)onSave:(id)sender {
    
}

@end
