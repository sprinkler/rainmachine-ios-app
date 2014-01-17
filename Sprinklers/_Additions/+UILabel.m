//
//  +UILabel.m
//  RedRover
//
//  Created by Daniel Cristolovean on 8/2/12.
//
//

#import "+UILabel.h"
#import "Constants.h"

@implementation UILabel (Additions)

- (void)setVerticalAlignmentTop {
    
    CGSize textSize = [self.text sizeWithFont:self.font constrainedToSize:self.frame.size lineBreakMode:self.lineBreakMode];
    CGRect textRect = CGRectMake(self.frame.origin.x,self.frame.origin.y, self.frame.size.width, textSize.height);
    [self setFrame:textRect];
    [self setNeedsDisplay];
}

- (void)setCustomRMFontWithCode:(unsigned short)code size:(int)size
{
    self.font = [UIFont fontWithName:kCustomRMFontName size:size];
    self.text = [NSString stringWithFormat:@"%C", code];
}

@end
