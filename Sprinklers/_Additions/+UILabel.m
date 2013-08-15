//
//  +UILabel.m
//  RedRover
//
//  Created by Daniel Cristolovean on 8/2/12.
//
//

#import "+UILabel.h"

@implementation UILabel (Additions)

- (void)setVerticalAlignmentTop {
    
    CGSize textSize = [self.text sizeWithFont:self.font constrainedToSize:self.frame.size lineBreakMode:self.lineBreakMode];
    CGRect textRect = CGRectMake(self.frame.origin.x,self.frame.origin.y, self.frame.size.width, textSize.height);
    [self setFrame:textRect];
    [self setNeedsDisplay];
}

@end
