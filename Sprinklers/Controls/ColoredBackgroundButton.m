//
//  ColoredBackgroundButton.m
//  Sprinklers
//
//  Created by Fabian Matyas on 10/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ColoredBackgroundButton.h"
#import "+UIButton.h"

@interface ColoredBackgroundButton ()
    @property (strong, nonatomic) UIColor *theCustomBackgroundColor;
    @property (strong, nonatomic) UIColor *theCustomBackgroundColorHighlighted;
@end

@implementation ColoredBackgroundButton

- (void)setCustomBackgroundColorFromComponents:(CGFloat[3])backgroundColorComponents
{
    float highlightPercentage = 0.75;
    self.theCustomBackgroundColor = [UIColor colorWithRed:backgroundColorComponents[0] green:backgroundColorComponents[1] blue:backgroundColorComponents[2] alpha:1];
    self.theCustomBackgroundColorHighlighted = [UIColor colorWithRed:highlightPercentage * backgroundColorComponents[0] green:highlightPercentage * backgroundColorComponents[1] blue:highlightPercentage * backgroundColorComponents[2] alpha:1];

    [self setupAsRoundColouredButton:self.theCustomBackgroundColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.state == UIControlStateHighlighted) {
        self.backgroundColor = self.theCustomBackgroundColorHighlighted;
    } else {
        self.backgroundColor = self.theCustomBackgroundColor;
    }
}

@end
