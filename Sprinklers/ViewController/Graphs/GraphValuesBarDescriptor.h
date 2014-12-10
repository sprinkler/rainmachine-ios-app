//
//  GraphValuesBarDescriptor.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GraphValuesBarDescriptor : NSObject

@property (nonatomic, assign) CGFloat valuesBarHeight;
@property (nonatomic, strong) UIFont *valuesFont;
@property (nonatomic, strong) UIColor *valuesColor;
@property (nonatomic, strong) UIFont *unitsFont;
@property (nonatomic, strong) UIColor *unitsColor;
@property (nonatomic, strong) NSString *units;

+ (GraphValuesBarDescriptor*)defaultDescriptor;

@end
