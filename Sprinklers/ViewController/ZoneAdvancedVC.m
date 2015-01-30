//
//  ZoneAdvancedVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 30/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ZoneAdvancedVC.h"
#import "ZoneVC.h"
#import "ZoneAdvancedPropertyCell.h"
#import "ZoneProperties4.h"
#import "Zone.h"
#import "ZoneAdvancedProperties.h"
#import "Utils.h"
#import "Constants.h"
#import "ServerProxy.h"
#import "MBProgressHUD.h"

#define kRow_MaxAllowedDepletion     0
#define kRow_PrecipitationRate       1
#define kRow_AppEfficiency           2
#define kRow_AllowedSurfaceAcc       3
#define kRow_RootDepth               4
#define kRow_IsTallPlant             5
#define kRow_SoilIntakeRate          6
#define kRow_PermWilting             7
#define kRow_FieldCapacity           8

#pragma mark -

@interface ZoneAdvancedVC ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString *metric;
@property (nonatomic, strong) ZoneProperties4 *zoneProperties;

- (NSString*)propertyTextForName:(NSString*)propertyName metric:(NSString*)metric;
- (NSString*)propertyValueToString:(NSNumber*)value;
- (NSString*)propertyValueToPercentString:(NSNumber*)value;

@property (nonatomic, strong) ServerProxy *zonePropertiesServerProxy;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)requestZoneProperties;

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
    self.metric = @"inch";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZoneAdvancedPropertyCell" bundle:nil] forCellReuseIdentifier:@"ZoneAdvancedPropertyCell"];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestZoneProperties];
}

#pragma mark - Methods

- (NSString*)propertyTextForName:(NSString*)propertyName metric:(NSString*)metric {
    return [NSString stringWithFormat:@"%@ (%@)",propertyName,metric];
}

- (NSString*)propertyValueToString:(NSNumber*)value {
    if (!value) return nil;
    
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.usesGroupingSeparator = NO;
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    return [numberFormatter stringFromNumber:value];
}

- (NSString*)propertyValueToPercentString:(NSNumber*)value {
    return [self propertyValueToString:@(value.doubleValue * 100.0)];
}

- (void)requestZoneProperties {
    if (self.zonePropertiesServerProxy) return;
    if (!self.zone) return;
    
    self.zonePropertiesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.zonePropertiesServerProxy requestZonePropertiesWithId:self.zone.zoneId];
    [self startHud:nil];
}

- (void)startHud:(NSString *)text {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.labelText = text;
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.zoneProperties) return 2;
    return 0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return kRow_FieldCapacity + 1;
    if (section == 1) return 12;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return nil;
    if (section == 1) return [self propertyTextForName:@"Detailed months Kc" metric:@"%"];
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 60.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"ZoneAdvancedPropertyCell";
    ZoneAdvancedPropertyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (indexPath.section == 0) {
        if (indexPath.row == kRow_SoilIntakeRate) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Soil intake" metric:self.metric];
            cell.propertyValueTextField.text = [self propertyValueToString:self.zoneProperties.advancedProperties.soilIntakeRate];
        }
        else if (indexPath.row == kRow_MaxAllowedDepletion) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Max allowed depletion" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.maxAllowedDepletion];
        }
        else if (indexPath.row == kRow_RootDepth) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Root depth" metric:self.metric];
            cell.propertyValueTextField.text = [self propertyValueToString:self.zoneProperties.advancedProperties.rootDepth];
        }
        else if (indexPath.row == kRow_IsTallPlant) {
            static NSString *TallPlantCellIdentifier = @"TallPlantCellIdentifier";
            UITableViewCell *tallPlantCell = [tableView dequeueReusableCellWithIdentifier:TallPlantCellIdentifier];
            if (!tallPlantCell) tallPlantCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TallPlantCellIdentifier];
                
            tallPlantCell.textLabel.text = @"Tall plant";
            tallPlantCell.accessoryView = [UISwitch new];
            ((UISwitch*)tallPlantCell.accessoryView).on = self.zoneProperties.advancedProperties.isTallPlant.boolValue;
            
            return tallPlantCell;
        }
        else if (indexPath.row == kRow_PrecipitationRate) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Precipitation rate" metric:self.metric];
            cell.propertyValueTextField.text = [self propertyValueToString:self.zoneProperties.advancedProperties.precipitationRate];
        }
        else if (indexPath.row == kRow_AppEfficiency) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"App efficiency" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.appEfficiency];
        }
        else if (indexPath.row == kRow_AllowedSurfaceAcc) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Allowed surface acc" metric:self.metric];
            cell.propertyValueTextField.text = [self propertyValueToString:self.zoneProperties.advancedProperties.allowedSurfaceAcc];
        }
        else if (indexPath.row == kRow_PermWilting) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Perm wilting" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.permWilting];
        }
        else if (indexPath.row == kRow_FieldCapacity) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Field capacity" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.fieldCapacity];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            static NSString *DetailedMonthKcCellIdentifier = @"DetailedMonthKcCellIdentifier";
            UITableViewCell *detailedMonthKcCell = [tableView dequeueReusableCellWithIdentifier:DetailedMonthKcCellIdentifier];
            if (!detailedMonthKcCell) detailedMonthKcCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DetailedMonthKcCellIdentifier];
            
            detailedMonthKcCell.textLabel.text = @"Use same value for all months";
            detailedMonthKcCell.accessoryView = [UISwitch new];
            ((UISwitch*)detailedMonthKcCell.accessoryView).on = YES;
            
            return detailedMonthKcCell;
        }
        else {
            NSInteger monthIndex = indexPath.row - 1;
            NSString *monthName = monthsOfYear[monthIndex];
            NSNumber *monthValue = (monthIndex < self.zoneProperties.advancedProperties.detailedMonthsKc.count ? self.zoneProperties.advancedProperties.detailedMonthsKc[monthIndex]: nil);
            
            cell.propertyNameLabel.text = monthName;
            cell.propertyValueTextField.text = [self propertyValueToPercentString:monthValue];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ((indexPath.section == 0 && indexPath.row == kRow_IsTallPlant) ||
        (indexPath.section == 1 && indexPath.row == 0)) {
        
        UISwitch *propertySwitch = (UISwitch*)cell.accessoryView;
        propertySwitch.on = !propertySwitch.on;
    } else {
        if ([cell isKindOfClass:[ZoneAdvancedPropertyCell class]]) {
            [((ZoneAdvancedPropertyCell*)cell).propertyValueTextField becomeFirstResponder];
        }
    }
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    [self.tableView endEditing:YES];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (serverProxy == self.zonePropertiesServerProxy) {
        self.zoneProperties = data;
        self.zonePropertiesServerProxy = nil;
    }
    
    [self.tableView reloadData];
}

- (void)serverErrorReceived:(NSError *)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    [self.parent handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (serverProxy == self.zonePropertiesServerProxy) {
        self.zonePropertiesServerProxy = nil;
    }
    
    [self.tableView reloadData];
}

- (void)loggedOut {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self handleLoggedOutSprinklerError];
}

@end
