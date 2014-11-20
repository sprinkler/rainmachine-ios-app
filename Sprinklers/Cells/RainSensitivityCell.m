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

#pragma mark - Actions

- (IBAction)onRainSensitivitySliderValueChanged:(UISlider*)slider {
    self.maximumValueLabel.text = [NSString stringWithFormat:@"%ld%%",(long)(slider.value * 100.0)];
}

@end
