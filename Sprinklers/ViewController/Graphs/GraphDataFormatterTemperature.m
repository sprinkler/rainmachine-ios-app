//
//  GraphDataFormatterTemperature.m
//  Sprinklers
//
//  Created by Istvan Sipos on 08/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataFormatterTemperature.h"

@implementation GraphDataFormatterTemperature

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    GraphDataFormatter *formatter1 = [GraphDataFormatter new];
    formatter1.subFormatterIndex = 0;
    formatter1.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeDate),
                                 GraphDataFormatterDescriptorFieldKey : @"date",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentCenter),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]}];
    
    GraphDataFormatter *formatter2 = [GraphDataFormatter new];
    formatter2.subFormatterIndex = 1;
    formatter2.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"High",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTemperature),
                                 GraphDataFormatterDescriptorFieldKey : @"maxt",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor]}];
    
    GraphDataFormatter *formatter3 = [GraphDataFormatter new];
    formatter3.subFormatterIndex = 2;
    formatter3.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                 GraphDataFormatterDescriptorFieldValue : @"Low",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                               @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTemperature),
                                 GraphDataFormatterDescriptorFieldKey : @"mint",
                                 GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                 GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor]}];
    
    self.subFormatters = @[formatter1, formatter2, formatter3];
    
    return self;
}

@end
