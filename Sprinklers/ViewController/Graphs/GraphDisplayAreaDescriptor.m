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
#import "GraphTimeInterval.h"

@implementation GraphDisplayAreaDescriptor

+ (GraphDisplayAreaDescriptor*)defaultDescriptor {
    GraphDisplayAreaDescriptor *descriptor = [GraphDisplayAreaDescriptor new];
    
    descriptor.displayAreaHeight = 80.0;
    descriptor.graphDisplayColor = [UIColor whiteColor];
    descriptor.valuesDisplayColor = [UIColor whiteColor];
    descriptor.dashedLinesColor = [UIColor colorWithRed:206.0 / 255.0 green:225.0 / 255.0 blue:235.0 / 255.0 alpha:1.0];
    
    descriptor.graphBarsWidthDictionary = @{@(GraphTimeIntervalType_Weekly) : @(16.0),
                                            @(GraphTimeIntervalType_Monthly) : @(4.0),
                                            @(GraphTimeIntervalType_Yearly) : @(1.0)};
    
    descriptor.graphCirclesRadiusDictionary = @{@(GraphTimeIntervalType_Weekly) : @(2.5),
                                                @(GraphTimeIntervalType_Monthly) : @(1.5),
                                                @(GraphTimeIntervalType_Yearly) : @(0.0)};
    descriptor.graphBarsTopPadding = 4.0;
    descriptor.graphBarsBottomPadding = 6.0;
    
    descriptor.valuesFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.valuesDisplayHeight = 16.0;
    descriptor.scalingMode = GraphScalingMode_Scale;
    descriptor.minValue = 0.0;
    descriptor.midValue = 50.0;
    descriptor.maxValue = 100.0;
    
    descriptor.graphStyle = [GraphStyleBars new];
    
    return descriptor;
}

@end
