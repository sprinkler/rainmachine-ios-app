//
//  RainSensitivityCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityCell.h"

@implementation RainSensitivityCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - Accessors

- (void)setRainSensitivity:(double)rainSensitivity {
    self.rainSensitivitySlider.value = rainSensitivity;
    [self onRainSensitivitySliderValueChanged:self.rainSensitivitySlider];
}

- (double)rainSensitivity {
    return self.rainSensitivitySlider.value;
}

#pragma mark - Actions

- (IBAction)onRainSensitivitySliderValueChanged:(UISlider*)slider {
    self.maximumValueLabel.text = [NSString stringWithFormat:@"%d%%",(int)(slider.value * 100)];
    [self.delegate onCellSliderValueChanged:slider];
}

@end
