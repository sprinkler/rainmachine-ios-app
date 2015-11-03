//
//  GraphVisualAppearanceDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphVisualAppearanceDescriptor.h"
#import "Constants.h"

@implementation GraphVisualAppearanceDescriptor

+ (GraphVisualAppearanceDescriptor*)defaultDescriptor {
    GraphVisualAppearanceDescriptor *descriptor = [GraphVisualAppearanceDescriptor new];
    
    descriptor.backgroundColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
    descriptor.cornerRadius = 4.0;
    descriptor.graphContentLeadingPadding = 0.0;
    descriptor.graphContentTrailingPadding = 0.0;
    
    return descriptor;
}

@end
