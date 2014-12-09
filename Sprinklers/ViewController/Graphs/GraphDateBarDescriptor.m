//
//  GraphDateBarDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDateBarDescriptor.h"

@implementation GraphDateBarDescriptor

+ (GraphDateBarDescriptor*)defaultDescriptor {
    GraphDateBarDescriptor *descriptor = [GraphDateBarDescriptor new];
    
    descriptor.dateBarHeight = 18.0;
    descriptor.timeIntervalFont = [UIFont systemFontOfSize:14.0];
    descriptor.timeIntervalColor = [UIColor whiteColor];
    descriptor.timeIntervalValue = @"oct";
    descriptor.dateValuesFont = [UIFont systemFontOfSize:14.0];
    descriptor.dateValuesColor = [UIColor whiteColor];
    descriptor.dateValues = @[@"08", @"09", @"10", @"11", @"12", @"13", @"14"];
    
    return descriptor;
}

@end
