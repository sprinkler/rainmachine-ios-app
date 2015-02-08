//
//  GraphDataFormatter.m
//  Sprinklers
//
//  Created by Istvan Sipos on 07/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataFormatter.h"
#import "GraphDataSource.h"
#import "GraphDataFormatterCell1.h"
#import "GraphDataFormatterCell2.h"
#import "GraphDataFormatterCell3.h"
#import "Utils.h"

NSString *GraphDataFormatterDescriptorFieldType             = @"GraphDataFormatterDescriptorFieldType";
NSString *GraphDataFormatterDescriptorFieldKey              = @"GraphDataFormatterDescriptorFieldKey";
NSString *GraphDataFormatterDescriptorFieldValue            = @"GraphDataFormatterDescriptorFieldValue";
NSString *GraphDataFormatterDescriptorFieldAlignment        = @"GraphDataFormatterDescriptorFieldAlignment";
NSString *GraphDataFormatterDescriptorFieldColor            = @"GraphDataFormatterDescriptorFieldColor";
NSString *GraphDataFormatterDescriptorFieldFont             = @"GraphDataFormatterDescriptorFieldFont";

#pragma mark -

@interface GraphDataFormatter ()

- (GraphDataFormatter*)graphDataFormatterForIndexPath:(NSIndexPath*)indexPath;

- (void)updateLabel:(UILabel*)label descriptor:(NSDictionary*)descriptor value:(id)value;
- (NSString*)formattedStringFromValue:(id)value fieldType:(GraphDataFormatterFieldType)fieldType;
- (NSString*)formattedNumberFromValue:(id)value;
- (NSString*)formattedDateStringFromString:(NSString*)string;
- (NSString*)formattedDateStringFromDate:(NSDate*)date;
- (NSString*)formattedTimeStringFromNumber:(NSNumber*)number;
- (NSString*)formattedTemperatureStringFromNumber:(NSNumber*)number;

@property (nonatomic, strong) NSDateFormatter *reverseDateFormatter;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

#pragma mark -

@implementation GraphDataFormatter

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    self.reverseDateFormatter = [NSDateFormatter new];
    self.reverseDateFormatter.dateFormat = @"yyyy-MM-dd";
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateFormat = @"MMM dd, yyyy";
    
    return self;
}

- (void)registerFormatterCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[UINib nibWithNibName:@"GraphDataFormatterCell1" bundle:nil] forCellReuseIdentifier:@"GraphDataFormatterCell1"];
    [tableView registerNib:[UINib nibWithNibName:@"GraphDataFormatterCell2" bundle:nil] forCellReuseIdentifier:@"GraphDataFormatterCell2"];
    [tableView registerNib:[UINib nibWithNibName:@"GraphDataFormatterCell3" bundle:nil] forCellReuseIdentifier:@"GraphDataFormatterCell3"];
    [tableView registerNib:[UINib nibWithNibName:@"GraphDataFormatterCell4" bundle:nil] forCellReuseIdentifier:@"GraphDataFormatterCell4"];
}

- (NSInteger)numberOfSection {
    return self.graphDataSourceValues.count;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    for (GraphDataFormatter *subFormatter in self.subFormatters) {
        if (!subFormatter.formatterKey.length) numberOfRows++;
        else {
            id value = [self.graphDataSourceValues valueForKey:subFormatter.formatterKey];
            if (![value isKindOfClass:[NSArray class]]) numberOfRows++;
            else numberOfRows += ((NSArray*)value).count;
        }
        
    }
    return numberOfRows;
}

- (CGFloat)heighForRowAtIndexPath:(NSIndexPath*)indexPath {
    GraphDataFormatter *graphDataFormatter = [self graphDataFormatterForIndexPath:indexPath];
    if (graphDataFormatter.descriptors.count == 4) return 88.0;
    return 44.0;
}

- (UITableViewCell*)cellForRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView {
    static NSString *GraphDataFormatterCell1Identifier = @"GraphDataFormatterCell1";
    static NSString *GraphDataFormatterCell2Identifier = @"GraphDataFormatterCell2";
    static NSString *GraphDataFormatterCell3Identifier = @"GraphDataFormatterCell3";
    static NSString *GraphDataFormatterCell4Identifier = @"GraphDataFormatterCell4";
    
    GraphDataFormatter *graphDataFormatter = [self graphDataFormatterForIndexPath:indexPath];
    
    UITableViewCell *cell = nil;
    if (graphDataFormatter.descriptors.count == 1) cell = [tableView dequeueReusableCellWithIdentifier:GraphDataFormatterCell1Identifier];
    else if (graphDataFormatter.descriptors.count == 2) cell = [tableView dequeueReusableCellWithIdentifier:GraphDataFormatterCell2Identifier];
    else if (graphDataFormatter.descriptors.count == 3) cell = [tableView dequeueReusableCellWithIdentifier:GraphDataFormatterCell3Identifier];
    else if (graphDataFormatter.descriptors.count == 4) cell = [tableView dequeueReusableCellWithIdentifier:GraphDataFormatterCell4Identifier];
    
    id value = self.graphDataSourceValues[indexPath.section];
    if (graphDataFormatter.formatterKey.length) {
        value = [value valueForKey:graphDataFormatter.formatterKey];
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *arrayValue = (NSArray*)value;
            NSInteger arrayIndex = indexPath.row - graphDataFormatter.subFormatterIndex;
            if (arrayIndex < arrayValue.count) value = [arrayValue objectAtIndex:arrayIndex];
            else value = nil;
        }
    }

    NSDictionary *descriptor1 = (graphDataFormatter.descriptors.count > 0 ? graphDataFormatter.descriptors[0] : nil);
    NSDictionary *descriptor2 = (graphDataFormatter.descriptors.count > 1 ? graphDataFormatter.descriptors[1] : nil);
    NSDictionary *descriptor3 = (graphDataFormatter.descriptors.count > 2 ? graphDataFormatter.descriptors[2] : nil);
    NSDictionary *descriptor4 = (graphDataFormatter.descriptors.count > 3 ? graphDataFormatter.descriptors[3] : nil);
    
    UILabel *label1 = (descriptor1 ? [cell valueForKey:@"label1"] : nil);
    UILabel *label2 = (descriptor2 ? [cell valueForKey:@"label2"] : nil);
    UILabel *label3 = (descriptor3 ? [cell valueForKey:@"label3"] : nil);
    UILabel *label4 = (descriptor4 ? [cell valueForKey:@"label4"] : nil);
    
    if (descriptor1) [self updateLabel:label1 descriptor:descriptor1 value:value];
    if (descriptor2) [self updateLabel:label2 descriptor:descriptor2 value:value];
    if (descriptor3) [self updateLabel:label3 descriptor:descriptor3 value:value];
    if (descriptor4) [self updateLabel:label4 descriptor:descriptor4 value:value];
    
    return cell;
}

#pragma mark - Helper methods

- (GraphDataFormatter*)graphDataFormatterForIndexPath:(NSIndexPath*)indexPath {
    if (!self.subFormatters.count) return self;
    if (indexPath.row < self.subFormatters.count) return self.subFormatters[indexPath.row];
    return self.subFormatters.lastObject;
}

- (void)updateLabel:(UILabel*)label descriptor:(NSDictionary*)descriptor value:(id)value {
    GraphDataFormatterFieldType descriptorType = (GraphDataFormatterFieldType)[[descriptor valueForKey:GraphDataFormatterDescriptorFieldType] integerValue];
    NSString *descriptorKey = [descriptor valueForKey:GraphDataFormatterDescriptorFieldKey];
    NSString *descriptorValue = [descriptor valueForKey:GraphDataFormatterDescriptorFieldValue];
    NSNumber *descriptorAlignment = [descriptor valueForKey:GraphDataFormatterDescriptorFieldAlignment];
        
    if (descriptorValue.length) label.text = descriptorValue;
    else if (descriptorKey) label.text = [self formattedStringFromValue:[value valueForKey:descriptorKey] fieldType:descriptorType];
    else label.text = nil;
    
    if (descriptorAlignment) label.textAlignment = descriptorAlignment.integerValue;
    else label.textAlignment = NSTextAlignmentLeft;
    
    label.textColor = [descriptor valueForKey:GraphDataFormatterDescriptorFieldColor];
    label.font = [descriptor valueForKey:GraphDataFormatterDescriptorFieldFont];
}

- (NSString*)formattedStringFromValue:(id)value fieldType:(GraphDataFormatterFieldType)fieldType {
    if (fieldType == GraphDataFormatterFieldTypeString) return value;
    if (fieldType == GraphDataFormatterFieldTypeNumber) return [self formattedNumberFromValue:value];
    if (fieldType == GraphDataFormatterFieldTypeDateString) return [self formattedDateStringFromString:value];
    if (fieldType == GraphDataFormatterFieldTypeDate) return [self formattedDateStringFromDate:value];
    if (fieldType == GraphDataFormatterFieldTypeTime) return [self formattedTimeStringFromNumber:value];
    if (fieldType == GraphDataFormatterFieldTypeTemperature) return [self formattedTemperatureStringFromNumber:value];
    return nil;
}

- (NSString*)formattedDateStringFromString:(NSString*)string {
    return [self.dateFormatter stringFromDate:[self.reverseDateFormatter dateFromString:string]];
}

- (NSString*)formattedDateStringFromDate:(NSDate*)date {
    return [self.dateFormatter stringFromDate:date];
}

- (NSString*)formattedNumberFromValue:(id)value {
    return [NSString stringWithFormat:@"%d",[value intValue]];
}

- (NSString*)formattedTimeStringFromNumber:(NSNumber*)number {
    NSInteger totalMins = number.integerValue / 60;
    NSInteger hours = totalMins / 60;
    NSInteger mins = totalMins - hours  * 60;
    
    NSString *formattedString = [NSString stringWithFormat:@"%dmin",(int)mins];
    if (hours) formattedString = [NSString stringWithFormat:@"%dh %@",(int)hours,formattedString];
    
    return formattedString;
}

- (NSString*)formattedTemperatureStringFromNumber:(NSNumber*)number {
    return [NSString stringWithFormat:@"%d°%@",number.intValue,[Utils sprinklerTemperatureUnits]];
}

@end
