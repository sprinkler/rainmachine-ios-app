//
//  DataSourcesParserVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "DataSourcesParserVC.h"
#import "DataSourcesParserParameterVC.h"
#import "DataSourcesVC.h"
#import "ServerProxy.h"
#import "Parser.h"
#import "Additions.h"
#import "Utils.h"
#import "MBProgressHUD.h"

#pragma mark -

@interface ParserParameterSwitch : UISwitch

@property (nonatomic, strong) ParserParameter *parserParameter;

@end

@implementation ParserParameterSwitch

@end

#pragma mark -

@interface DataSourcesParserVC ()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) ServerProxy *saveParserServerProxy;
@property (nonatomic, strong) Parser *parserCopy;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)saveParserParameters;
- (void)initializeToolbar;
- (void)refreshProgressHUD;

- (IBAction)onDiscard:(id)sender;
- (IBAction)onSave:(id)sender;

@property (nonatomic, assign) BOOL shouldLeaveWithoutSavingChanges;

- (void)showUnsavedChangesPopup;

@end

#pragma mark -

@implementation DataSourcesParserVC

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.parser.name;
    self.parserCopy = [self.parser copy];
    
    if (self.showInitialUnsavedAlert) {
        [self showUnsavedChangesPopup];
        self.showInitialUnsavedAlert = NO;
        self.parserCopy = [self.unsavedParser copy];
    } else {
        self.parserCopy = [self.parser copy];
    }
    
    [self initializeToolbar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self initializeToolbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.shouldLeaveWithoutSavingChanges && ![self.parser isEqualToParser:self.parserCopy]) {
        self.parent.parser = self.parser;
        self.parent.unsavedParser = self.parserCopy;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

#pragma mark - Helper methods

- (void)saveParserParameters {
    self.saveParserServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveParserServerProxy saveParserParams:self.parserCopy];
}

- (void)initializeToolbar {
    UIBarButtonItem* discardButton = [[UIBarButtonItem alloc] initWithTitle:@"Discard" style:UIBarButtonItemStyleBordered target:self action:@selector(onDiscard:)];
    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(onSave:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    BOOL parserParametersEdited = ![self.parserCopy isEqualToParser:self.parser];
    
    if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
        discardButton.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
        if (parserParametersEdited) saveButton.tintColor = [UIColor colorWithRed:kWateringRedButtonColor[0] green:kWateringRedButtonColor[1] blue:kWateringRedButtonColor[2] alpha:1];
        else saveButton.tintColor = [UIColor colorWithRed:kButtonBlueTintColor[0] green:kButtonBlueTintColor[1] blue:kButtonBlueTintColor[2] alpha:1];
    }
    
    self.toolbar.items = [NSArray arrayWithObjects:flexibleSpace, discardButton, flexibleSpace, saveButton, flexibleSpace, nil];
}

- (void)refreshProgressHUD {
    BOOL shouldShowProgressHUD = (self.saveParserServerProxy != nil);
    if (shouldShowProgressHUD && !self.hud) self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    else if (!shouldShowProgressHUD && self.hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.hud = nil;
    }
}

#pragma mark - Actions

- (IBAction)onSwitchValue:(ParserParameterSwitch*)sender {
    sender.parserParameter.value = @(sender.on);
    [self initializeToolbar];
}

- (IBAction)onDiscard:(id)sender {
    self.parserCopy = [self.parser copy];
    [self.tableView reloadData];
    [self initializeToolbar];
}

- (IBAction)onSave:(id)sender {
    [self saveParserParameters];
    [self refreshProgressHUD];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return self.parserCopy.params.count;
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
    
    ParserParameter *parameter = self.parserCopy.params[indexPath.row];
    cell.textLabel.text = parameter.name;
    
    if (parameter.parameterType == ParserParameterTypeUnknown) cell.accessoryView = nil;
    else if (parameter.parameterType == ParserParameterTypeNull) cell.accessoryView = nil;
    else if (parameter.parameterType == ParserParameterTypeBoolean) {
        ParserParameterSwitch *accessorySwitch = [ParserParameterSwitch new];
        accessorySwitch.parserParameter = parameter;
        accessorySwitch.on = [parameter.value boolValue];
        [accessorySwitch addTarget:self action:@selector(onSwitchValue:) forControlEvents:UIControlEventValueChanged];
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
    
    ParserParameter *parameter = self.parserCopy.params[indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (parameter.parameterType == ParserParameterTypeBoolean) {
        ParserParameterSwitch *accessorySwitch = (ParserParameterSwitch*)cell.accessoryView;
        accessorySwitch.on = !accessorySwitch.isOn;
        [self onSwitchValue:accessorySwitch];
    }
    else {
        DataSourcesParserParameterVC *dataSourceParserParameterVC = [[DataSourcesParserParameterVC alloc] init];
        dataSourceParserParameterVC.parser = self.parserCopy;
        dataSourceParserParameterVC.parserParameter = parameter;
        [self.navigationController pushViewController:dataSourceParserParameterVC animated:YES];
    }
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.saveParserServerProxy) {
        self.parser = self.parserCopy;
        self.parserCopy = [self.parser copy];
        self.saveParserServerProxy = nil;
    }
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
    [self initializeToolbar];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    
    if (serverProxy == self.saveParserServerProxy) self.saveParserServerProxy = nil;
    
    [self.tableView reloadData];
    [self refreshProgressHUD];
    [self initializeToolbar];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - CCTBackButtonActionHelper delegate

- (BOOL)cct_navigationBar:(UINavigationBar*)navigationBar willPopItem:(UINavigationItem*)item {
    if (![self.parser isEqualToParser:self.parserCopy]) {
        [self showUnsavedChangesPopup];
        return NO;
    }
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    return YES;
}

#pragma mark - Unsaved changes alert

- (void)showUnsavedChangesPopup {
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

@end
