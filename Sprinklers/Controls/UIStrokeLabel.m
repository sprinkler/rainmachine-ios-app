//
//  UIStrokeLabel.m
//  BounceThatApp
//
//  Created by Daniel Cristolovean on 4/3/12.
//  Copyright (c) 2012 VLF Networks. All rights reserved.
//

#import "UIStrokeLabel.h"

@implementation UIStrokeLabel

@synthesize strokeColor, strokeWidth;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.strokeColor = [UIColor blackColor];
        self.strokeWidth = 1.0f;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, strokeWidth);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = strokeColor;
    [super drawTextInRect:CGRectMake(rect.origin.x, rect.origin.y+1, rect.size.width, rect.size.height)];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
}

@end
