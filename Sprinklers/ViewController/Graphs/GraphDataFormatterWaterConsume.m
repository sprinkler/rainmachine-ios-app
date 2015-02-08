//
//  GraphDataFormatterWaterConsume.m
//  Sprinklers
//
//  Created by Istvan Sipos on 08/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataFormatterWaterConsume.h"
#import "ServerProxy.h"

@implementation GraphDataFormatterWaterConsume

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    if ([ServerProxy usesAPI4]) {
        GraphDataFormatter *formatter1 = [GraphDataFormatter new];
        formatter1.subFormatterIndex = 0;
        formatter1.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeDateString),
                                     GraphDataFormatterDescriptorFieldKey : @"date",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentCenter),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]}];
        
        GraphDataFormatter *formatter2 = [GraphDataFormatter new];
        formatter2.subFormatterIndex = 1;
        formatter2.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                     GraphDataFormatterDescriptorFieldValue : @"Programed",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                                   @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                     GraphDataFormatterDescriptorFieldKey : @"simulatedUserDurationSum",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor]}];
        
        GraphDataFormatter *formatter3 = [GraphDataFormatter new];
        formatter3.subFormatterIndex = 2;
        formatter3.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                     GraphDataFormatterDescriptorFieldValue : @"Watered",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                                   @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeTime),
                                     GraphDataFormatterDescriptorFieldKey : @"simulatedRealDurationSum",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor]}];
        
        self.subFormatters = @[formatter1, formatter2, formatter3];
    }
    else if ([ServerProxy usesAPI3]) {
        GraphDataFormatter *formatter1 = [GraphDataFormatter new];
        formatter1.subFormatterIndex = 0;
        formatter1.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeDateString),
                                     GraphDataFormatterDescriptorFieldKey : @"date",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentCenter),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]}];
        
        GraphDataFormatter *formatter2 = [GraphDataFormatter new];
        formatter2.subFormatterIndex = 1;
        formatter2.descriptors = @[@{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypeString),
                                     GraphDataFormatterDescriptorFieldValue : @"Water Consumed",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentLeft),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor blackColor]},
                                   @{GraphDataFormatterDescriptorFieldType : @(GraphDataFormatterFieldTypePercetage),
                                     GraphDataFormatterDescriptorFieldKey : @"percentage",
                                     GraphDataFormatterDescriptorFieldAlignment : @(NSTextAlignmentRight),
                                     GraphDataFormatterDescriptorFieldColor : [UIColor darkGrayColor]}];
        
        self.subFormatters = @[formatter1, formatter2];
    }
    
    return self;
}

@end
