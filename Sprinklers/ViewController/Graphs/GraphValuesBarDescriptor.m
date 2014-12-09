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

@interface GraphValuesBarDescriptor ()

+ (NSArray*)createValues;

@end

#pragma mark -

@implementation GraphValuesBarDescriptor

+ (GraphValuesBarDescriptor*)defaultDescriptor {
    GraphValuesBarDescriptor *descriptor = [GraphValuesBarDescriptor new];
    
    descriptor.valuesBarHeight = 16.0;
    descriptor.valuesFont = [UIFont systemFontOfSize:14.0];
    descriptor.valuesColor = [UIColor whiteColor];
    descriptor.values = [self createValues];
    descriptor.unitsFont = [UIFont systemFontOfSize:14.0];
    descriptor.unitsColor = [UIColor whiteColor];
    
    return descriptor;
}

+ (NSArray*)createValues {
    NSMutableArray *values = [NSMutableArray new];
    
    if (![GraphsManager randomizeTestData]) {
        [values addObjectsFromArray:@[@0,@0,@0,@0,@0,@0,@0]];
    } else {
        for (NSInteger index = 0; index < 7; index++) {
            [values addObject:@((int)((double)rand() / (double)RAND_MAX * 100.0))];
        }
    }
    
    return values;
}

@end
