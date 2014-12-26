//
//  GraphIconsBarDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphIconsBarDescriptor.h"
#import "GraphsManager.h"
#import "Utils.h"

#pragma mark -

@implementation GraphIconsBarDescriptor

+ (GraphIconsBarDescriptor*)defaultDescriptor {
    GraphIconsBarDescriptor *descriptor = [GraphIconsBarDescriptor new];
    
    descriptor.iconsBarHeight = 24.0;
    descriptor.iconsHeight = 22.0;
    descriptor.iconImagesColor = [UIColor whiteColor];
    
    return descriptor;
}

@end
