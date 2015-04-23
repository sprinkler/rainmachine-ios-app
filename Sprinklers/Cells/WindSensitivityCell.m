//
//  WindSensitivityCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "WindSensitivityCell.h"

@implementation WindSensitivityCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - Accessors

- (void)setWindSensitivity:(double)windSensitivity {
    self.windSensitivitySlider.value = windSensitivity;
    [self onWindSensitivitySliderValueChanged:self.windSensitivitySlider];
}

- (double)windSensitivity {
    return self.windSensitivitySlider.value;
}

#pragma mark - Actions

- (IBAction)onWindSensitivitySliderValueChanged:(UISlider*)slider {
    self.maximumValueLabel.text = [NSString stringWithFormat:@"%d%%",(int)(slider.value * 100)];
    [self.delegate onCellSliderValueChanged:slider];
}

@end
