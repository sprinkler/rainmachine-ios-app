//
//  RainSensitivityGraphMonthCell.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RainSensitivityGraphMonthCell : UIView

@property (nonatomic, weak) IBOutlet UILabel *monthLabel;

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell;

@end
