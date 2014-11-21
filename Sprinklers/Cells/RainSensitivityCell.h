//
//  RainSensitivityCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RainSensitivityCell : UITableViewCell

@property (nonatomic, assign) double rainSensitivity;

@property (nonatomic, weak) IBOutlet UILabel *minimumValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *maximumValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *rainSensitivitySlider;

- (IBAction)onRainSensitivitySliderValueChanged:(id)sender;

@end
