//
//  RainSensitivityGraphMonthCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityGraphMonthCell.h"
#import "RainSensitivityGraphMonthView.h"
#import "RainSensitivitySimulationGraphVC.h"
#import "MixerDailyValue.h"

#pragma mark -

@interface RainSensitivityGraphMonthCell ()

@end

#pragma mark -

@implementation RainSensitivityGraphMonthCell

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"RainSensitivityGraphMonthCell" owner:nil options:nil];
    return objects.lastObject;
}

- (void)awakeFromNib {
    self.cloudImageView.image = [UIImage imageNamed:@"shra"];
}

- (void)calculateValues {
    self.graphView.graphBackgroundValues = [self.rainSensitivitySimulationGraph.et0Array subarrayWithRange:NSMakeRange(self.firstDayIndex, self.numberOfDays)];
    self.graphView.graphForegroundValues = [self.rainSensitivitySimulationGraph.waterNeedArray subarrayWithRange:NSMakeRange(self.firstDayIndex, self.numberOfDays)];
    self.graphView.graphBackgroundColor = self.rainSensitivitySimulationGraph.savedIndicatorColor;
    self.graphView.graphForegroundColor = self.rainSensitivitySimulationGraph.wateredIndicatorColor;
    self.graphView.maxValue = self.rainSensitivitySimulationGraph.maxValue;
}

- (void)draw {
    [self.graphView draw];
}

@end
