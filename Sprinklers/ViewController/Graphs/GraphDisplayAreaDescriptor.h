//
//  GraphDisplayAreaDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphStyle;

@interface GraphDisplayAreaDescriptor : NSObject

@property (nonatomic, assign) CGFloat displayAreaHeight;
@property (nonatomic, strong) UIColor *graphDisplayColor;
@property (nonatomic, strong) UIColor *valuesDisplayColor;
@property (nonatomic, strong) UIColor *dashedLinesColor;

@property (nonatomic, assign) CGFloat graphBarsWidth;
@property (nonatomic, assign) CGFloat graphBarsTopPadding;
@property (nonatomic, assign) CGFloat graphBarsBottomPadding;

@property (nonatomic, strong) UIFont *valuesFont;
@property (nonatomic, assign) CGFloat valuesDisplayHeight;
@property (nonatomic, assign) NSInteger minValue;
@property (nonatomic, assign) NSInteger maxValue;
@property (nonatomic, assign) NSInteger midValue;

@property (nonatomic, strong) GraphStyle *graphStyle;

+ (GraphDisplayAreaDescriptor*)defaultDescriptor;

@end
