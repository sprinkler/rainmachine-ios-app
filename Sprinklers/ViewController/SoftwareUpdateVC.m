//
//  SoftwareUpdateVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 01/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "SoftwareUpdateVC.h"
#import "ColoredBackgroundButton.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "UpdateManager.h"
#import "Utils.h"
#import "APIVersion.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface SoftwareUpdateVC ()

@property (nonatomic, strong) UpdateManager *updateManager;
@property (nonatomic, strong) ServerProxy *requestVersionServerProxy;
@property (nonatomic, strong) APIVersion *apiVersion;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)requestVersion;
- (void)checkForUpdate;
- (void)refreshProgressHUD;
- (void)refreshUI;

@property (nonatomic, assign) BOOL checkingForUpdate;
@property (nonatomic, assign) BOOL updateAvailable;
@property (nonatomic, strong) NSString *updateAvailableVersion;
@property (nonatomic, strong) NSString *updateCurrentVersion;

@end

#pragma mark - 

@implementation SoftwareUpdateVC

#pragma mark - Init

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Software Update";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.updateButton.customBackgroundColorFromComponents = kSprinklerBlueColor;
    self.updateContainerView.hidden = YES;
    self.checkingForUpdate = NO;
    self.updateManager = [[UpdateManager alloc] initWithDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkForUpdate];
    [self refreshProgressHUD];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.updateManager stopAll];
    [self.requestVersionServerProxy cancelAllOperations];
    self.requestVersionServerProxy = nil;
    self.checkingForUpdate = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)requestVersion {
    self.requestVersionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestVersionServerProxy requestAPIVersion];
}

- (void)checkForUpdate {
    self.checkingForUpdate = YES;
    [self requestVersion];
    [self.updateManager poll];
}

- (void)refreshProgressHUD {
    BOOL shouldShowProgressHUD = (self.requestVersionServerProxy != nil || self.checkingForUpdate);
    if (shouldShowProgressHUD && !self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    else if (!shouldShowProgressHUD && self.hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.hud = nil;
    }
}

- (void)refreshUI {
    BOOL shouldRefreshUI = (self.requestVersionServerProxy == nil && !self.checkingForUpdate);
    if (shouldRefreshUI) {
        self.updateContainerView.hidden = NO;
        self.updateVersionLabel.text = (self.updateAvailable ? [NSString stringWithFormat:@"New update found: %@",self.updateAvailableVersion] : @"No updates found.");
        self.currentVersionLabel.text = [NSString stringWithFormat:@"Current version: %@",(self.updateAvailable ? self.updateCurrentVersion : self.apiVersion.swVer)];
        [self.updateButton setTitle:(self.updateAvailable ? @"Update Now" : @"Check for update") forState:UIControlStateNormal];
    }
}

#pragma mark - Actions

- (IBAction)updateAction:(id)sender {
    if (self.updateAvailable) [self.updateManager startUpdate];
    else {
        [self checkForUpdate];
        [self refreshProgressHUD];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestVersionServerProxy) {
        self.apiVersion = data;
        self.requestVersionServerProxy = nil;
    }
    [self refreshProgressHUD];
    [self refreshUI];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    if (serverProxy == self.requestVersionServerProxy) self.requestVersionServerProxy = nil;
    [self refreshProgressHUD];
    [self refreshUI];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UpdateManager delegate

- (void)sprinklerVersionReceivedMajor:(int)major minor:(int)minor subMinor:(int)subMinor {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.updateManager.serverAPIMainVersion = major;
    appDelegate.updateManager.serverAPISubVersion = minor;
    appDelegate.updateManager.serverAPIMinorSubVersion = subMinor;
}

- (void)updateNowAvailable:(BOOL)available withVersion:(NSString *)the_new_version currentVersion:(NSString*)the_current_version {
    self.updateAvailable = available;
    self.updateAvailableVersion = the_new_version;
    self.updateCurrentVersion = the_current_version;
    self.checkingForUpdate = NO;
    [self refreshProgressHUD];
    [self refreshUI];
}

@end
