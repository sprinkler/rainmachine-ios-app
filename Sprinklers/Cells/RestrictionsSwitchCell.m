//
//  RestrictionsSwitchCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 26/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsSwitchCell.h"
#import "RestrictionsVC.h"

@implementation RestrictionsSwitchCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onSwitch:(id)sender {
    if ([self.delegate respondsToSelector:@selector(onCellSwitch:)]) {
        [self.delegate onCellSwitch:self];
    }
}

@end
