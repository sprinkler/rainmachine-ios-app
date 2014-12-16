//
//  GraphTitleAreaDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphTitleAreaDescriptor.h"

@implementation GraphTitleAreaDescriptor

+ (GraphTitleAreaDescriptor*)defaultDescriptor {
    GraphTitleAreaDescriptor *descriptor = [GraphTitleAreaDescriptor new];
    
    descriptor.titleFont = [UIFont boldSystemFontOfSize:14.0];
    descriptor.titleColor = [UIColor whiteColor];
    descriptor.unitsFont = [UIFont boldSystemFontOfSize:14.0];
    descriptor.unitsColor = [UIColor whiteColor];
    descriptor.titleAreaHeight = 23.0;
    descriptor.titleAreaSeparatorColor = [UIColor colorWithRed:156.0 / 255.0 green:205.0 / 255.0 blue:230.0 / 255.0 alpha:1.0];
    
    return descriptor;
}

@end
