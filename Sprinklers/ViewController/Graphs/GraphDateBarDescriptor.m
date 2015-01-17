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
    descriptor.dateBarBottomPadding = 2.0;
    descriptor.timeIntervalFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.timeIntervalColor = [UIColor whiteColor];
    descriptor.dateValuesFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.dateValuesColor = [UIColor whiteColor];
    descriptor.dateValueSelectionColor = [UIColor whiteColor];
    descriptor.selectedDateValueIndex = -1;
    
    return descriptor;
}

@end
