//
//  ZoneAdvancedVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ZoneAdvancedVC.h"
#import "ZoneAdvancedTableVC.h"
#import "ZoneVC.h"
#import "ZoneAdvancedPropertyCell.h"
#import "ZoneProperties4.h"
#import "ZoneAdvancedProperties.h"
#import "Zone.h"
#import "Utils.h"
#import "Additions.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface ZoneAdvancedVC ()

@property (nonatomic, weak) IBOutlet UIView *zoneAdvancedTableContainerView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) ZoneAdvancedTableVC *zoneAdvancedTableVC;
@property (nonatomic, strong) ServerProxy *zonePropertiesServerProxy;
@property (nonatomic, strong) ServerProxy *saveZonePropertiesServerProxy;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)requestZoneProperties;
- (void)saveZoneProperties;

- (IBAction)onDiscard:(id)sender;
- (IBAction)onSave:(id)sender;

@property (nonatomic, assign) BOOL shouldLeaveWithoutSavingChanges;

@end

#pragma mark -

@implementation ZoneAdvancedVC

#pragma Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.zone) self.title = [Utils fixedZoneName:_zone.name withId:[NSNumber numberWithInt:_zone.zoneId]];
    
    self.zoneAdvancedTableVC = [[ZoneAdvancedTableVC alloc] initWithStyle:UITableViewStylePlain];
    self.zoneAdvancedTableVC.view.frame = self.zoneAdvancedTableContainerView.bounds;
    [self.zoneAdvancedTableContainerView addSubview:self.zoneAdvancedTableVC.view];
    [self addChildViewController:self.zoneAdvancedTableVC];
    [self.zoneAdvancedTableVC didMoveToParentViewController:self.zoneAdvancedTableVC];
    
    UIView *zoneAdvancedTableView = self.zoneAdvancedTableVC.view;
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[zoneAdvancedTableView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(zoneAdvancedTableView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[zoneAdvancedTableView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(zoneAdvancedTableView)]];
    } else {
        [self.zoneAdvancedTableContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[zoneAdvancedTableView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(zoneAdvancedTableView)]];
        [self.zoneAdvancedTableContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[zoneAdvancedTableView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(zoneAdvancedTableView)]];
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.zoneAdvancedTableVC.parent = self;
    self.zoneAdvancedTableVC.zone = self.zone;
    
    if (self.showInitialUnsavedAlert) {
        [self showUnsavedChangesPopup:nil];
        self.showInitialUnsavedAlert = NO;
        self.zoneAdvancedTableVC.zoneProperties = self.unsavedZoneProperties;
    } else {
        self.zoneAdvancedTableVC.zoneProperties = nil;
    }
    
    [self.zoneAdvancedTableVC reloadData];
    [self initializeToolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.unsavedZoneProperties) {
        [self requestZoneProperties];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.shouldLeaveWithoutSavingChanges && ![self.zoneProperties.advancedProperties isEqualToZoneAdvancedProperties:self.zoneAdvancedTableVC.zoneProperties.advancedProperties]) {
        self.parent.zoneProperties = self.zoneProperties;
        self.parent.unsavedZoneProperties = self.zoneAdvancedTableVC.zoneProperties;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

#pragma mark - Methods

- (void)requestZoneProperties {
    if (self.zonePropertiesServerProxy) return;
    if (!self.zone) return;
    
    self.zonePropertiesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.zonePropertiesServerProxy requestZonePropertiesWithId:self.zone.zoneId];
    [self startHud:nil];
}

- (void)saveZoneProperties {
    if (self.saveZonePropertiesServerProxy) return;
    if (!self.zoneAdvancedTableVC.zoneProperties) return;
    
    self.saveZonePropertiesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveZonePropertiesServerProxy saveZone:(Zone*)self.zoneAdvancedTableVC.zoneProperties];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

- (void)initializeToolbar {
    UIBarButtonItem* discardButton = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(onSave:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    BOOL advancedPropertiesTableViewEdited = NO;
    if (self.zoneProperties && self.zoneAdvancedTableVC.zoneProperties) {
        advancedPropertiesTableViewEdited = ![self.zoneProperties.advancedProperties isEqualToZoneAdvancedProperties:self.zoneAdvancedTableVC.zoneProperties.advancedProperties];
    }
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        discardButton.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        if (advancedPropertiesTableViewEdited) saveButton.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        else saveButton.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
    }
    
    self.toolbar.items = [NSArray arrayWithObjects:flexibleSpace, discardButton, flexibleSpace, saveButton, flexibleSpace, nil];
}

- (void)advancedPropertiesTableViewDidEdit {
    [self initializeToolbar];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (serverProxy == self.zonePropertiesServerProxy) {
        self.zoneProperties = data;
        self.zoneAdvancedTableVC.zoneProperties = [self.zoneProperties copy];
        self.zonePropertiesServerProxy = nil;
    }
    else if (serverProxy == self.saveZonePropertiesServerProxy) {
        self.zoneProperties = [self.zoneAdvancedTableVC.zoneProperties copy];
        self.saveZonePropertiesServerProxy = nil;
    }
    
    [self.zoneAdvancedTableVC reloadData];
    [self initializeToolbar];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (serverProxy == self.zonePropertiesServerProxy) self.zonePropertiesServerProxy = nil;
    else if (serverProxy == self.saveZonePropertiesServerProxy) self.saveZonePropertiesServerProxy = nil;
    
    [self.zoneAdvancedTableVC reloadData];
    [self initializeToolbar];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - CCTBackButtonActionHelper delegate

- (BOOL)cct_navigationBar:(UINavigationBar*)navigationBar willPopItem:(UINavigationItem*)item {
    if (![self.zoneProperties.advancedProperties isEqualToZoneAdvancedProperties:self.zoneAdvancedTableVC.zoneProperties.advancedProperties]) {
        [self showUnsavedChangesPopup:nil];
        
        return NO;
    }
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    return YES;
}

#pragma mark - Unsaved changes alert

- (void)showUnsavedChangesPopup:(id)notification {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Leave screen?"
                                                        message:@"There are unsaved changes"
                                                       delegate:self
                                              cancelButtonTitle:@"Leave screen"
                                              otherButtonTitles:@"Stay", nil];
    alertView.tag = kAlertView_UnsavedChanges;
    [alertView show];
}

- (void)alertView:(UIAlertView *)theAlertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (theAlertView.tag == kAlertView_UnsavedChanges) {
        if (theAlertView.cancelButtonIndex == buttonIndex) {
            self.shouldLeaveWithoutSavingChanges = YES;
            [CCTBackButtonActionHelper sharedInstance].delegate = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [super alertView:theAlertView didDismissWithButtonIndex:buttonIndex];
    }
}

#pragma mark - Actions

- (IBAction)onDiscard:(id)sender {
    [self.zoneAdvancedTableVC endEditing];
    self.zoneAdvancedTableVC.zoneProperties = [self.zoneProperties copy];
    [self.zoneAdvancedTableVC reloadData];
    [self initializeToolbar];
}

- (IBAction)onSave:(id)sender {
    [self.zoneAdvancedTableVC endEditing];
    [self saveZoneProperties];
}

@end
