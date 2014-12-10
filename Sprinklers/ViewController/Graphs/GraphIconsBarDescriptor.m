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

@interface GraphIconsBarDescriptor ()

+ (NSArray*)createBarIconImages;

@end

#pragma mark -

@implementation GraphIconsBarDescriptor

+ (GraphIconsBarDescriptor*)defaultDescriptor {
    GraphIconsBarDescriptor *descriptor = [GraphIconsBarDescriptor new];
    
    descriptor.iconsBarHeight = 24.0;
    descriptor.iconsHeight = 22.0;
    descriptor.iconImagesColor = [UIColor whiteColor];
    descriptor.iconImages = [self createBarIconImages];
    
    return descriptor;
}

+ (NSArray*)createBarIconImages {
    NSMutableArray *iconImages = [NSMutableArray new];
    
    if (![GraphsManager randomizeTestData]) {
        UIImage *image = [UIImage imageNamed:@"na"];
        for (NSInteger index = 0; index < 7; index++) [iconImages addObject:[UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation]];
    } else {
        for (NSInteger index = 0; index < 7; index++) {
            UIImage *image = [Utils smallWhiteWeatherImageFromCode:@((int)((double)rand() / (double)RAND_MAX * 24.0))];
            UIImage *iconImage = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
            [iconImages addObject:iconImage];
        }
    }
    
    return iconImages;
}

@end
