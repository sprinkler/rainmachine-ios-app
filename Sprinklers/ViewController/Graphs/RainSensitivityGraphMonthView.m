//
//  RainSensitivityGraphMonthView.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivityGraphMonthView.h"
#import "Constants.h"

@implementation RainSensitivityGraphMonthView

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    
    [self addObserver:self forKeyPath:@"values" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"values"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1.0].CGColor);
    
    CGFloat lineWidth = self.frame.size.width / self.values.count;
    CGFloat lineX = 0.0;
    
    CGContextSetLineWidth(context, ceil(lineWidth));
    
    for (NSNumber *value in self.values) {
        CGFloat lineHeight = self.frame.size.height * value.doubleValue;
        CGFloat lineY = self.frame.size.height - lineHeight;
        
        CGContextMoveToPoint(context, ceil(lineX), lineY);
        CGContextAddLineToPoint(context, ceil(lineX), self.frame.size.height);
        CGContextStrokePath(context);
        
        lineX += lineWidth;
    }
}

@end
