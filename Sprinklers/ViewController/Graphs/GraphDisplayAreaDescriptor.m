//
//  GraphDisplayAreaDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDisplayAreaDescriptor.h"

@implementation GraphDisplayAreaDescriptor

+ (GraphDisplayAreaDescriptor*)defaultDescriptor {
    GraphDisplayAreaDescriptor *descriptor = [GraphDisplayAreaDescriptor new];
    
    descriptor.displayAreaHeight = 80.0;
    
    return descriptor;
}

@end
