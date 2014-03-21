//
//  ZonePropertiesVC.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 09/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ZoneVC.h"
#import "Additions.h"
#import "ProgramCellType1.h"
#import "MBProgressHUD.h"
#import "ServerProxy.h"
#import "ColoredBackgroundButton.h"
#import "Utils.h"
#import "VegetationTypeVC.h"
#import "ServerResponse.h"
#import "ZonesVC.h"
#import "DevicesCellType1.h"
#import "SetDelayVC.h"

#define kZoneProperties_Name 0
#define kZoneProperties_Active 1
#define kZoneProperties_VegetationType 2
#define kZoneProperties_ForecastData 3
#define kZoneProperties_HistoricalAverages 4

#define kAlertViewTag_InvalidZone 1
#define kAlertViewTag_UnsavedChanges 2

typedef enum {
    MasterValve = 0,
    Active = 1,
    VegetationType = 2,
    Advanced = 3,
    ForecastData = 4,
    HistoricalAverages = 5
} RowTypes;

@interface ZoneVC () {
    MBProgressHUD *hud;
    int sectionMasterValve;
    int sectionProperties;
}

@property (strong, nonatomic) ServerProxy *postSaveServerProxy;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) UILabel *footer;

@end

@implementation ZoneVC

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (_zone) {
        self.title = [Utils fixedZoneName:_zone.name withId:[NSNumber numberWithInt:_zone.zoneId]];
    }
    
    sectionMasterValve = _showMasterValve ? 0 : -1;
    sectionProperties = sectionMasterValve + 1;
    
    if (!self.showInitialUnsavedAlert) {
        // In the case when 'showInitialUnsavedAlert' is YES, zoneCopyBeforeSave is set beforehand
        self.zoneCopyBeforeSave = self.zone;
    }

//    [_buttonRunNow setCustomBackgroundColorFromComponents:kLoginGreenButtonColor];
    
    [_tableView registerNib:[UINib nibWithNibName:@"ProgramCellType1" bundle:nil] forCellReuseIdentifier:@"ProgramCellType1"];
    [_tableView registerNib:[UINib nibWithNibName:@"DevicesCellType1" bundle:nil] forCellReuseIdentifier:@"DevicesCellType1"];
    
    if (self.showInitialUnsavedAlert) {
        [self showUnsavedChangesPopup:nil];
        self.showInitialUnsavedAlert = NO;
    }
}

- (void)willPushChildView
{
    // This prevents the test from viewWillDisappear to pass
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ([CCTBackButtonActionHelper sharedInstance].delegate) {
        // The back was done using back-swipe gesture
        if ([self hasUnsavedChanged]) {
            [self.parent setUnsavedZone:self.zone withIndex:self.zoneIndex];
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [CCTBackButtonActionHelper sharedInstance].delegate = self;
}

- (void)vegetationTypeVCWillDissapear:(VegetationTypeVC*)vegetationTypeVC
{
    self.zone.vegetation = vegetationTypeVC.vegetationType;
    
    [self.tableView reloadData];
}

- (void)cellTextFieldChanged:(NSString*)text
{
    self.zone.name = text;
}

- (void)showUnsavedChangesPopup:(id)notif
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Leave screen?"
                                                        message:@"There are unsaved changes"
                                                       delegate:self
                                              cancelButtonTitle:@"Leave screen"
                                              otherButtonTitles:@"Stay", nil];
    alertView.tag = kAlertViewTag_UnsavedChanges;
    [alertView show];
}

- (BOOL)hasUnsavedChanged
{
    if (self.zoneCopyBeforeSave) {
        if (_zone.masterValve == 1) {
            // In this comparison the difference in state should not be considered
            return ![self.zoneCopyBeforeSave isEqualToZone:self.zone];
        } else {
            // In this comparison the difference in state should not be considered
            return ![self.zoneCopyBeforeSave isEqualToZone:self.zone];
        }
    }
    
    return YES;
}

- (UILabel*)footerLabel
{
    if (self.footer) {
        return self.footer;
    }
    
    NSString *s = @"Open 'Master Valve' before a program starts and keep the 'Master Valve' ON after a program ends.";
    UILabel *label = [[UILabel alloc] init];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = s;
    label.font = [UIFont systemFontOfSize:13];
    label.backgroundColor = [UIColor clearColor];
    CGSize size = [s sizeWithFont:label.font constrainedToSize:self.view.frame.size lineBreakMode:label.lineBreakMode];
    label.frame = CGRectMake(0, 0, size.width, size.height + 26);
    
    self.footer = label;
    
    return label;
}

- (void)setDelayVCOver:(SetDelayVC*)setDelayVC
{
    if ([setDelayVC.userInfo isKindOfClass:[NSString class]]) {
        if ([setDelayVC.userInfo isEqualToString:@"before"]) {
            self.zone.before = setDelayVC.valuePicker1;
        }
        else if ([setDelayVC.userInfo isEqualToString:@"after"]) {
                self.zone.after = setDelayVC.valuePicker1;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)onSave:(id)sender {
    if (!self.postSaveServerProxy) {
        [self startHud:nil];
        self.postSaveServerProxy = [[ServerProxy alloc] initWithServerURL:[Utils currentSprinklerURL] delegate:self jsonRequest:YES];
        [self.postSaveServerProxy saveZone:_zone];
    }
}

- (IBAction)onDiscard:(id)sender {
    self.zone = self.zoneCopyBeforeSave;
    [self.tableView reloadData];
}

//- (IBAction)runNow:(id)sender {
//}

- (void)switchChanged:(UISwitch *)sw {
    int tag = sw.tag;
    if (tag == MasterValve) {
        _zone.masterValve = !_zone.masterValve;
    }
    if (tag == Active) {
        _zone.active = !_zone.active;
    }
    if (tag == ForecastData) {
        _zone.forecastData = !_zone.forecastData;
    }
    if (tag == HistoricalAverages) {
        _zone.historicalAverage = !_zone.historicalAverage;
    }
}

- (void)startHud:(NSString *)text {
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    if (serverProxy == self.postSaveServerProxy) {
        self.postSaveServerProxy = nil;
        ServerResponse *response = (ServerResponse*)data;
        if ([response.status isEqualToString:@"err"]) {
            [self.parent handleGeneralSprinklerError:response.message showErrorMessage:YES];
        } else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.parent setZone:self.zone withIndex:self.zoneIndex];
            if (self.zoneCopyBeforeSave.masterValve != self.zone.masterValve) {
                [CCTBackButtonActionHelper sharedInstance].delegate = nil;
                [self.tableView reloadData];
            }
            self.zoneCopyBeforeSave = self.zone;
        }
    }
    
    [self.tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy userInfo:(id)userInfo {
    [self.parent handleGeneralSprinklerError:[error localizedDescription] showErrorMessage:YES];
    
    if (serverProxy == self.postSaveServerProxy) {
        self.postSaveServerProxy = nil;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_zone.masterValve == 1) {
        return 2;
    }
    
    return (sectionMasterValve >= 0) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_zone) {
        if (_zone.masterValve == 1) {
            return (section == 0) ? 1 : 2;
        } else {
            if (section == sectionMasterValve) {
                return 1;
            }
            else if (section == sectionProperties) {
                return 5;
            }
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (_zone.masterValve == 1) {
        if (section == 1) {
            return [self footerLabel].frame.size.height;
        }
    }
    
    return 0;
}

- (UILabel*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (_zone.masterValve == 1) {
        if (section == 1) {
            return [self footerLabel];
        }
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView masterValveCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            static NSString *CellIdentifier1 = @"Cell1";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            
            if (nil == cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
            }
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = _zone.active;
            sw.tag = MasterValve;
            [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.textLabel.text = @"Master Valve";
            cell.textLabel.textColor = [UIColor orangeColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            static NSString *CellIdentifier2 = @"DevicesCellType1";
            DevicesCellType1 *cell = (DevicesCellType1*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            
            [cell.labelMainSubtitle removeFromSuperview];

            cell.labelMainTitle.text = @"Before program starts";
            cell.labelMainSubtitle.hidden = YES;
            cell.labelInfo.text = [NSString stringWithFormat:@"%d mins", _zone.before];
            
            return cell;
        }
        else if (indexPath.row == 1) {
            static NSString *CellIdentifier2 = @"DevicesCellType1";
            DevicesCellType1 *cell = (DevicesCellType1*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            
            [cell.labelMainSubtitle removeFromSuperview];
            
            cell.labelMainTitle.text = @"After program starts";
            cell.labelMainSubtitle.hidden = YES;
            cell.labelInfo.text = [NSString stringWithFormat:@"%d mins", _zone.after];
            
            return cell;
        }
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_zone.masterValve == 1) {
        return [self tableView:tableView masterValveCellForRowAtIndexPath:indexPath];
    }
    
    if (indexPath.section == sectionMasterValve) {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = @"Master Valve";
        cell.tag = MasterValve;
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = _zone.masterValve;
        sw.tag = MasterValve;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }
    
    if (indexPath.section == sectionProperties) {
        if (indexPath.row == kZoneProperties_Name) {
            ProgramCellType1 *cell = (ProgramCellType1 *)[tableView dequeueReusableCellWithIdentifier:@"ProgramCellType1"];

            cell.delegate = self;
            cell.theTextField.text = _zone.name;//[Utils fixedZoneName:_zone.name withId:[NSNumber numberWithInt:_zone.zoneId]];
            if ([[UIDevice currentDevice] iOSGreaterThan:7]) {
                cell.theTextField.tintColor = [UIColor blackColor];
            }
            
            return cell;
        }
        
        else if (indexPath.row == kZoneProperties_Active) {
            static NSString *CellIdentifier1 = @"Cell1";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
            
            if (nil == cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
            }
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = _zone.active;
            sw.tag = Active;
            [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.textLabel.text = @"Active";
            return cell;
        }
        
        else if (indexPath.row == kZoneProperties_VegetationType) {
            static NSString *CellIdentifier2 = @"Cell2";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
            
            if (nil == cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier2];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.textLabel.text = @"Vegetation Type";
            cell.detailTextLabel.text = kVegetationType[_zone.vegetation];
            
            return cell;
        }

    //    if (indexPath.row == 3) {
    //        static NSString *CellIdentifier3 = @"Cell3";
    //        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
    //        
    //        if (nil == cell) {
    //            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier3];
    //            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //        }
    //
    //        cell.textLabel.text = @"Advanced";
    //        return cell;
    //    }

        else if (indexPath.row == kZoneProperties_ForecastData) {
            static NSString *CellIdentifier4 = @"Cell4";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier4];
            
            if (nil == cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier4];
            }
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = _zone.forecastData;
            sw.tag = ForecastData;
            [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.textLabel.text = @"Forecast Data";
            return cell;
        }

        else if (indexPath.row == kZoneProperties_HistoricalAverages) {
            static NSString *CellIdentifier5 = @"Cell5";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier5];
            
            if (nil == cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier5];
            }
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = _zone.historicalAverage;
            sw.tag = HistoricalAverages;
            [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.textLabel.text = @"Historical Averages";
            return cell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_zone.masterValve == 0) {
        if (indexPath.section == sectionProperties) {
            if (indexPath.row == kZoneProperties_VegetationType) {
                VegetationTypeVC *vegetationTypeVC = [[VegetationTypeVC alloc] init];
                vegetationTypeVC.parent = self;
                vegetationTypeVC.vegetationType = self.zone.vegetation;

                [self willPushChildView];
                [self.navigationController pushViewController:vegetationTypeVC animated:YES];
            }
        }
    } else {
        if (indexPath.section == 1) {
            SetDelayVC *setDelayVC = [[SetDelayVC alloc] init];
            setDelayVC.minValuePicker1 = 0;
            setDelayVC.maxValuePicker1 = 300;
            setDelayVC.titlePicker1 = @"minutes";
            
            setDelayVC.parent = self;
            
            [self willPushChildView];
            [self.navigationController pushViewController:setDelayVC animated:YES];
            
            if (indexPath.row == 0) {
                setDelayVC.userInfo = @"before";
                setDelayVC.title = @"Before";
                setDelayVC.valuePicker1 = self.zone.before;
            } else {
                setDelayVC.userInfo = @"after";
                setDelayVC.title = @"After";
                setDelayVC.valuePicker1 = self.zone.after;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_zone.masterValve == 1) {
        return 50.0f;
    }
    
    if (indexPath.section == kZoneProperties_Name) {
        return 54;
    }
    
    return 44.0f;
}

#pragma mark - CCTBackButtonActionHelper delegate

- (BOOL)cct_navigationBar:(UINavigationBar *)navigationBar willPopItem:(UINavigationItem *)item {
    if ([self hasUnsavedChanged]) {
        [self showUnsavedChangesPopup:nil];
        
        return NO;
    }
    
    [CCTBackButtonActionHelper sharedInstance].delegate = nil;
    return YES;
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertViewTag_UnsavedChanges) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            [CCTBackButtonActionHelper sharedInstance].delegate = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (alertView.tag == kAlertViewTag_InvalidZone) {
    }
}

@end
