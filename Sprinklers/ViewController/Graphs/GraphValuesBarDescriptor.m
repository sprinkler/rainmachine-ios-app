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
    descriptor.valuesFont = [UIFont systemFontOfSize:12.0];
    descriptor.valuesColor = [UIColor whiteColor];
    descriptor.unitsFont = [UIFont systemFontOfSize:12.0];
    descriptor.unitsColor = [UIColor whiteColor];
    descriptor.valuesRoundingMode = GraphValuesRoundingMode_None;
    
    return descriptor;
}

- (void)reloadUnits {
    if (self.unitsReloadHandler) self.unitsReloadHandler(self);
}

@end
