//
//  RainSensitivityGraphMonthCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityGraphMonthCell.h"

@implementation RainSensitivityGraphMonthCell

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"RainSensitivityGraphMonthCell" owner:nil options:nil];
    return objects.lastObject;
}

@end
