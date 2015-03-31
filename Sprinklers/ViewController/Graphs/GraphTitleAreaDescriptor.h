//
//  GraphTitleAreaDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphTitleAreaDescriptor : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) UIFont *unitsFont;
@property (nonatomic, strong) UIColor *unitsColor;
@property (nonatomic, assign) CGFloat unitsWidth;

@property (nonatomic, assign) CGFloat titleAreaHeight;
@property (nonatomic, strong) UIColor *titleAreaSeparatorColor;

+ (GraphTitleAreaDescriptor*)defaultDescriptor;

@end
