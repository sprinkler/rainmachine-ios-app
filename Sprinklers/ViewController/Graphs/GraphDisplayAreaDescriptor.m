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
    descriptor.dashedLinesColor = [UIColor colorWithRed:206.0 / 255.0 green:225.0 / 255.0 blue:235.0 / 255.0 alpha:1.0];
    
    descriptor.graphBarsWidth = 16.0;
    descriptor.graphCirclesRadius = 2.5;
    descriptor.graphBarsTopPadding = 4.0;
    descriptor.graphBarsBottomPadding = 6.0;
    
    descriptor.valuesFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.valuesDisplayHeight = 16.0;
    descriptor.minValue = 0.0;
    descriptor.midValue = 50.0;
    descriptor.maxValue = 100.0;
    
    descriptor.graphStyle = [GraphStyleBars new];
    
    return descriptor;
}

@end
