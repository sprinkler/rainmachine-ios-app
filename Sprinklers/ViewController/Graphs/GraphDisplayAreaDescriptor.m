//
//  GraphDisplayAreaDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDisplayAreaDescriptor.h"
#import "GraphStyle.h"
#import "GraphStyleBars.h"

@implementation GraphDisplayAreaDescriptor

+ (GraphDisplayAreaDescriptor*)defaultDescriptor {
    GraphDisplayAreaDescriptor *descriptor = [GraphDisplayAreaDescriptor new];
    
    descriptor.displayAreaHeight = 80.0;
    descriptor.graphDisplayColor = [UIColor whiteColor];
    descriptor.valuesDisplayColor = [UIColor whiteColor];
    descriptor.dashedLinesColor = [UIColor colorWithRed:156.0 / 255.0 green:205.0 / 255.0 blue:230.0 / 255.0 alpha:1.0];
    
    descriptor.graphBarsWidth = 16.0;
    descriptor.graphBarsTopPadding = 2.0;
    descriptor.graphBarsBottomPadding = 2.0;
    
    descriptor.valuesFont = [UIFont systemFontOfSize:14.0];
    descriptor.valuesDisplayHeight = 16.0;
    descriptor.minValue = 0;
    descriptor.midValue = 50;
    descriptor.maxValue = 100;
    
    descriptor.graphStyle = [GraphStyleBars new];
    
    return descriptor;
}

@end
