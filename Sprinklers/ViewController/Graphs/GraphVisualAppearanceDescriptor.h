//
//  GraphVisualAppearanceDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphVisualAppearanceDescriptor : NSObject

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) CGFloat cornerRadius;

+ (GraphVisualAppearanceDescriptor*)defaultDescriptor;

@end
