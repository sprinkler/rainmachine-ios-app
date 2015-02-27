//
//  ZoneAdvancedTableVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 14/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "ZoneAdvancedTableVC.h"
#import "ZoneAdvancedVC.h"
#import "ZoneAdvancedPropertyCell.h"
#import "ZoneAdvancedMonthKCCell.h"
#import "ZoneAdvancedProperties.h"
#import "ZoneProperties4.h"
#import "Zone.h"
#import "Utils.h"

#define kRow_MaxAllowedDepletion        0
#define kRow_PrecipitationRate          1
#define kRow_AppEfficiency              2
#define kRow_AllowedSurfaceAcc          3
#define kRow_RootDepth                  4
#define kRow_IsTallPlant                5
#define kRow_SoilIntakeRate             6
#define kRow_PermWilting                7
#define kRow_FieldCapacity              8

#define kTag_AdvancedProperties         1000
#define kTag_DetailedMonthKC            2000

#pragma mark -

@interface ZoneAdvancedTableVC ()

@property (nonatomic, strong) NSString *lengthUnits;
@property (nonatomic, assign) BOOL useSameMonthKC;
@property (nonatomic, strong) NSNumber *sameMonthKCValue;

- (NSString*)propertyTextForName:(NSString*)propertyName metric:(NSString*)metric;
- (NSString*)propertyValueToString:(NSNumber*)value;
- (NSString*)propertyValueToLengthString:(NSNumber*)value;
- (NSString*)propertyValueToPercentString:(NSNumber*)value;
- (NSNumber*)propertyValueFromLengthString:(NSString*)string;
- (NSNumber*)propertyValueFromPercentString:(NSString*)string;

@property (nonatomic, strong) NSString *currentTextFieldOldValue;

@end

#pragma mark -

@implementation ZoneAdvancedTableVC

#pragma mark - Init

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (!self) return nil;
    
    _lengthUnits = [Utils sprinklerLengthUnits];
    _useSameMonthKC = NO;
    _sameMonthKCValue = @(0.0);
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZoneAdvancedPropertyCell" bundle:nil] forCellReuseIdentifier:@"ZoneAdvancedPropertyCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZoneAdvancedMonthKCCell" bundle:nil] forCellReuseIdentifier:@"ZoneAdvancedMonthKCCell"];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)endEditing {
    [self.tableView endEditing:nil];
}

#pragma mark - Methods

- (NSString*)propertyTextForName:(NSString*)propertyName metric:(NSString*)metric {
    return [NSString stringWithFormat:@"%@ (%@)",propertyName,metric];
}

- (NSString*)propertyValueToString:(NSNumber*)value {
    if (!value) return nil;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setDecimalSeparator:@"."];
    
    NSString *stringValue = [numberFormatter stringFromNumber:value];
    if (![stringValue containsString:@"."]) return stringValue;
    
    while ([stringValue hasSuffix:@"0"]) stringValue = [stringValue substringToIndex:stringValue.length - 1];
    if ([stringValue hasSuffix:@"."]) stringValue = [stringValue substringToIndex:stringValue.length - 1];
    
    return stringValue;
}

- (NSString*)propertyValueToLengthString:(NSNumber*)value {
    if ([self.lengthUnits isEqualToString:@"mm"]) return [self propertyValueToString:value];
    return [self propertyValueToString:@(value.doubleValue / 25.4)];
}

- (NSString*)propertyValueToPercentString:(NSNumber*)value {
    return [self propertyValueToString:@(value.doubleValue * 100.0)];
}

- (NSNumber*)propertyValueFromLengthString:(NSString*)string {
    if ([self.lengthUnits isEqualToString:@"mm"]) return @(string.doubleValue);
    return @(string.doubleValue * 25.4);
}

- (NSNumber*)propertyValueFromPercentString:(NSString*)string {
    return @(string.doubleValue / 100.0);
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.zoneProperties) return 2;
    return 0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return kRow_FieldCapacity + 1;
    if (section == 1) return (self.useSameMonthKC ? 2 : 13);
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

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) return 36.0;
    return 0.0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 60.0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"ZoneAdvancedPropertyCell";
        ZoneAdvancedPropertyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (indexPath.row == kRow_SoilIntakeRate) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Soil intake" metric:self.lengthUnits];
            cell.propertyValueTextField.text = [self propertyValueToLengthString:self.zoneProperties.advancedProperties.soilIntakeRate];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_SoilIntakeRate;
        }
        else if (indexPath.row == kRow_MaxAllowedDepletion) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Max allowed depletion" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.maxAllowedDepletion];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_MaxAllowedDepletion;
        }
        else if (indexPath.row == kRow_RootDepth) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Root depth" metric:self.lengthUnits];
            cell.propertyValueTextField.text = [self propertyValueToLengthString:self.zoneProperties.advancedProperties.rootDepth];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_RootDepth;
        }
        else if (indexPath.row == kRow_IsTallPlant) {
            static NSString *TallPlantCellIdentifier = @"TallPlantCellIdentifier";
            UITableViewCell *tallPlantCell = [tableView dequeueReusableCellWithIdentifier:TallPlantCellIdentifier];
            if (!tallPlantCell) tallPlantCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TallPlantCellIdentifier];
            
            tallPlantCell.textLabel.text = @"Tall plant";
            tallPlantCell.accessoryView = [UISwitch new];
            ((UISwitch*)tallPlantCell.accessoryView).on = self.zoneProperties.advancedProperties.isTallPlant.boolValue;
            [((UISwitch*)tallPlantCell.accessoryView) addTarget:self action:@selector(onTallPlantSwitch:) forControlEvents:UIControlEventValueChanged];
            
            return tallPlantCell;
        }
        else if (indexPath.row == kRow_PrecipitationRate) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Precipitation rate" metric:self.lengthUnits];
            cell.propertyValueTextField.text = [self propertyValueToLengthString:self.zoneProperties.advancedProperties.precipitationRate];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_PrecipitationRate;
        }
        else if (indexPath.row == kRow_AppEfficiency) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"App efficiency" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.appEfficiency];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_AppEfficiency;
        }
        else if (indexPath.row == kRow_AllowedSurfaceAcc) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Allowed surface acc" metric:self.lengthUnits];
            cell.propertyValueTextField.text = [self propertyValueToLengthString:self.zoneProperties.advancedProperties.allowedSurfaceAcc];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_AllowedSurfaceAcc;
        }
        else if (indexPath.row == kRow_PermWilting) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Perm wilting" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.permWilting];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_PermWilting;
        }
        else if (indexPath.row == kRow_FieldCapacity) {
            cell.propertyNameLabel.text = [self propertyTextForName:@"Field capacity" metric:@"%"];
            cell.propertyValueTextField.text = [self propertyValueToPercentString:self.zoneProperties.advancedProperties.fieldCapacity];
            cell.propertyValueTextField.delegate = self;
            cell.propertyValueTextField.tag = kTag_AdvancedProperties + kRow_FieldCapacity;
        }
        
        return cell;
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            static NSString *DetailedMonthKCCellIdentifier = @"DetailedMonthKCCellIdentifier";
            UITableViewCell *detailedMonthKCCell = [tableView dequeueReusableCellWithIdentifier:DetailedMonthKCCellIdentifier];
            if (!detailedMonthKCCell) detailedMonthKCCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DetailedMonthKCCellIdentifier];
            
            detailedMonthKCCell.textLabel.text = @"Use same value for all months";
            detailedMonthKCCell.accessoryView = [UISwitch new];
            ((UISwitch*)detailedMonthKCCell.accessoryView).on = self.useSameMonthKC;
            [((UISwitch*)detailedMonthKCCell.accessoryView) addTarget:self action:@selector(onDetailedMonthKCSwitch:) forControlEvents:UIControlEventValueChanged];
            
            return detailedMonthKCCell;
        }
        else {
            if (self.useSameMonthKC) {
                static NSString *CellIdentifier = @"ZoneAdvancedMonthKCCell";
                ZoneAdvancedMonthKCCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.propertyValueTextField.text = [self propertyValueToPercentString:self.sameMonthKCValue];
                cell.propertyValueTextField.delegate = self;
                cell.propertyValueTextField.tag = kTag_DetailedMonthKC;
                
                return cell;
            } else {
                static NSString *CellIdentifier = @"ZoneAdvancedPropertyCell";
                ZoneAdvancedPropertyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                NSInteger monthIndex = indexPath.row - 1;
                NSString *monthName = monthsOfYear[monthIndex];
                NSNumber *monthValue = (monthIndex < self.zoneProperties.advancedProperties.detailedMonthsKc.count ? self.zoneProperties.advancedProperties.detailedMonthsKc[monthIndex]: nil);
                
                cell.propertyNameLabel.text = monthName;
                cell.propertyValueTextField.text = [self propertyValueToPercentString:monthValue];
                cell.propertyValueTextField.delegate = self;
                cell.propertyValueTextField.tag = kTag_DetailedMonthKC + monthIndex;
                
                return cell;
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == kRow_IsTallPlant) {
        UISwitch *tallPlantSwitch = (UISwitch*)cell.accessoryView;
        tallPlantSwitch.on = !tallPlantSwitch.on;
        [self onTallPlantSwitch:tallPlantSwitch];
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        UISwitch *detailedMonthKCSwitch = (UISwitch*)cell.accessoryView;
        detailedMonthKCSwitch.on = !detailedMonthKCSwitch.on;
        [self onDetailedMonthKCSwitch:detailedMonthKCSwitch];
    } else {
        if ([cell isKindOfClass:[ZoneAdvancedPropertyCell class]]) {
            [((ZoneAdvancedPropertyCell*)cell).propertyValueTextField becomeFirstResponder];
        }
    }
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if (!scrollView.dragging) return;
    [self.tableView endEditing:YES];
}

#pragma mark - UITextField delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (!string.length) return YES;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setDecimalSeparator:@"."];
    
    NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSNumber *number = [numberFormatter numberFromString:updatedText];
    
    if (number) return YES;
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    self.currentTextFieldOldValue = textField.text;
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
    if (!textField.text.length) {
        if (self.currentTextFieldOldValue) textField.text = self.currentTextFieldOldValue;
        else textField.text = @"0";
        self.currentTextFieldOldValue = nil;
        
        [self.parent advancedPropertiesTableViewDidEdit];
        
        return;
    }

    if (textField.tag >= kTag_AdvancedProperties && textField.tag < kTag_DetailedMonthKC) {
        NSInteger advancedPropertyRow = textField.tag - kTag_AdvancedProperties;
        
        if (advancedPropertyRow == kRow_MaxAllowedDepletion) self.zoneProperties.advancedProperties.maxAllowedDepletion = [self propertyValueFromPercentString:textField.text];
        else if (advancedPropertyRow == kRow_PrecipitationRate) self.zoneProperties.advancedProperties.precipitationRate = [self propertyValueFromLengthString:textField.text];
        else if (advancedPropertyRow == kRow_AppEfficiency) self.zoneProperties.advancedProperties.appEfficiency = [self propertyValueFromPercentString:textField.text];
        else if (advancedPropertyRow == kRow_AllowedSurfaceAcc) self.zoneProperties.advancedProperties.allowedSurfaceAcc = [self propertyValueFromLengthString:textField.text];
        else if (advancedPropertyRow == kRow_RootDepth) self.zoneProperties.advancedProperties.rootDepth = [self propertyValueFromLengthString:textField.text];
        else if (advancedPropertyRow == kRow_SoilIntakeRate) self.zoneProperties.advancedProperties.soilIntakeRate = [self propertyValueFromLengthString:textField.text];
        else if (advancedPropertyRow == kRow_PermWilting) self.zoneProperties.advancedProperties.permWilting = [self propertyValueFromPercentString:textField.text];
        else if (advancedPropertyRow == kRow_FieldCapacity) self.zoneProperties.advancedProperties.fieldCapacity = [self propertyValueFromPercentString:textField.text];
    }
    else if (textField.tag >= kTag_DetailedMonthKC) {
        if (self.useSameMonthKC) {
            self.sameMonthKCValue = [self propertyValueFromPercentString:textField.text];
            
            NSMutableArray *array = [NSMutableArray new];
            while (array.count < 12) [array addObject:self.sameMonthKCValue];
            
            self.zoneProperties.advancedProperties.detailedMonthsKc = array;
        }
        else {
            NSMutableArray *array = [self.zoneProperties.advancedProperties.detailedMonthsKc mutableCopy];
            if (!array) array = [NSMutableArray new];
            while (array.count < 12) [array addObject:@(0)];
            
            NSInteger month = textField.tag - kTag_DetailedMonthKC;
            array[month] = [self propertyValueFromPercentString:textField.text];
            
            self.zoneProperties.advancedProperties.detailedMonthsKc = array;
        }
    }
    
    [self.parent advancedPropertiesTableViewDidEdit];
}

#pragma mark - Actions

- (IBAction)onTallPlantSwitch:(UISwitch*)tallPlantSwitch {
    self.zoneProperties.advancedProperties.isTallPlant = @(tallPlantSwitch.isOn);
}

- (IBAction)onDetailedMonthKCSwitch:(UISwitch*)detailedMonthKCSwitch {
    self.useSameMonthKC = detailedMonthKCSwitch.isOn;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

@end
