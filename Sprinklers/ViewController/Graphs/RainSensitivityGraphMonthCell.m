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
#import "+UIImage.h"

#pragma mark -

@interface RainSensitivityGraphMonthCell ()

- (void)updateCloudImage;

@end

#pragma mark -

@implementation RainSensitivityGraphMonthCell

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"RainSensitivityGraphMonthCell" owner:nil options:nil];
    return objects.lastObject;
}

- (BOOL)shouldDrawClouds {
    return NO;
}

- (void)calculateValues {
    self.graphView.graphBackgroundValues = [self.rainSensitivitySimulationGraph.et0Array subarrayWithRange:NSMakeRange(self.firstDayIndex, self.numberOfDays)];
    self.graphView.graphForegroundValues = [self.rainSensitivitySimulationGraph.waterNeedArray subarrayWithRange:NSMakeRange(self.firstDayIndex, self.numberOfDays)];
    self.graphView.graphBackgroundColor = self.rainSensitivitySimulationGraph.savedIndicatorColor;
    self.graphView.graphForegroundColor = self.rainSensitivitySimulationGraph.wateredIndicatorColor;
    self.graphView.maxValue = self.rainSensitivitySimulationGraph.maxValue;
}

- (void)awakeFromNib {
    self.cloudImageView.image = (self.shouldDrawClouds ? [[UIImage imageNamed:@"shra"] imageByFillingWithColor:self.rainSensitivitySimulationGraph.cloudsDarkBlueColor] : nil);
    self.cloudImageView.hidden = !self.shouldDrawClouds;
    self.graphView.graphValuesDivider = (self.shouldDrawClouds ? 1.5 : 1.2);
}

- (void)draw {
    [self.graphView draw];
    if (self.shouldDrawClouds) [self updateCloudImage];
}

- (void)updateCloudImage {
    double savedWater = [self.rainSensitivitySimulationGraph.savedWaterArray[self.month] doubleValue];
    double cloudColorAlphaValue = (savedWater / 100.0);
    if (cloudColorAlphaValue > 1.0) cloudColorAlphaValue = 1.0;
    
    self.cloudImageView.alpha = cloudColorAlphaValue;
}

@end
