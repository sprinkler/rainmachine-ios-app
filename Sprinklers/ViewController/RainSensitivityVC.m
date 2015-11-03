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
#import "Additions.h"
#import "Constants.h"
#import "Utils.h"
#import "ColoredBackgroundButton.h"
#import "ServerProxy.h"
#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"
#import "RainSensitivitySimulationGraphVC.h"
#import "SettingsVC.h"
#import "PickerVC.h"
#import "MBProgressHUD.h"

#define RAIN_SENSITIVITY_GRAPHS_ENABLED             NO

const int RainSensitivityMaxWSDays                  = 5;
const int RainSensitivityDefaultWSDays              = 2;
const double RainSensitivityDefaultRainSensitivity  = 0.8;
const double RainSensitivitySimulationGraphHeight   = 240.0;

@interface RainSensitivityVC ()

@property (nonatomic, strong) ServerProxy *requestProvisionServerProxy;
@property (nonatomic, strong) ServerProxy *requestMixerDataServerProxy;
@property (nonatomic, strong) ServerProxy *saveRainSensitivityServerProxy;
@property (nonatomic, strong) Provision *provision;

@property (nonatomic, strong) RainSensitivitySimulationGraphVC *rainSensitivitySimulationGraphVC;

- (void)initializeRainSensitivitySimulationGraph;
- (void)requestProvision;
- (void)requestMixerData;
- (void)saveRainSensitivity;

@property (nonatomic, assign) BOOL rainSensitivitySimulationGraphUseTestData;

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
    
    if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
        [self initializeRainSensitivitySimulationGraph];
        [self requestMixerData];
    } else {
        self.rainSensitivitySimulationGraphHeightLayoutConstraint.constant = 0.0;
    }
    
    [self requestProvision];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Methods

- (void)initializeRainSensitivitySimulationGraph {
    self.rainSensitivitySimulationGraphVC = [[RainSensitivitySimulationGraphVC alloc] init];
    self.rainSensitivitySimulationGraphVC.view.frame = self.rainSensitivitySimulationGraphContainerView.bounds;
    self.rainSensitivitySimulationGraphVC.parent = self;
    self.rainSensitivitySimulationGraphVC.delegate = self;
    
    [self.rainSensitivitySimulationGraphContainerView addSubview:self.rainSensitivitySimulationGraphVC.view];
    [self addChildViewController:self.rainSensitivitySimulationGraphVC];
    
    [self.rainSensitivitySimulationGraphVC didMoveToParentViewController:self];
    
    UIView *graphView = self.rainSensitivitySimulationGraphVC.view;
    
    if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[graphView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[graphView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphView)]];
    } else {
        [self.rainSensitivitySimulationGraphContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[graphView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphView)]];
        [self.rainSensitivitySimulationGraphContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[graphView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphView)]];
    }
}

- (void)requestProvision {
    self.requestProvisionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestProvisionServerProxy requestProvision];
    [self startHud:nil];
}

- (void)requestMixerData {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];

    self.requestMixerDataServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:NO];
    [self.requestMixerDataServerProxy requestMixerDataFromDate:[NSString stringWithFormat:@"%d-01-01",(int)dateComponents.year]
                                                     daysCount:365];
    
    self.rainSensitivitySimulationGraphVC.year = dateComponents.year;
    
    [self startHud:nil];
}

- (void)saveRainSensitivity {
    self.saveRainSensitivityServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.saveRainSensitivityServerProxy saveRainSensitivityFromProvision:self.provision];
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
        if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
            self.rainSensitivitySimulationGraphVC.provision = self.provision;
        }
        self.requestProvisionServerProxy = nil;
    }
    
    if (serverProxy == self.requestMixerDataServerProxy) {
        self.rainSensitivitySimulationGraphVC.mixerDataByDate = (NSArray*)data;
        self.requestMixerDataServerProxy = nil;
    }
    
    if (serverProxy == self.saveRainSensitivityServerProxy) {
        self.saveRainSensitivityServerProxy = nil;
    }
    
    if (!self.requestProvisionServerProxy && !self.requestMixerDataServerProxy && !self.saveRainSensitivityServerProxy) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        hud = nil;
    }
    
    if (!self.requestProvisionServerProxy && !self.requestMixerDataServerProxy && self.provision && (!RAIN_SENSITIVITY_GRAPHS_ENABLED || self.rainSensitivitySimulationGraphVC.mixerDataByDate)) {
        if (!RAIN_SENSITIVITY_GRAPHS_ENABLED) {
            CGRect frame = self.rainSensitivityHeaderView.frame;
            frame.size.height = 64.0;
            self.rainSensitivityHeaderView.frame = frame;
        }
        
        self.tableView.tableHeaderView = self.rainSensitivityHeaderView;
        
        if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
            [self.rainSensitivitySimulationGraphVC initializeGraph];
            [self.rainSensitivitySimulationGraphVC centerCurrentMonthAnimated:NO];
        }
        
        [self.tableView reloadData];
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestProvisionServerProxy) self.requestProvisionServerProxy = nil;
    else if (serverProxy == self.requestMixerDataServerProxy) self.requestMixerDataServerProxy = nil;
    else if (serverProxy == self.saveRainSensitivityServerProxy) self.saveRainSensitivityServerProxy = nil;
    
    if (!self.requestProvisionServerProxy && !self.requestMixerDataServerProxy && !self.saveRainSensitivityServerProxy) {
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
    return (self.provision ? (ENABLE_DEBUG_SETTINGS && RAIN_SENSITIVITY_GRAPHS_ENABLED ? 3 : 2) : 0);
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 1;
    if (section == 2) return 1;
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) return 83.0;
    if (indexPath.section == 1 && indexPath.row == 0) return 62.0;
    if (indexPath.section == 2 && indexPath.row == 0) return 44.0;
    return 0.0;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"Field Capacity";
    if (section == 2) return @"Settings (Debug)";
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *RainSensitivityCellIdentifier = @"RainSensitivityCell";
    static NSString *FieldCapacityCellIdentifier = @"FieldCapacityCell";
    static NSString *DebugCheckboxCellIdentifier = @"DebugCheckboxCellIdentifier";
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        RainSensitivityCell *cell = [tableView dequeueReusableCellWithIdentifier:RainSensitivityCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.rainSensitivity = (self.provision.location.rainSensitivity > 1.0 ? 1.0 : self.provision.location.rainSensitivity);
        cell.delegate = self;
        return cell;
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        FieldCapacityCell *cell = [tableView dequeueReusableCellWithIdentifier:FieldCapacityCellIdentifier];
        cell.fieldCapacity = self.provision.location.wsDays;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    else if (indexPath.section == 2 && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DebugCheckboxCellIdentifier];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DebugCheckboxCellIdentifier];
        
        cell.textLabel.text = @"Generate Test Data";
        cell.accessoryType = (self.rainSensitivitySimulationGraphUseTestData ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        
        if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
            cell.tintColor = [UIColor colorWithRed:0.0 / 255.0 green:122.0 / 255.0 blue:255.0 / 255.0 alpha:1.0];
        }
        
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        NSMutableArray *itemsArray = [NSMutableArray new];
        for (int days = 0; days <= RainSensitivityMaxWSDays; days++) [itemsArray addObject:[NSString stringWithFormat:@"%d",days]];
        
        PickerVC *pickerVC = [[PickerVC alloc] init];
        pickerVC.title = @"Field Capacity";
        pickerVC.itemsArray = itemsArray;
        pickerVC.itemsDisplayStringArray = itemsArray;
        pickerVC.selectedItem = [NSString stringWithFormat:@"%d",self.provision.location.wsDays];
        pickerVC.parent = self;
        
        [self.navigationController pushViewController:pickerVC animated:YES];
    }
    
    else if (indexPath.section == 2 && indexPath.row == 0) {
        self.rainSensitivitySimulationGraphUseTestData = !self.rainSensitivitySimulationGraphUseTestData;
        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewCellAccessoryNone];
        
        [self.rainSensitivitySimulationGraphVC initializeGraph];
        [self.rainSensitivitySimulationGraphVC centerCurrentMonthAnimated:YES];
    }
}

#pragma mark - Rain sensitivity simulation graph delegate

- (CGFloat)widthForGraphInRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)graphVC {
    return ceil(MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) / 3.0);
}

- (CGFloat)heightForGraphInRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)graphVC {
    return RainSensitivitySimulationGraphHeight;
}

- (BOOL)generateTestDataForRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)graphVC {
    return self.rainSensitivitySimulationGraphUseTestData;
}

#pragma mark - Actions

- (void)onCellSliderValueChanged:(UISlider*)slider {
    self.provision.location.rainSensitivity = (int)(slider.value * 100.0) / 100.0;
    
    if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
        [self.rainSensitivitySimulationGraphVC delayedUpdateGraph:0.05];
    }
}

- (void)pickerVCWillDissapear:(PickerVC*)pickerVC {
    if (!pickerVC.selectedItem.length) return;
    self.provision.location.wsDays = pickerVC.selectedItem.intValue;
    
    [self.tableView reloadData];
    
    if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
        [self.rainSensitivitySimulationGraphVC updateGraph];
    }
}

- (IBAction)onDefaults:(id)sender {
    self.provision.location.rainSensitivity = RainSensitivityDefaultRainSensitivity;
    self.provision.location.wsDays = RainSensitivityDefaultWSDays;
    
    [self.tableView reloadData];
    
    if (RAIN_SENSITIVITY_GRAPHS_ENABLED) {
        [self.rainSensitivitySimulationGraphVC updateGraph];
    }
}

- (IBAction)onSave:(id)sender {
    [self saveRainSensitivity];
}

@end
