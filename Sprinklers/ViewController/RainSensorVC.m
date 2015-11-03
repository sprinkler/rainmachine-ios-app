//
//  RainSensorVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 23/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "RainSensorVC.h"
#import "Additions.h"
#import "Utils.h"
#import "ServerProxy.h"
#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface RainSensorVC ()

@property (nonatomic, strong) ServerProxy *requestProvisionServerProxy;
@property (nonatomic, strong) ServerProxy *saveRainSensorServerProxy;
@property (nonatomic, strong) Provision *provision;

- (void)initializeUserInterface;
- (void)hideRainSensorView;
- (void)showRainSensorView;
- (void)updateRainSensorImageVisibility;

@property (nonatomic, readonly) BOOL rainSensorViewShown;

- (void)requestProvision;
- (void)saveRainSensor;

@end

#pragma mark -

@implementation RainSensorVC {
    MBProgressHUD *hud;
}

#pragma mark - Init

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Rain Sensor";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeUserInterface];
    [self hideRainSensorView];
    [self requestProvision];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper methods

- (void)initializeUserInterface {
    self.rainSensorSwitch.tintColor = [UIColor colorWithWhite:0.81 alpha:1.0];
}

- (void)hideRainSensorView {
    self.rainSensorScrollView.hidden = YES;
}

- (void)showRainSensorView {
    if (self.rainSensorContentView.superview != self.rainSensorScrollView) {
        self.rainSensorContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.rainSensorContentView.frame = CGRectMake(0.0, 0.0, self.rainSensorScrollView.bounds.size.width, self.rainSensorContentView.frame.size.height);
        self.rainSensorScrollView.contentSize = CGSizeMake(0.0, self.rainSensorContentView.frame.size.height);
        [self.rainSensorScrollView addSubview:self.rainSensorContentView];
    }
    
    self.rainSensorSwitch.on = self.provision.system.useRainSensor;
    self.rainSensorScrollView.hidden = NO;
    
    [self updateRainSensorImageVisibility];
}

- (void)updateRainSensorImageVisibility {
    self.rainSensorDescriptionLabel.hidden = !self.provision.system.useRainSensor;
    self.rainSensorImageView.hidden = !self.provision.system.useRainSensor;
}

- (BOOL)rainSensorViewShown {
    return !self.rainSensorScrollView.hidden;
}

- (void)requestProvision {
    self.requestProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestProvisionServerProxy requestProvision];
    [self startHud:nil];
}

- (void)saveRainSensor {
    self.saveRainSensorServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveRainSensorServerProxy setUseRainSensor:self.rainSensorSwitch.isOn];
    [self startHud:nil];
}

- (void)startHud:(NSString*)text {
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
    
    if (serverProxy == self.saveRainSensorServerProxy) {
        self.provision.system.useRainSensor = self.rainSensorSwitch.isOn;
        self.saveRainSensorServerProxy = nil;
        [self updateRainSensorImageVisibility];
    }
    
    if (!self.requestProvisionServerProxy && !self.saveRainSensorServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    if (!self.requestProvisionServerProxy && self.provision && !self.rainSensorViewShown) {
        [self showRainSensorView];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestProvisionServerProxy) self.requestProvisionServerProxy = nil;
    else if (serverProxy == self.saveRainSensorServerProxy) {
        self.saveRainSensorServerProxy = nil;
        self.rainSensorSwitch.on = !self.rainSensorSwitch.isOn;
    }
    
    if (!self.requestProvisionServerProxy && !self.saveRainSensorServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    [self handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - Actions

- (IBAction)onSwitchRainSensor:(id)sender {
    [self saveRainSensor];
}

@end
