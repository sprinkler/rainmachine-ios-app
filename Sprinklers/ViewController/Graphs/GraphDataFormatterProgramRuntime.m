//
//  GraphDataFormatterProgramRuntime.m
//  Sprinklers
//
//  Created by Istvan Sipos on 07/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataFormatterProgramRuntime.h"
#import "Constants.h"

@implementation GraphDataFormatterProgramRuntime

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    GraphDataFormatter *formatter1 = [GraphDataFormatter new];
    formatter1.subFormatterIndex = 0;
    formatter1.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeDateString),
                                 GraphDataFormatterDescriptorFieldKey : @"date",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentCenter),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"Programed",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"Watered",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]}];
    
    GraphDataFormatter *formatter2 = [GraphDataFormatter new];
    formatter2.subFormatterIndex = 1;
    formatter2.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"TOTAL",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                 GraphDataFormatterDescriptorFieldKey : @"userDuration",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                 GraphDataFormatterDescriptorFieldKey : @"realDuration",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1]}];
    
    GraphDataFormatter *formatter3 = [GraphDataFormatter new];
    formatter3.formatterKey = @"zones";
    formatter3.subFormatterIndex = 2;
    formatter3.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeNumber),
                                 GraphDataFormatterDescriptorFieldKey : @"zoneId",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor],
                                 GraphDataFormatterDescriptorFieldFont : [UIFont systemFontOfSize:15.0]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                 GraphDataFormatterDescriptorFieldKey : @"userDurationSum",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor],
                                 GraphDataFormatterDescriptorFieldFont : [UIFont systemFontOfSize:15.0]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                 GraphDataFormatterDescriptorFieldKey : @"realDurationSum",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor],
                                 GraphDataFormatterDescriptorFieldFont : [UIFont systemFontOfSize:15.0]}];
    
    self.subFormatters = @[formatter1, formatter2, formatter3];
    
    return self;
}

@end
