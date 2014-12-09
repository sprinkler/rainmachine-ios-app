//
//  GraphIconsBarDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphIconsBarDescriptor : NSObject

@property (nonatomic, assign) CGFloat iconsBarHeight;
@property (nonatomic, assign) CGFloat iconsHeight;
@property (nonatomic, strong) NSArray *iconImages;
@property (nonatomic, strong) UIColor *iconImagesColor;

+ (GraphIconsBarDescriptor*)defaultDescriptor;

@end
