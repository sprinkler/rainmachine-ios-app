//
//  RainSensitivityGraphMonthCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  RainSensitivityGraphMonthView;

@interface RainSensitivityGraphMonthCell : UIView

@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger numberOfDays;

@property (nonatomic, weak) IBOutlet RainSensitivityGraphMonthView *graphView;
@property (nonatomic, weak) IBOutlet UILabel *monthLabel;

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell;
- (void)draw;

@end
