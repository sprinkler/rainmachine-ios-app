//
//  +UILabel.m
//  RedRover
//

#import "+UIButton.h"

@implementation UIButton (Additions)

- (void)setupAsRoundColouredButton:(UIColor*)color {
    
  [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];
  [self.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
  self.backgroundColor = color;
  self.layer.cornerRadius = 10.0f;
}

@end
