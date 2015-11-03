//
//  WindSensitivityVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 23/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WindSensitivityVC.h"
#import "WindSensitivityCell.h"
#import "Additions.h"
#import "Constants.h"
#import "Utils.h"
#import "ColoredBackgroundButton.h"
#import "ServerProxy.h"
#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"
#import "SettingsVC.h"
#import "MBProgressHUD.h"

const double WindSensitivityDefaultWindSensitivity  = 0.5;

@interface WindSensitivityVC ()

@property (nonatomic, strong) ServerProxy *requestProvisionServerProxy;
@property (nonatomic, strong) ServerProxy *saveWindSensitivityServerProxy;
@property (nonatomic, strong) Provision *provision;

- (void)requestProvision;
- (void)saveWindSensitivity;

@end

#pragma mark -

@implementation WindSensitivityVC {
    MBProgressHUD *hud;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Wind Sensitivity";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"WindSensitivityCell" bundle:nil] forCellReuseIdentifier:@"WindSensitivityCell"];
    
    UIColor *sprinklerBlueColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0];
    
    [self.defaultsButton setCustomBackgroundColorFromComponents:(CGFloat[3]){1.0f, 1.0f, 1.0f}];
    [self.defaultsButton.layer setBorderColor:sprinklerBlueColor.CGColor];
    [self.defaultsButton.layer setBorderWidth:1.0];
    [self.defaultsButton setTitleColor:sprinklerBlueColor forState:UIControlStateNormal];
    [self.defaultsButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    
    [self.saveButton setCustomBackgroundColorFromComponents:kSprinklerBlueColor];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    
    [self requestProvision];
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

- (void)saveWindSensitivity {
    self.saveWindSensitivityServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveWindSensitivityServerProxy saveWindSensitivityFromProvision:self.provision];
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
    
    if (serverProxy == self.saveWindSensitivityServerProxy) {
        self.saveWindSensitivityServerProxy = nil;
    }
    
    if (!self.requestProvisionServerProxy && !self.saveWindSensitivityServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    if (!self.requestProvisionServerProxy && self.provision) {
        self.tableView.tableHeaderView = self.windSensitivityHeaderView;
        [self.tableView reloadData];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestProvisionServerProxy) self.requestProvisionServerProxy = nil;
    else if (serverProxy == self.saveWindSensitivityServerProxy) self.saveWindSensitivityServerProxy = nil;
    
    if (!self.requestProvisionServerProxy && !self.saveWindSensitivityServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.parent handleLoggedOutSprinklerError];
}

#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.provision ? 1 : 0);
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) return 83.0;
    return 0.0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *WindSensitivityCellIdentifier = @"WindSensitivityCell";
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        WindSensitivityCell *cell = [tableView dequeueReusableCellWithIdentifier:WindSensitivityCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.windSensitivity = (self.provision.location.windSensitivity > 1.0 ? 1.0 : self.provision.location.windSensitivity);
        cell.delegate = self;
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (void)onCellSliderValueChanged:(UISlider*)slider {
    self.provision.location.windSensitivity = (int)(slider.value * 100.0) / 100.0;
}

- (IBAction)onDefaults:(id)sender {
    self.provision.location.windSensitivity = WindSensitivityDefaultWindSensitivity;
    [self.tableView reloadData];
}

- (IBAction)onSave:(id)sender {
    [self saveWindSensitivity];
}

@end
