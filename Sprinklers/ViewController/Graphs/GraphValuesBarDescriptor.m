//
//  GraphValuesBarDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphValuesBarDescriptor.h"
#import "GraphsManager.h"

#pragma mark -

@implementation GraphValuesBarDescriptor

+ (GraphValuesBarDescriptor*)defaultDescriptor {
    GraphValuesBarDescriptor *descriptor = [GraphValuesBarDescriptor new];
    
    descriptor.valuesBarHeight = 16.0;
    descriptor.valuesFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.valuesColor = [UIColor whiteColor];
    descriptor.unitsFont = [UIFont boldSystemFontOfSize:12.0];
    descriptor.unitsColor = [UIColor whiteColor];
    
    return descriptor;
}

@end
