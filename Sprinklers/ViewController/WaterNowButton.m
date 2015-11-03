//
//  WaterNowButton.m
//  Sprinklers
//
//  Created by Istvan Sipos on 13/05/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WaterNowButton.h"

@implementation WaterNowButton

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = self.bounds;
}

@end
