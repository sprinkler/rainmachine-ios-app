//
//  RestrictionsCheckCell.m
//  Sprinklers
//
//  Created by Fabian Matyas on 28/09/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RestrictionsCheckCell.h"

@implementation RestrictionsCheckCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (IBAction)onCheck:(id)sender {
    self.checkmarkButton.selected = !self.checkmarkButton.selected;
    if ([self.delegate respondsToSelector:@selector(onCell:checkmarkState:)]) {
        [self.delegate onCell:self checkmarkState:self.checkmarkButton.selected];
    }
}

@end
