//
//  RainSensitivityGraphMonthCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RainSensitivityGraphMonthView;
@class RainSensitivitySimulationGraphVC;

@interface RainSensitivityGraphMonthCell : UIView

@property (nonatomic, weak) RainSensitivitySimulationGraphVC *rainSensitivitySimulationGraph;

@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger firstDayIndex;
@property (nonatomic, assign) NSInteger numberOfDays;

@property (nonatomic, weak) IBOutlet RainSensitivityGraphMonthView *graphView;
@property (nonatomic, weak) IBOutlet UIView *trailingSeparatorView;
@property (nonatomic, weak) IBOutlet UIImageView *cloudImageView;
@property (nonatomic, weak) IBOutlet UILabel *monthLabel;

@property (nonatomic, readonly) BOOL shouldDrawClouds;

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell;
- (void)calculateValues;
- (void)draw;

@end
