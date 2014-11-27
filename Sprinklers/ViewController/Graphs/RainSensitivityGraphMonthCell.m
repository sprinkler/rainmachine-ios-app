//
//  RainSensitivityGraphMonthCell.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityGraphMonthCell.h"
#import "RainSensitivityGraphMonthView.h"

#pragma mark -

@interface RainSensitivityGraphMonthCell ()

@end

#pragma mark -

@implementation RainSensitivityGraphMonthCell

+ (RainSensitivityGraphMonthCell*)newGraphMonthCell {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"RainSensitivityGraphMonthCell" owner:nil options:nil];
    return objects.lastObject;
}

- (void)draw {
    NSMutableArray *values = [NSMutableArray new];
    for (NSInteger day = 0; day < self.numberOfDays; day++) {
        [values addObject:@((double)rand() / (double)RAND_MAX)];
    }
    self.graphView.values = values;
}

@end
