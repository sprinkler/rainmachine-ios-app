//
//  WindSensitivityCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"

@interface WindSensitivityCell : UITableViewCell

@property (nonatomic, assign) double windSensitivity;
@property (nonatomic, weak) id<CellButtonDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *minimumValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *maximumValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *windSensitivitySlider;

- (IBAction)onWindSensitivitySliderValueChanged:(id)sender;

@end
