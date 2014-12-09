//
//  GraphDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDescriptor.h"
#import "GraphTimeInterval.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"

@implementation GraphDescriptor

+ (GraphDescriptor*)defaultDescriptor {
    GraphDescriptor *descriptor = [GraphDescriptor new];
    
    descriptor.visualAppearanceDescriptor = [GraphVisualAppearanceDescriptor defaultDescriptor];
    descriptor.titleAreaDescriptor = [GraphTitleAreaDescriptor defaultDescriptor];
    descriptor.displayAreaDescriptor = [GraphDisplayAreaDescriptor defaultDescriptor];
    descriptor.dateBarDescriptor = [GraphDateBarDescriptor defaultDescriptor];
    
    return descriptor;
}

- (CGFloat)totalGraphHeight {
    return self.titleAreaDescriptor.titleAreaHeight +
        self.iconsBarDescriptor.iconsBarHeight +
        self.valuesBarDescriptor.valuesBarHeight +
        self.displayAreaDescriptor.displayAreaHeight +
        self.dateBarDescriptor.dateBarHeight + 6.0;
}

@end
