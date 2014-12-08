//
//  RainSensitivityGraphMonthView.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RainSensitivityGraphMonthView : UIView

@property (nonatomic, strong) NSArray *graphBackgroundValues;
@property (nonatomic, strong) NSArray *graphForegroundValues;
@property (nonatomic, strong) UIColor *graphBackgroundColor;
@property (nonatomic, strong) UIColor *graphForegroundColor;
@property (nonatomic, assign) double maxValue;
@property (nonatomic, assign) double graphValuesDivider;

- (void)draw;

@end
